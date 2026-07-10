import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;

/// 统计数据访问层（user 库）
class StatisticsDao {
  final db.AppDatabase _db;
  const StatisticsDao(this._db);

  Future<int> getTotalQuestions() async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM submission_details WHERE is_correct IS NOT NULL',
      readsFrom: {_db.submissionDetails},
    ).getSingle();
    return row.read<int>('c')!;
  }

  Future<double> getAccuracy() async {
    final row = await _db.customSelect(
      'SELECT CAST(SUM(is_correct) AS REAL) / COUNT(*) AS p FROM submission_details WHERE is_correct IS NOT NULL',
      readsFrom: {_db.submissionDetails},
    ).getSingle();
    return row.read<double>('p') ?? 0.0;
  }

  Future<List<({String date, int count, int correct})>> getDailyRecords(int days) async {
    final rows = await _db.customSelect(
      "SELECT DATE(created_at) AS d, COUNT(*) AS cnt, COALESCE(SUM(is_correct), 0) AS cor FROM submission_details "
      "WHERE created_at >= datetime('now', '-? days') GROUP BY d ORDER BY d",
      variables: [Variable(days)],
      readsFrom: {_db.submissionDetails},
    ).get();
    return rows.map((r) => (
      date: r.read<String>('d')!,
      count: r.read<int>('cnt')!,
      correct: r.read<int>('cor')!,
    )).toList();
  }

  Future<List<({String date, int amount})>> getPointsByDay(int days) async {
    final rows = await _db.customSelect(
      "SELECT DATE(created_at) AS d, SUM(amount) AS amt FROM points_transactions "
      "WHERE created_at >= datetime('now', '-? days') GROUP BY d ORDER BY d",
      variables: [Variable(days)],
      readsFrom: {_db.pointsTransactions},
    ).get();
    return rows.map((r) => (
      date: r.read<String>('d')!,
      amount: r.read<int>('amt')!,
    )).toList();
  }

  Future<List<({String type, int count})>> getTypeDistribution() async {
    // 通过 question_id 联表
    final rows = await _db.customSelect(
      'SELECT q.question_type AS t, COUNT(*) AS c FROM submission_details sd '
      'LEFT JOIN ... GROUP BY t',
      readsFrom: {_db.submissionDetails},
    ).get();
    return rows.map((r) => (
      type: r.read<String>('t')!,
      count: r.read<int>('c')!,
    )).toList();
  }
}
