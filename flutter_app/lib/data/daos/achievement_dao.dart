import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;

/// 成就数据访问层（user 库）
class AchievementDao {
  final db.AppDatabase _db;
  const AchievementDao(this._db);

  Future<int> getUnlockedCount() async {
    final rows = await (_db.select(_db.studentAchievements)
      ..where((t) => t.isUnlocked.equals(1))).get();
    return rows.length;
  }

  Future<List<db.StudentAchievementRow>> getAllProgress() =>
      _db.select(_db.studentAchievements).get();

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
    return rows.length;
  }

  Future<int> getRatingCount() async {
    final rows = await _db.select(_db.questionRatings).get();
    return rows.length;
  }
}
