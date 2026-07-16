import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../widgets/shared/error_placeholder.dart';
import '../../../widgets/shared/format_utils.dart';
import '../../../data/daos/statistics_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/statistics_repository.dart';
import '../../../widgets/shared/loading_indicator.dart';
import 'widgets/time_range_picker.dart';
import 'widgets/heatmap_chart.dart';
import 'widgets/trend_chart.dart';
import 'widgets/donut_chart.dart';
import '../../data/debug/audit_logger.dart';

/// 学习统计页
class StatisticsPage extends StatefulWidget {
  final StatisticsRepository? statisticsRepository;
  const StatisticsPage({super.key, this.statisticsRepository});

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
    _repo = widget.statisticsRepository ?? StatisticsRepository(
      StatisticsDao(DatabaseProvider()),
      questionDao: QuestionDao(DatabaseProvider()),
    );
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      // 并行加载 5 项独立数据
      final results = await Future.wait([
        _repo.getOverview(),
        _repo.getDailyRecords(_rangeDays),
        _repo.getPointsTrend(_rangeDays),
        _repo.getDistribution(rangeDays: _rangeDays),
      ]);
      final ov = results[0] as StatsOverview;
      final dr = results[1] as List<DailyRecord>;
      // 正确率趋势从 dailyRecords 派生，不再重复查询
      final at = StatisticsRepository.deriveAccuracyTrend(dr);
      final pt = results[2] as List<TrendPoint>;
      final dist = results[3] as Distribution;
      if (!mounted) return;
      setState(() {
        _overview = ov; _dailyRecords = dr; _accuracyTrend = at; _pointsTrend = pt; _distribution = dist;
        // 全时段整体正确率（sum(correct)/sum(count)），匹配 HTML 原型
        _accuracySummary = dr.isNotEmpty
            ? '${(dr.fold<int>(0, (s, r) => s + r.correct) / dr.fold<int>(0, (s, r) => s + r.count) * 100).toStringAsFixed(0)}%'
            : null;
        _pointsSummary = pt.isNotEmpty ? formatAmount(pt.last.value) : null;
        _loading = false;
      });
      AuditLogger.instance.page('StatisticsPage', {'hasData': _overview != null});
    } catch (e) { AuditLogger.instance.error('StatisticsPage._loadAll', e); if (mounted) { setState(() { _error = e.toString(); _loading = false; }); } }
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSizes.baseSpacing),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  TimeRangePicker(valueDays: _rangeDays, onChanged: (d) { setState(() => _rangeDays = d); _loadAll(); }),
                  const SizedBox(height: 12),
                  _buildOverviewCards(),
                  const SizedBox(height: 12),
                  HeatmapChart(rangeDays: _rangeDays, records: _dailyRecords ?? []),
                  const SizedBox(height: 4),
                  // 热力图图例
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('少', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Container(width: 12, height: 12, margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                      Container(width: 12, height: 12, margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(color: AppColors.heatmapLevel1, borderRadius: BorderRadius.circular(2))),
                      Container(width: 12, height: 12, margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(color: AppColors.heatmapLevel2, borderRadius: BorderRadius.circular(2))),
                      Container(width: 12, height: 12, margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(color: AppColors.heatmapLevel3, borderRadius: BorderRadius.circular(2))),
                      const Text('多', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TrendChart(title: '正确率趋势', points: _accuracyTrend ?? [], fixedYRange: true,
                    summaryLabel: '该时段正确率', summaryValue: _accuracySummary),
                  const SizedBox(height: 8),
                  TrendChart(title: '积分累计趋势', points: _pointsTrend ?? [], lineColor: AppColors.success,
                    summaryLabel: '时段累计积分', summaryValue: _pointsSummary),
                  const SizedBox(height: 8),
                  DonutChart(data: _distribution ?? const Distribution(total: 0, choiceCount: 0, choicePercent: 0, fillCount: 0, fillPercent: 0, solutionCount: 0, solutionPercent: 0)),
                ],
              ),
            ),
          ),
  );

  Widget _buildOverviewCards() {
    final ov = _overview;
    if (ov == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.baseSpacing),
      child: Row(
        children: [
          _overviewCard('总做题', '${ov.totalQuestions}', Icons.checklist, AppColors.primary),
          const SizedBox(width: 8),
          _overviewCard('正确率', '${ov.accuracyPercent.toStringAsFixed(0)}%', Icons.percent, AppColors.success),
          const SizedBox(width: 8),
          _overviewCard('连续做题天', '${ov.streakDays} 天', Icons.local_fire_department, Colors.orange),
          const SizedBox(width: 8),
          _overviewCard('活跃天', '${ov.activeDays}', Icons.today, AppColors.primaryLight),
        ],
      ),
    );
  }

  Widget _overviewCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
