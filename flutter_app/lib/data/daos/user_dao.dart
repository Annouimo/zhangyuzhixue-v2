import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;

/// 用户数据访问层（user 库）
class UserDao {
  final db.AppDatabase _db;
  const UserDao(this._db);

  Future<db.UserProfileRow?> getProfile() async {
    final rows = await _db.customSelect(
      'SELECT * FROM user_profiles LIMIT 1',
      readsFrom: {_db.userProfiles},
    ).get();
    if (rows.isEmpty) return null;
    return _db.userProfiles.map(rows.first.data);
  }

  Future<void> saveProfile({
    required int id,
    required String name,
    String? realName,
    String? studentId,
    String? avatar,
    String? school,
    String? gaokaoYear,
    int? classGroupId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final existing = await _db.customSelect(
      'SELECT 1 FROM user_profiles WHERE id = ?',
      variables: [Variable(id)],
      readsFrom: {_db.userProfiles},
    ).get();
    if (existing.isNotEmpty) {
      final q = _db.update(_db.userProfiles);
      q.where((t) => t.id.equals(id));
      await q.write(db.UserProfilesCompanion(
        name: Value(name),
        realName: Value(realName),
        studentId: Value(studentId),
        avatar: Value(avatar),
        school: Value(school),
        gaokaoYear: Value(gaokaoYear),
        classGroupId: Value(classGroupId),
        updatedAt: Value(now),
      ));
    } else {
      await _db.into(_db.userProfiles).insert(db.UserProfilesCompanion(
        id: Value(id),
        name: Value(name),
        realName: Value(realName),
        studentId: Value(studentId),
        avatar: Value(avatar),
        school: Value(school),
        gaokaoYear: Value(gaokaoYear),
        classGroupId: Value(classGroupId),
        updatedAt: Value(now),
      ));
    }
  }

  // ── 积分 ──

  Future<List<db.PointsTransactionRow>> getPointsHistory() async {
    final rows = await _db.customSelect(
      'SELECT * FROM points_transactions ORDER BY created_at DESC',
      readsFrom: {_db.pointsTransactions},
    ).get();
    return rows.map((r) => _db.pointsTransactions.map(r.data)).toList();
  }

  Future<int> getEarnedPoints() async {
    final row = await _db.customSelect(
      "SELECT COALESCE(SUM(amount), 0) AS s FROM points_transactions WHERE source IN ('LOGIN_BONUS', 'PRACTICE_REWARD', 'TASK_REWARD')",
      readsFrom: {_db.pointsTransactions},
    ).getSingle();
    return row.read<int>('s')!;
  }

  Future<int> getBonusPoints() async {
    final row = await _db.customSelect(
      "SELECT COALESCE(SUM(amount), 0) AS s FROM points_transactions WHERE source = 'SIGNUP_BONUS'",
      readsFrom: {_db.pointsTransactions},
    ).getSingle();
    return row.read<int>('s')!;
  }

  Future<int> getSpentPoints() async {
    final row = await _db.customSelect(
      "SELECT COALESCE(ABS(SUM(amount)), 0) AS s FROM points_transactions WHERE source = 'PAPER_PURCHASE'",
      readsFrom: {_db.pointsTransactions},
    ).getSingle();
    return row.read<int>('s')!;
  }

  Future<int> getTodayPoints() async {
    final row = await _db.customSelect(
      "SELECT COALESCE(SUM(amount), 0) AS s FROM points_transactions WHERE DATE(created_at) = DATE('now')",
      readsFrom: {_db.pointsTransactions},
    ).getSingle();
    return row.read<int>('s')!;
  }

  // ── 签到 ──

  Future<int> getStreakDays() async {
    // 最长的连续签到天数
    final rows = await _db.customSelect(
      'SELECT login_date FROM user_login_logs ORDER BY login_date DESC',
      readsFrom: {_db.userLoginLogs},
    ).get();
    if (rows.isEmpty) return 0;
    var streak = 0;
    final today = DateTime.now();
    for (var i = 0; i < rows.length; i++) {
      final d = DateTime.parse(rows[i].read<String>('login_date')!);
      final expected = today.subtract(Duration(days: streak));
      if (d.year == expected.year && d.month == expected.month && d.day == expected.day) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
