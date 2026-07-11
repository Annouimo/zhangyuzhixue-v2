import '../data/daos/statistics_dao.dart';

/// 统计概览
class StatsOverview {
  final int totalQuestions;
  final double accuracyPercent;
  final int streakDays;
  final int activeDays;

  const StatsOverview({
    required this.totalQuestions,
    required this.accuracyPercent,
    required this.streakDays,
    required this.activeDays,
  });
}

/// 每日记录
class DailyRecord {
  final String date;
  final int count;
  final int level;
  const DailyRecord({required this.date, required this.count, required this.level});
}

/// 趋势点
class TrendPoint {
  final String label;
  final double value;
  const TrendPoint({required this.label, required this.value});
}

/// 题型分布
class Distribution {
  final int total;
  final int choiceCount;
  final double choicePercent;
  final int fillCount;
  final double fillPercent;
  final int solutionCount;
  final double solutionPercent;

  const Distribution({
    required this.total,
    required this.choiceCount,
    required this.choicePercent,
    required this.fillCount,
    required this.fillPercent,
    required this.solutionCount,
    required this.solutionPercent,
  });
}

/// 统计 Repository — 委托 StatisticsDao + _StatisticsAggregator
class StatisticsRepository {
  final StatisticsDao _dao;
  const StatisticsRepository(this._dao);

  Future<StatsOverview> getOverview() async {
    final total = await _dao.getTotalQuestions();
    final acc = await _dao.getAccuracy();
    final streak = await _dao.getStreakDays();
    final active = await _dao.getActiveDays();
    return StatsOverview(
      totalQuestions: total,
      accuracyPercent: acc * 100,
      streakDays: streak,
      activeDays: active,
    );
  }

  Future<int> totalQuestions() => _dao.getTotalQuestions();
  Future<double> accuracy() => _dao.getAccuracy();

  Future<List<DailyRecord>> getDailyRecords(int rangeDays) async {
    final raw = await _dao.getDailyRecords(rangeDays);
    return _StatisticsAggregator.aggregateDailyRecords(raw);
  }

  Future<List<TrendPoint>> getAccuracyTrend(int rangeDays) async {
    final raw = await _dao.getDailyRecords(rangeDays);
    if (raw.isEmpty) return [];
    // 每日正确率作为趋势点
    final points = <TrendPoint>[];
    for (final r in raw) {
      if (r.count == 0) continue;
      final acc = r.correct / r.count;
      points.add(TrendPoint(label: r.date, value: acc * 100));
    }
    // 点数 > 30 时降采样
    if (points.length > 30) {
      final sampled = <TrendPoint>[];
      final step = (points.length / 30).ceil();
      for (var i = 0; i < points.length; i += step) {
        sampled.add(points[i]);
      }
      return sampled;
    }
    return points;
  }

  Future<List<TrendPoint>> getPointsTrend(int rangeDays) async {
    final raw = await _dao.getPointsByDay(rangeDays);
    if (raw.isEmpty) return [];
    // 累计求和
    var cum = 0.0;
    final points = <TrendPoint>[];
    for (final r in raw) {
      cum += r.amount;
      points.add(TrendPoint(label: r.date, value: cum));
    }
    // 点数 > 30 时降采样
    if (points.length > 30) {
      final sampled = <TrendPoint>[];
      final step = (points.length / 30).ceil();
      for (var i = 0; i < points.length; i += step) {
        sampled.add(points[i]);
      }
      return sampled;
    }
    return points;
  }

  Future<Distribution> getDistribution() async {
    final counts = await _dao.getTypeCounts();
    final total = counts.choice + counts.fill + counts.solution;
    return Distribution(
      total: total,
      choiceCount: counts.choice,
      choicePercent: total > 0 ? counts.choice / total * 100 : 0,
      fillCount: counts.fill,
      fillPercent: total > 0 ? counts.fill / total * 100 : 0,
      solutionCount: counts.solution,
      solutionPercent: total > 0 ? counts.solution / total * 100 : 0,
    );
  }
}

// ── 统计聚合引擎 ──
class _StatisticsAggregator {
  static List<DailyRecord> aggregateDailyRecords(
    List<({String date, int count, int correct})> raw,
  ) {
    if (raw.isEmpty) return [];
    final grouped = <String, ({int count, int correct})>{};
    for (final r in raw) {
      final cur = grouped[r.date] ?? (count: 0, correct: 0);
      grouped[r.date] = (count: cur.count + r.count, correct: cur.correct + r.correct);
    }
    final list = grouped.entries.map((e) => DailyRecord(
      date: e.key,
      count: e.value.count,
      level: e.value.count > 5 ? 3 : (e.value.count > 2 ? 2 : (e.value.count > 0 ? 1 : 0)),
    )).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }
}
