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
    return StatsOverview(
      totalQuestions: total,
      accuracyPercent: acc * 100,
      streakDays: streak,
      activeDays: streak,
    );
  }

  Future<int> totalQuestions() => _dao.getTotalQuestions();
  Future<double> accuracy() => _dao.getAccuracy();

  Future<List<DailyRecord>> getDailyRecords(int rangeDays) async {
    return []; // 由 _StatisticsAggregator 实现
  }

  Future<List<TrendPoint>> getAccuracyTrend(int rangeDays) async {
    return []; // 由 _StatisticsAggregator 实现
  }

  Future<List<TrendPoint>> getPointsTrend(int rangeDays) async {
    return []; // 由 _StatisticsAggregator 实现
  }

  Future<Distribution> getDistribution() async {
    return const Distribution(
      total: 0, choiceCount: 0, choicePercent: 0,
      fillCount: 0, fillPercent: 0,
      solutionCount: 0, solutionPercent: 0,
    );
  }
}

// ── 统计聚合引擎（极简 v1） ──
/// 从 StatisticsDAO 获取原始数据，在 Dart 侧做聚合计算。
class StatisticsAggregator {
  /// 按日期汇总每日做题数，返回降采样到 rangeDays 粒度的记录
  static List<DailyRecord> aggregateDailyRecords(
    List<({String date, int count})> raw,
    int rangeDays,
  ) {
    if (raw.isEmpty) return [];
    // 按日期分组求和
    final grouped = <String, int>{};
    for (final r in raw) {
      grouped[r.date] = (grouped[r.date] ?? 0) + r.count;
    }
    final list = grouped.entries.map((e) => DailyRecord(
      date: e.key,
      count: e.value,
      level: e.value > 5 ? 3 : (e.value > 2 ? 2 : (e.value > 0 ? 1 : 0)),
    )).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }
}
