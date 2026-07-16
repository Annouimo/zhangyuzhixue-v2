import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;
import '../database/database_provider.dart';
import 'package:shared/debug/audit_logger.dart';

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

  /// 单 SQL 查询积分汇总（4 个聚合并行），替代全量加载+Dart 循环
  Future<({double earned, double bonus, double spent, double available})> getPointsSummaryAggregated() async {
    Future<double> sumWhere(List<String> sources) async {
      final q = _db.selectOnly(_db.pointsTransactions)
        ..addColumns([_db.pointsTransactions.amount.sum()])
        ..where(_db.pointsTransactions.source.isIn(sources));
      final row = await q.getSingle();
      return row.read(_db.pointsTransactions.amount.sum()) ?? 0.0;
    }
    final results = await Future.wait([
      sumWhere(['PRACTICE_REWARD']),
      sumWhere(['LOGIN_BONUS', 'TASK_REWARD', 'SIGNUP_BONUS', 'REVIEW_REWARD', 'RATING_REWARD', 'ADMIN_ADJUST']),
      sumWhere(['PAPER_PURCHASE']),
    ]);
    final earned = results[0];
    final bonus = results[1];
    final spent = results[2].abs();
    AuditLogger.instance.dao('UserDao.getPointsSummaryAggregated', 3, {});
    return (earned: earned, bonus: bonus, spent: spent, available: earned + bonus - spent);
  }

  Future<double> getEarnedPoints() async {
    final q = _db.selectOnly(_db.pointsTransactions)
      ..addColumns([_db.pointsTransactions.amount.sum()])
      ..where(_db.pointsTransactions.source.equals('PRACTICE_REWARD'));
    final row = await q.getSingle();
    final result = row.read(_db.pointsTransactions.amount.sum()) ?? 0.0;
    AuditLogger.instance.dao('UserDao.getEarnedPoints', 1, {});
    return result;
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
    final q = _db.selectOnly(_db.submissionDetails)
      ..addColumns([_db.submissionDetails.id.count()])
      ..where(_db.submissionDetails.isCorrect.isNotNull());
    final row = await q.getSingle();
    final result = row.read(_db.submissionDetails.id.count()) ?? 0;
    AuditLogger.instance.dao('UserDao.getTotalSubmissions', result, {});
    return result;
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
