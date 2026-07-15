import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;
import '../database/database_provider.dart';
import '../debug/audit_logger.dart';

/// 用户数据访问层（user 库）
class UserDao {
  final DatabaseProvider _provider;
  UserDao(this._provider);
  db.AppDatabase get _db => _provider.appDb;

  Future<db.UserProfileRow?> getProfile() async {
    final rows = await _db.select(_db.userProfiles).get();
    AuditLogger.instance.dao('UserDao.getProfile', rows.length, {});
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> saveProfile({
    required int id,
    required String name,
    String? realName,
    String? studentId,
    String? avatar,
    String? school,
    String? gaokaoYear,
    String? phone,
    int? classGroupId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final existing = await (_db.select(_db.userProfiles)
      ..where((t) => t.id.equals(id))).get();
    if (existing.isNotEmpty) {
      final q = _db.update(_db.userProfiles)..where((t) => t.id.equals(id));
      await q.write(db.UserProfilesCompanion(
        name: Value(name), realName: Value(realName),
        studentId: Value(studentId), avatar: Value(avatar),
        school: Value(school), gaokaoYear: Value(gaokaoYear),
        phone: Value(phone),
        classGroupId: Value(classGroupId), updatedAt: Value(now),
      ));
    } else {
      await _db.into(_db.userProfiles).insert(db.UserProfilesCompanion(
        id: Value(id), name: Value(name),
        realName: Value(realName), studentId: Value(studentId),
        avatar: Value(avatar), school: Value(school),
        gaokaoYear: Value(gaokaoYear), phone: Value(phone),
        classGroupId: Value(classGroupId),
        updatedAt: Value(now),
      ));
    }
  }
  Future<List<db.PointsTransactionRow>> getPointsHistory() async {
    final q = _db.select(_db.pointsTransactions)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    final result = await q.get();
    AuditLogger.instance.dao('UserDao.getPointsHistory', result.length, {});
    return result;
  }

  Future<double> getEarnedPoints() async {
    final rows = await (_db.select(_db.pointsTransactions)
      ..where((t) => t.source.equals('PRACTICE_REWARD'))).get();
    AuditLogger.instance.dao('UserDao.getEarnedPoints', rows.length, {});
    var total = 0.0;
    for (final r in rows) { total += r.amount; }
    return total;
  }

  Future<List<db.PointsTransactionRow>> getTransactionsBySource(
      List<String> sources) async {
    final q = _db.select(_db.pointsTransactions)
      ..where((t) => t.source.isIn(sources));
    final rows = await q.get();
    AuditLogger.instance.dao('UserDao.getTransactionsBySource', rows.length, {'sources': sources.length});
    return rows;
  }

  /// 连续做题天数（从 submissionDetail 推算，从今天回溯）
  Future<int> getStreakDays() async {
    final rows = await (_db.select(_db.submissionDetails)
      ..where((t) => t.isCorrect.isNotNull())).get();
    if (rows.isEmpty) return 0;
    final studyDates = rows.map((r) => r.createdAt.substring(0, 10)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    var streak = 0;
    final today = DateTime.now();
    for (final dateStr in studyDates) {
      final d = DateTime.parse(dateStr);
      final expected = today.subtract(Duration(days: streak));
      if (d.year == expected.year && d.month == expected.month && d.day == expected.day) {
        streak++;
      } else {
        break;
      }
    }
    AuditLogger.instance.dao('UserDao.getStreakDays', streak, {});
    return streak;
  }

  Future<int> getTotalSubmissions() async {
    final rows = await (_db.select(_db.submissionDetails)
      ..where((t) => t.isCorrect.isNotNull())).get();
    AuditLogger.instance.dao('UserDao.getTotalSubmissions', rows.length, {});
    return rows.length;
  }

  /// 获取最近做题记录（倒序，取 [limit] 条）
  Future<List<db.SubmissionDetailRow>> getRecentSubmissions({int limit = 20}) async {
    final q = _db.select(_db.submissionDetails)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
      ..limit(limit);
    final rows = await q.get();
    AuditLogger.instance.dao('UserDao.getRecentSubmissions', rows.length, {'limit': limit});
    return rows;
  }

  /// 获取今天获得的学习积分（仅 earned 分类，不含 bonus/spent）
  Future<double> getTodayEarnedPoints() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final q = (_db.select(_db.pointsTransactions)
      ..where((t) =>
          t.createdAt.isBiggerOrEqual(Variable(today)) &
          t.amount.isBiggerThanValue(0.0) &
          t.source.isIn(['LOGIN_BONUS', 'PRACTICE_REWARD', 'TASK_REWARD'])));
    final rows = await q.get();
    AuditLogger.instance.dao('UserDao.getTodayEarnedPoints', rows.length, {});
    var total = 0.0;
    for (final row in rows) {
      total += row.amount;
    }
    return total;
  }

  /// 今日做题统计（选择/填空 is_correct + 解答题小问全对）
  Future<({int total, int correct})> getTodaySubmissionStats() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // ① 选择/填空
    final cfRows = await (_db.select(_db.submissionDetails)
      ..where((t) => t.createdAt.isBiggerOrEqual(Variable(today)))).get();
    var cfTotal = 0; var cfCorrect = 0;
    for (final r in cfRows) { cfTotal++; if (r.isCorrect == 1) cfCorrect++; }

    // ② 解答题小问
    final step = await getTodayStepSubQuestionStats();

    AuditLogger.instance.dao('UserDao.getTodaySubmissionStats', cfTotal + step.total, {
      'cfTotal': cfTotal, 'cfCorrect': cfCorrect,
      'stepTotal': step.total, 'stepCorrect': step.correct,
    });
    return (total: cfTotal + step.total, correct: cfCorrect + step.correct);
  }

  /// 今日解答题按小问统计（全对的小问数）
  Future<({int total, int correct})> getTodayStepSubQuestionStats() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // 先查今日解答题的 submission_detail ID
    final sdIds = await (_db.select(_db.submissionDetails)
      ..where((t) =>
          t.createdAt.isBiggerOrEqual(Variable(today)) &
          t.isCorrect.isNull())
    ).get();
    if (sdIds.isEmpty) return (total: 0, correct: 0);
    final idSet = sdIds.map((r) => r.id).toSet();

    // 查这些提交的 step_feedback
    final rows = await (_db.select(_db.stepFeedbacks)
      ..where((t) => t.submissionDetailId.isIn(idSet))
    ).get();

    // Dart 层按 (submission_detail_id, sub_question_index, method_id) 分组
    final groups = <(int, int?, int?), List<String>>{};
    for (final sf in rows) {
      groups.putIfAbsent((sf.submissionDetailId, sf.subQuestionIndex, sf.methodId), () => []).add(sf.status);
    }

    var total = 0; var correct = 0;
    for (final ss in groups.values) {
      total++;
      if (ss.every((s) => s == 'full_correct')) correct++;
    }
    return (total: total, correct: correct);
  }

}
