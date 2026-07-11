import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;
import '../debug/audit_logger.dart';

/// 统计数据访问层（user 库）
class StatisticsDao {
  final db.AppDatabase _db;
  const StatisticsDao(this._db);

  Future<int> getTotalQuestions() async {
    final rows = await (_db.select(_db.submissionDetails)
      ..where((t) => t.isCorrect.isNotNull())).get();
    AuditLogger.instance.dao('StatisticsDao.getTotalQuestions', rows.length, {});
    return rows.length;
  }

  Future<double> getAccuracy() async {
    final rows = await (_db.select(_db.submissionDetails)
      ..where((t) => t.isCorrect.isNotNull())).get();
    AuditLogger.instance.dao('StatisticsDao.getAccuracy', rows.length, {});
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
    AuditLogger.instance.dao('StatisticsDao.getStreakDays', streak, {});
    return streak;
  }

  /// 活跃天数（有做题记录的非重复日期数）
  Future<int> getActiveDays() async {
    final rows = await (_db.select(_db.submissionDetails)
      ..where((t) => t.isCorrect.isNotNull())).get();
    AuditLogger.instance.dao('StatisticsDao.getActiveDays', rows.length, {});
    final dates = rows.map((r) => r.createdAt.substring(0, 10)).toSet();
    return dates.length;
  }

  /// 按日期统计每日做题数和正确数
  Future<List<({String date, int count, int correct})>> getDailyRecords(int rangeDays) async {
    final threshold = DateTime.now().subtract(Duration(days: rangeDays)).toIso8601String();
    final rows = await (_db.select(_db.submissionDetails)
      ..where((t) => t.createdAt.isBiggerThanValue(threshold))).get();
    AuditLogger.instance.dao('StatisticsDao.getDailyRecords', rows.length, {'rangeDays': rangeDays});
    final groups = <String, ({int count, int correct})>{};
    for (final r in rows) {
      final date = r.createdAt.substring(0, 10);
      final cur = groups[date] ?? (count: 0, correct: 0);
      groups[date] = (count: cur.count + 1, correct: cur.correct + (r.isCorrect == 1 ? 1 : 0));
    }
    return groups.entries.map((e) => (
      date: e.key,
      count: e.value.count,
      correct: e.value.correct,
    )).toList();
  }

  /// 按日期统计每日获得积分
  Future<List<({String date, double amount})>> getPointsByDay(int rangeDays) async {
    final threshold = DateTime.now().subtract(Duration(days: rangeDays)).toIso8601String();
    final rows = await (_db.select(_db.pointsTransactions)
      ..where((t) => t.createdAt.isBiggerThanValue(threshold))).get();
    AuditLogger.instance.dao('StatisticsDao.getPointsByDay', rows.length, {'rangeDays': rangeDays});
    final groups = <String, double>{};
    for (final r in rows) {
      final date = r.createdAt.substring(0, 10);
      groups[date] = (groups[date] ?? 0) + r.amount;
    }
    return groups.entries.map((e) => (date: e.key, amount: e.value)).toList();
  }

  /// 按题型统计答题数
  Future<({int choice, int fill, int solution})> getTypeCounts() async {
    // 需要联表查询 question 的 type，本地无此关联
    return (choice: 0, fill: 0, solution: 0);
  }
}
