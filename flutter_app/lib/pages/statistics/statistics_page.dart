import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/question_dao.dart';
import '../../data/daos/statistics_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/statistics_repository.dart';
import '../../widgets/shared/format_utils.dart';
import 'widgets/donut_chart.dart';
import 'widgets/heatmap_chart.dart';
import 'widgets/time_range_picker.dart';
import 'widgets/trend_chart.dart';

/// 学习统计页。
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, this.statisticsRepository});

  final StatisticsRepository? statisticsRepository;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late final StatisticsRepository _repo;
  bool _loading = true;
  int _rangeDays = 7;
  String? _error;
  StatsOverview? _overview;
  List<DailyRecord>? _dailyRecords;
  List<TrendPoint>? _accuracyTrend;
  List<TrendPoint>? _pointsTrend;
  Distribution? _distribution;
  String? _accuracySummary;
  String? _pointsSummary;

  @override
  void initState() {
    super.initState();
    _repo = widget.statisticsRepository ??
        StatisticsRepository(
          StatisticsDao(DatabaseProvider()),
          questionDao: QuestionDao(DatabaseProvider()),
        );
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.getOverview(),
        _repo.getDailyRecords(_rangeDays),
        _repo.getPointsTrend(_rangeDays),
        _repo.getDistribution(rangeDays: _rangeDays),
      ]);
      final overview = results[0] as StatsOverview;
      final dailyRecords = results[1] as List<DailyRecord>;
      final accuracyTrend = StatisticsRepository.deriveAccuracyTrend(
        dailyRecords,
      );
      final pointsTrend = results[2] as List<TrendPoint>;
      final distribution = results[3] as Distribution;
      final totalAnswers = dailyRecords.fold<int>(
        0,
        (sum, record) => sum + record.count,
      );
      final totalCorrect = dailyRecords.fold<int>(
        0,
        (sum, record) => sum + record.correct,
      );
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _dailyRecords = dailyRecords;
        _accuracyTrend = accuracyTrend;
        _pointsTrend = pointsTrend;
        _distribution = distribution;
        _accuracySummary = totalAnswers > 0
            ? '${(totalCorrect / totalAnswers * 100).toStringAsFixed(0)}%'
            : null;
        _pointsSummary = pointsTrend.isNotEmpty
            ? formatAmount(pointsTrend.last.value)
            : null;
        _loading = false;
      });
      AuditLogger.instance.page(
        'StatisticsPage',
        {'hasData': _overview != null},
      );
    } catch (error) {
      OperationLog.instance.error('statistics_page_load', error);
      AuditLogger.instance.error('StatisticsPage._loadAll', error);
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('学习统计')),
        body: _loading
            ? const LoadingIndicator(message: '加载统计数据…')
            : _error != null
                ? ErrorPlaceholder(message: _error!, onRetry: _loadAll)
                : RefreshIndicator(
                    onRefresh: _loadAll,
                    child: AppContentContainer(
                      maxWidth: AppContentWidth.dashboard,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        children: [
                          AppFeatureBanner(
                            eyebrow: '学习数据',
                            icon: Icons.insights_rounded,
                            title: '看见每一次积累',
                            subtitle: '通过做题数量、正确率、连续学习和题型分布，了解近期学习节奏。',
                            footer: TimeRangePicker(
                              valueDays: _rangeDays,
                              onChanged: (days) {
                                setState(() => _rangeDays = days);
                                _loadAll();
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const AppSectionHeader(
                            title: '核心概览',
                            subtitle: '总览数据不受当前时间范围筛选影响。',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildOverviewCards(),
                          const SizedBox(height: AppSpacing.xl),
                          AppSectionHeader(
                            title: '趋势与分布',
                            subtitle: '当前展示：${_rangeLabel(_rangeDays)}',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final twoColumns = constraints.maxWidth >=
                                  AppBreakpoints.expanded;
                              const gap = AppSpacing.md;
                              final width = twoColumns
                                  ? (constraints.maxWidth - gap) / 2
                                  : constraints.maxWidth;
                              final charts = <Widget>[
                                HeatmapChart(
                                  rangeDays: _rangeDays,
                                  records: _dailyRecords ?? [],
                                ),
                                TrendChart(
                                  title: '正确率趋势',
                                  points: _accuracyTrend ?? [],
                                  lineColor: context.colors.primary,
                                  fixedYRange: true,
                                  summaryLabel: '该时段正确率',
                                  summaryValue: _accuracySummary,
                                ),
                                TrendChart(
                                  title: '积分累计趋势',
                                  points: _pointsTrend ?? [],
                                  lineColor: context.colors.success,
                                  summaryLabel: '时段累计积分',
                                  summaryValue: _pointsSummary,
                                ),
                                DonutChart(
                                  data: _distribution ??
                                      Distribution(
                                        total: 0,
                                        choiceCount: 0,
                                        choicePercent: 0,
                                        fillCount: 0,
                                        fillPercent: 0,
                                        solutionCount: 0,
                                        solutionPercent: 0,
                                      ),
                                ),
                              ];
                              return Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: charts
                                    .map(
                                      (chart) => SizedBox(
                                        width: width,
                                        child: chart,
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
      );

  Widget _buildOverviewCards() {
    final overview = _overview;
    if (overview == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= AppBreakpoints.expanded
            ? 4
            : constraints.maxWidth >= AppBreakpoints.compact
                ? 2
                : 1;
        const gap = AppSpacing.sm;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap * (columns - 1)) / columns;
        final cards = [
          AppMetricCard(
            label: '总做题',
            value: '${overview.totalQuestions}',
            icon: Icons.checklist_rounded,
            tone: AppStatusTone.primary,
          ),
          AppMetricCard(
            label: '整体正确率',
            value: '${overview.accuracyPercent.toStringAsFixed(0)}%',
            icon: Icons.track_changes_rounded,
            tone: AppStatusTone.success,
          ),
          AppMetricCard(
            label: '连续学习',
            value: '${overview.streakDays} 天',
            icon: Icons.local_fire_department_rounded,
            tone: AppStatusTone.recommendation,
          ),
          AppMetricCard(
            label: '活跃天数',
            value: '${overview.activeDays}',
            icon: Icons.calendar_month_outlined,
            tone: AppStatusTone.info,
          ),
        ];
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }

  String _rangeLabel(int days) => switch (days) {
        7 => '近一周',
        30 => '近一月',
        90 => '近三月',
        365 => '近一年',
        _ => '全部记录',
      };
}
