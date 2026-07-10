import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;

/// 统计数据访问层（user 库）
class StatisticsDao {
  final db.AppDatabase _db;
  const StatisticsDao(this._db);

  Future<int> getTotalQuestions() async {
    final rows = await (_db.select(_db.submissionDetails)
      ..where((t) => t.isCorrect.isNotNull())).get();
    return rows.length;
  }

  Future<double> getAccuracy() async {
    final rows = await (_db.select(_db.submissionDetails)
      ..where((t) => t.isCorrect.isNotNull())).get();
    if (rows.isEmpty) return 0.0;
    final correct = rows.where((r) => r.isCorrect == 1).length;
    return correct / rows.length;
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
    return streak;
  }
}
