import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;
import '../database/database_provider.dart';
import '../debug/audit_logger.dart';

/// 成就数据访问层（user 库）
class AchievementDao {
  final DatabaseProvider _provider;
  AchievementDao(this._provider);
  db.AppDatabase get _db => _provider.appDb;

  Future<int> getUnlockedCount() async {
    final result = await _db.customSelect(
      'SELECT COUNT(*) AS cnt FROM student_achievement WHERE is_unlocked = 1',
    ).getSingle();
    return result.read<int>('cnt');
  }

  Future<List<db.StudentAchievementRow>> getAllProgress() {
    final q = (_db.select(_db.studentAchievements)
      ..orderBy([(t) => OrderingTerm(expression: t.achievementCode)]))
      .get();
    return q.then((rows) {
      AuditLogger.instance.dao('AchievementDao.getAllProgress', rows.length, {});
      return rows;
    });
  }

  Future<void> upsertProgress({
    required String achievementCode,
    required int progress,
    required int isUnlocked,
    String? unlockedAt,
  }) async {
    final existing = await (_db.select(_db.studentAchievements)
      ..where((t) => t.achievementCode.equals(achievementCode))).get();
    if (existing.isNotEmpty) {
      final q = _db.update(_db.studentAchievements)
        ..where((t) => t.achievementCode.equals(achievementCode));
      await q.write(db.StudentAchievementsCompanion(
        progress: Value(progress),
        isUnlocked: Value(isUnlocked),
        unlockedAt: Value(unlockedAt),
      ));
    } else {
      await _db.into(_db.studentAchievements).insert(
        db.StudentAchievementsCompanion(
          achievementCode: Value(achievementCode),
          progress: Value(progress),
          isUnlocked: Value(isUnlocked),
          unlockedAt: Value(unlockedAt),
        ),
      );
    }
  }

  Future<int> getSubmissionCount() async {
    final result = await _db.customSelect(
      'SELECT COUNT(*) AS cnt FROM submission_detail',
    ).getSingle();
    return result.read<int>('cnt');
  }

  Future<int> getRatingCount() async {
    final result = await _db.customSelect(
      'SELECT COUNT(*) AS cnt FROM question_rating',
    ).getSingle();
    return result.read<int>('cnt');
  }

  /// 从登录日志推算连续签到天数
  Future<int> getLoginStreak() async {
    final rows = await (_db.select(_db.userLoginLogs)
      ..orderBy([(t) => OrderingTerm(expression: t.loginDate, mode: OrderingMode.desc)])).get();
    if (rows.isEmpty) return 0;
    var streak = 0;
    // 以最新一条签到记录为起点往前推算，而非从 today 开始。
    // 如果 today 尚未签到，当前算法能从最近的实际签到日期开始连续计数。
    final mostRecent = DateTime.parse(rows.first.loginDate);
    for (final row in rows) {
      final d = DateTime.parse(row.loginDate);
      final expected = mostRecent.subtract(Duration(days: streak));
      if (d.year == expected.year && d.month == expected.month && d.day == expected.day) {
        streak++;
      } else {
        break;
      }
    }
    AuditLogger.instance.dao('AchievementDao.getLoginStreak', streak, {'streak': streak});
    return streak;
  }

  /// 写入本地登录日志（签到 API 成功后调用）
  Future<void> insertLoginLog({
    required String loginDate,
    required String createdAt,
  }) async {
    await _db.into(_db.userLoginLogs).insert(
      db.UserLoginLogsCompanion(
        loginDate: Value(loginDate),
        createdAt: Value(createdAt),
      ),
      mode: InsertMode.insertOrReplace,
    );
    AuditLogger.instance.dao('AchievementDao.insertLoginLog', 1, {'loginDate': loginDate});
  }

  // ── 新增成就引擎方法 ──

  /// 连续有做题记录的天数（从今天倒推）
  Future<int> getPracticeStreak() async {
    final rows = await (_db.select(_db.submissionDetails)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
      .get();
    if (rows.isEmpty) return 0;
    final dates = rows.map((r) => r.createdAt.substring(0, 10)).toSet().toList()..sort();
    var streak = 0;
    final today = DateTime.now();
    for (var i = dates.length - 1; i >= 0; i--) {
      final d = DateTime.parse(dates[i]);
      final expected = today.subtract(Duration(days: streak));
      if (d.year == expected.year && d.month == expected.month && d.day == expected.day) {
        streak++;
      } else {
        break;
      }
    }
    AuditLogger.instance.dao('AchievementDao.getPracticeStreak', streak, {});
    return streak;
  }

  /// 返回 (correctCount, totalCount) — 所有有 is_correct 标记的提交
  Future<(int, int)> getAccuracyStats() async {
    final rows = await (_db.select(_db.submissionDetails)
      ..where((t) => t.isCorrect.isNotNull()))
      .get();
    final correct = rows.where((r) => r.isCorrect == 1).length;
    AuditLogger.instance.dao('AchievementDao.getAccuracyStats', correct, {
      'total': rows.length,
    });
    return (correct, rows.length);
  }

  /// 全量做题统计（选填 is_correct + 解答题小问全对），成就引擎用
  Future<({int total, int correct})> getFullAccuracyStats() async {
    // ① 选择/填空
    final cfRows = await (_db.select(_db.submissionDetails)
      ..where((t) => t.isCorrect.isNotNull())).get();
    var cfCorrect = cfRows.where((r) => r.isCorrect == 1).length;

    // ② 解答题小问（全量）
    final sdIds = await (_db.select(_db.submissionDetails)
      ..where((t) => t.isCorrect.isNull())
    ).get();
    if (sdIds.isEmpty) {
      AuditLogger.instance.dao('AchievementDao.getFullAccuracyStats', cfCorrect, {
        'cfTotal': cfRows.length, 'cfCorrect': cfCorrect,
        'stepTotal': 0, 'stepCorrect': 0,
      });
      return (total: cfRows.length, correct: cfCorrect);
    }
    final idSet = sdIds.map((r) => r.id).toSet();

    final stepRows = await (_db.select(_db.stepFeedbacks)
      ..where((t) => t.submissionDetailId.isIn(idSet))
    ).get();

    final groups = <(int, int?, int?), List<String>>{};
    for (final sf in stepRows) {
      groups.putIfAbsent((sf.submissionDetailId, sf.subQuestionIndex, sf.methodId), () => []).add(sf.status);
    }

    var stepTotal = 0; var stepCorrect = 0;
    for (final ss in groups.values) {
      stepTotal++;
      if (ss.every((s) => s == 'full_correct')) stepCorrect++;
    }

    AuditLogger.instance.dao('AchievementDao.getFullAccuracyStats',
      cfCorrect + stepCorrect, {
      'cfTotal': cfRows.length, 'cfCorrect': cfCorrect,
      'stepTotal': stepTotal, 'stepCorrect': stepCorrect,
    });
    return (total: cfRows.length + stepTotal, correct: cfCorrect + stepCorrect);
  }

  /// 扫描提交记录，按时间排序后的最大连续正确数
  Future<int> getMaxConsecutiveCorrect() async {
    final rows = await (_db.select(_db.submissionDetails)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)]))
      .get();
    var maxStreak = 0, currentStreak = 0;
    for (final r in rows) {
      if (r.isCorrect == 1) {
        currentStreak++;
        if (currentStreak > maxStreak) maxStreak = currentStreak;
      } else {
        currentStreak = 0;
      }
    }
    AuditLogger.instance.dao('AchievementDao.getMaxConsecutiveCorrect', maxStreak, {});
    return maxStreak;
  }
}
