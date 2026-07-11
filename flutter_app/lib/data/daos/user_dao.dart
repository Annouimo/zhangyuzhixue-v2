import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;
import '../debug/audit_logger.dart';

/// 用户数据访问层（user 库）
class UserDao {
  final db.AppDatabase _db;
  const UserDao(this._db);

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

  Future<int> getEarnedPoints() async {
    final rows = await (_db.select(_db.pointsTransactions)
      ..where((t) => t.source.isIn(['LOGIN_BONUS', 'PRACTICE_REWARD', 'TASK_REWARD']))).get();
    AuditLogger.instance.dao('UserDao.getEarnedPoints', rows.length, {});
    var total = 0;
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

  Future<int> getStreakDays() async {
    final rows = await (_db.select(_db.userLoginLogs)
      ..orderBy([(t) => OrderingTerm(expression: t.loginDate, mode: OrderingMode.desc)])).get();
    if (rows.isEmpty) return 0;
    var streak = 0;
    final today = DateTime.now();
    for (final row in rows) {
      final d = DateTime.parse(row.loginDate);
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
    final rows = await _db.select(_db.submissionDetails).get();
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

  /// 获取今天获得的积分
  Future<int> getTodayEarnedPoints() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final all = await _db.select(_db.pointsTransactions).get();
    AuditLogger.instance.dao('UserDao.getTodayEarnedPoints', all.length, {});
    var total = 0;
    for (final row in all) {
      if (row.createdAt.startsWith(today) && row.amount > 0) {
        total += row.amount;
      }
    }
    return total;
  }
}
