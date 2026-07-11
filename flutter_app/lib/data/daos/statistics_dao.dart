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

  /// 活跃天数（有做题记录的非重复日期数）
  Future<int> getActiveDays() async {
    final rows = await (_db.select(_db.submissionDetails)
      ..where((t) => t.isCorrect.isNotNull())).get();
    final dates = rows.map((r) => r.createdAt.substring(0, 10)).toSet();
    return dates.length;
  }

  /// 按日期统计每日做题数
  Future<List<({String date, int count})>> getDailyRecords(int rangeDays) async {
    final threshold = DateTime.now().subtract(Duration(days: rangeDays)).toIso8601String();
    final rows = await (_db.select(_db.submissionDetails)
      ..where((t) => t.createdAt.isBiggerThanValue(threshold))).get();
    final groups = <String, int>{};
    for (final r in rows) {
      final date = r.createdAt.substring(0, 10);
      groups[date] = (groups[date] ?? 0) + 1;
    }
    return groups.entries.map((e) => (date: e.key, count: e.value)).toList();
  }

  /// 按题型统计答题数
  Future<({int choice, int fill, int solution})> getTypeCounts() async {
    // 需要联表查询 question 的 type，本地无此关联
    return (choice: 0, fill: 0, solution: 0);
  }
}
