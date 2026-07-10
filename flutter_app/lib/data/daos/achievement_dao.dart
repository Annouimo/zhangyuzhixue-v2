import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;

/// 成就数据访问层（user 库）
class AchievementDao {
  final db.AppDatabase _db;
  const AchievementDao(this._db);

  Future<int> getUnlockedCount() async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM student_achievements WHERE is_unlocked = 1',
      readsFrom: {_db.studentAchievements},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<List<db.StudentAchievementRow>> getAllProgress() async {
    final rows = await _db.customSelect(
      'SELECT * FROM student_achievements',
      readsFrom: {_db.studentAchievements},
    ).get();
    return rows.map((r) => _db.studentAchievements.map(r.data)).toList();
  }

  Future<void> upsertProgress({
    required String achievementCode,
    required int progress,
    required int isUnlocked,
    String? unlockedAt,
  }) async {
    final existing = await _db.customSelect(
      'SELECT * FROM student_achievements WHERE achievement_code = ?',
      variables: [Variable(achievementCode)],
      readsFrom: {_db.studentAchievements},
    ).get();
    if (existing.isNotEmpty) {
      final q = _db.update(_db.studentAchievements);
      q.where((t) => t.achievementCode.equals(achievementCode));
      await q.write(db.StudentAchievementsCompanion(
        progress: Value(progress),
        isUnlocked: Value(isUnlocked),
        unlockedAt: Value(unlockedAt),
      ));
    } else {
      await _db.into(_db.studentAchievements).insert(db.StudentAchievementsCompanion(
        achievementCode: Value(achievementCode),
        progress: Value(progress),
        isUnlocked: Value(isUnlocked),
        unlockedAt: Value(unlockedAt),
      ));
    }
  }

  Future<int> getLoginStreak() async {
    final rows = await _db.customSelect(
      'SELECT login_date FROM user_login_logs ORDER BY login_date DESC',
      readsFrom: {_db.userLoginLogs},
    ).get();
    // 推算连续签到天数
    if (rows.isEmpty) return 0;
    var streak = 0;
    final today = DateTime.now();
    for (var i = 0; i < rows.length; i++) {
      final d = DateTime.parse(rows[i].read<String>('login_date'));
      final expected = today.subtract(Duration(days: streak));
      if (d.year == expected.year && d.month == expected.month && d.day == expected.day) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<int> getSubmissionCount() async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM submission_details',
      readsFrom: {_db.submissionDetails},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<int> getRatingCount() async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM question_ratings',
      readsFrom: {_db.questionRatings},
    ).getSingle();
    return row.read<int>('c');
  }
}
