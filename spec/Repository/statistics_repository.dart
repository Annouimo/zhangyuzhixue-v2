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
  static Future<StatsOverview> getOverview() async {
    throw UnimplementedError('StatisticsRepository.getOverview');
  }

  /// 总做题数（profile.html 快捷用法）
  static Future<int> totalQuestions() async {
    throw UnimplementedError('StatisticsRepository.totalQuestions');
  }

  /// 总体正确率（profile.html 快捷用法）
  static Future<double> accuracy() async {
    throw UnimplementedError('StatisticsRepository.accuracy');
  }

  /// GET /api/stats/daily-records?range={days}
  static Future<List<DailyRecord>> getDailyRecords(int rangeDays) async {
    throw UnimplementedError('StatisticsRepository.getDailyRecords');
  }

  /// GET /api/stats/accuracy-trend?range={days}
  static Future<List<TrendPoint>> getAccuracyTrend(int rangeDays) async {
    throw UnimplementedError('StatisticsRepository.getAccuracyTrend');
  }

  /// GET /api/stats/points-trend?range={days}
  static Future<List<TrendPoint>> getPointsTrend(int rangeDays) async {
    throw UnimplementedError('StatisticsRepository.getPointsTrend');
  }

  /// GET /api/stats/distribution/
  static Future<Distribution> getDistribution() async {
    throw UnimplementedError('StatisticsRepository.getDistribution');
  }
}

// ---- 统计聚合引擎 ----
// 从本地 drift 做题记录表中聚合统计
class _StatisticsAggregator {
  // totalQuestions: SELECT COUNT(*) FROM answer_records
  // accuracyPercent: SELECT SUM(is_correct)/COUNT(*) FROM answer_records
  // streakDays: 从 daily_records 计算最长连续
  // activeDays: SELECT COUNT(DISTINCT date) FROM daily_records
  // dailyRecords: SELECT date, COUNT(*) FROM answer_records GROUP BY date
  // accuracyTrend: 按日期窗口滑动计算正确率
  // pointsTrend: 按日期窗口滑动计算积分
  // distribution: 按 question_type 分组计数+算百分比
}
