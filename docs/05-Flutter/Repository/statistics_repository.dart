/// 章鱼智学 — StatisticsRepository
/// data-db: stats.*
/// 对应页面：statistics.html, profile.html(总做题/正确率)

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

  factory StatsOverview.fromJson(Map<String, dynamic> json) => StatsOverview(
        totalQuestions: json['total_questions'] as int,
        accuracyPercent: (json['accuracy_percent'] as num).toDouble(),
        streakDays: json['streak_days'] as int,
        activeDays: json['active_days'] as int,
      );
}

class DailyRecord {
  final String date;
  final int count;
  final int level;

  const DailyRecord({
    required this.date,
    required this.count,
    required this.level,
  });

  factory DailyRecord.fromJson(Map<String, dynamic> json) => DailyRecord(
        date: json['date'] as String,
        count: json['count'] as int,
        level: json['level'] as int,
      );
}

class TrendPoint {
  final String label;
  final double value;

  const TrendPoint({required this.label, required this.value});

  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
        label: json['label'] as String,
        value: (json['value'] as num).toDouble(),
      );
}

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

  factory Distribution.fromJson(Map<String, dynamic> json) => Distribution(
        total: json['total'] as int,
        choiceCount: json['choice_count'] as int,
        choicePercent: (json['choice_percent'] as num).toDouble(),
        fillCount: json['fill_count'] as int,
        fillPercent: (json['fill_percent'] as num).toDouble(),
        solutionCount: json['solution_count'] as int,
        solutionPercent: (json['solution_percent'] as num).toDouble(),
      );
}

class StatisticsRepository {
  /// GET /api/stats/overview/
  Future<StatsOverview> getOverview() async {
    throw UnimplementedError('StatisticsRepository.getOverview');
  }

  /// 总做题数（profile.html 快捷用法）
  Future<int> totalQuestions() async {
    throw UnimplementedError('StatisticsRepository.totalQuestions');
  }

  /// 总体正确率（profile.html 快捷用法）
  Future<double> accuracy() async {
    throw UnimplementedError('StatisticsRepository.accuracy');
  }

  /// GET /api/stats/daily-records?range={days}
  Future<List<DailyRecord>> getDailyRecords(int rangeDays) async {
    throw UnimplementedError('StatisticsRepository.getDailyRecords');
  }

  /// GET /api/stats/accuracy-trend?range={days}
  Future<List<TrendPoint>> getAccuracyTrend(int rangeDays) async {
    throw UnimplementedError('StatisticsRepository.getAccuracyTrend');
  }

  /// GET /api/stats/points-trend?range={days}
  Future<List<TrendPoint>> getPointsTrend(int rangeDays) async {
    throw UnimplementedError('StatisticsRepository.getPointsTrend');
  }

  /// GET /api/stats/distribution/
  Future<Distribution> getDistribution() async {
    throw UnimplementedError('StatisticsRepository.getDistribution');
  }
}

// ---- 统计聚合引擎 ----
// 从 StatisticsDAO 获取原始数据，在 Dart 侧做聚合计算。
// 渲染层设计见 spec/UI_html/statistics.html（含 4 种自适应模式 + 示例 JS）
//
// 4 个数据源（调用 StatisticsDAO，不走 API）：
//
//   getDailyRecords(rangeDays)
//     → dao.getDailyRecords(rangeDays) 返回 [{date, count, correct}]
//     → Dart 侧 levelOf() 按当期最大值归一化为 lv0~lv3
//     → 渲染层按天数自动选择 条形图/7行周历/周格/月格
//
//   getAccuracyTrend(rangeDays)
//     → dao.getDailyRecords(rangeDays) （复用每日记录）
//     → Dart 侧按窗口滑动计算正确率
//     → 点数 > 30 时降采样（取窗口均值）
//
//   getPointsTrend(rangeDays)
//     → dao.getPointsByDay(rangeDays) 返回 [{date, amount}]
//     → Dart 侧算累计值（cumulative sum）
//
//   getDistribution()
//     → dao.getTypeDistribution() 返回 [{questionType, count}]
//     → Dart 侧算百分比
//
// 概览（getOverview）：从上述数据计算：
//   totalQuestions = sum of count
//   accuracyPercent = sum(correct) / sum(count)
//   streakDays = 从记录的连续有做题的天数推算（最长连续）
//   activeDays = COUNT DISTINCT date
//
// 等级百分位（levelPercentile）需要全量用户数据，必须调服务端 API
class _StatisticsAggregator {
}
