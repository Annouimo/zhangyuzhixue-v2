import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;
import '../debug/audit_logger.dart';

/// 成就数据访问层（user 库）
class AchievementDao {
  final db.AppDatabase _db;
  const AchievementDao(this._db);

  Future<int> getUnlockedCount() async {
    final rows = await (_db.select(_db.studentAchievements)
      ..where((t) => t.isUnlocked.equals(1))).get();
    AuditLogger.instance.dao('AchievementDao.getUnlockedCount', rows.length, {});
    return rows.length;
  }

  Future<List<db.StudentAchievementRow>> getAllProgress() {
    final q = _db.select(_db.studentAchievements).get();
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
    final rows = await _db.select(_db.submissionDetails).get();
    AuditLogger.instance.dao('AchievementDao.getSubmissionCount', rows.length, {});
    return rows.length;
  }

  Future<int> getRatingCount() async {
    final rows = await _db.select(_db.questionRatings).get();
    AuditLogger.instance.dao('AchievementDao.getRatingCount', rows.length, {});
    return rows.length;
  }

  /// 从登录日志推算连续签到天数
  Future<int> getLoginStreak() async {
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
    AuditLogger.instance.dao('AchievementDao.getLoginStreak', streak, {'streak': streak});
    return streak;
  }
}
