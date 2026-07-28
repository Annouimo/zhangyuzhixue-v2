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

/// 实际实现见 `flutter_app/lib/domain/statistics_repository.dart`
/// （本地查询，委托 StatisticsDao + QuestionDao，不走 API）
///
/// ---- 统计聚合引擎 ----
// 从 StatisticsDAO 获取原始数据，在 Dart 侧做聚合计算。
// 渲染层设计见 docs/04-UI/html/statistics.html（含 4 种自适应模式 + 示例 JS）
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
//     → dao.getAttemptedQuestionIds() + QuestionDao.getByIds()
//     → Dart 侧按 questionType 分组并算百分比
//
// 概览（getOverview）：从上述数据计算：
//   totalQuestions = sum of count
//   accuracyPercent = sum(correct) / sum(count)
//   streakDays = 从 submissionDetail 推算的当前连续做题天数（从今天回溯）
//   activeDays = COUNT DISTINCT date
//
// 等级百分位（levelPercentile）需要全量用户数据，必须调服务端 API
class _StatisticsAggregator {
}
