import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../data/daos/statistics_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/statistics_repository.dart';
import '../../../widgets/shared/loading_indicator.dart';
import 'widgets/time_range_picker.dart';
import 'widgets/heatmap_chart.dart';
import 'widgets/trend_chart.dart';
import 'widgets/donut_chart.dart';

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
  StatsOverview? _overview;
  List<DailyRecord>? _dailyRecords;
  List<TrendPoint>? _accuracyTrend;
  List<TrendPoint>? _pointsTrend;
  Distribution? _distribution;

  @override
  void initState() {
    super.initState();
    _repo = widget.statisticsRepository ?? StatisticsRepository(StatisticsDao(DatabaseProvider().appDb));
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final ov = await _repo.getOverview();
      final dr = await _repo.getDailyRecords(_rangeDays);
      final at = await _repo.getAccuracyTrend(_rangeDays);
      final pt = await _repo.getPointsTrend(_rangeDays);
      final dist = await _repo.getDistribution();
      if (!mounted) return;
      setState(() { _overview = ov; _dailyRecords = dr; _accuracyTrend = at; _pointsTrend = pt; _distribution = dist; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('📊 学习统计')),
    body: _loading
        ? const LoadingIndicator(message: '加载统计数据…')
        : RefreshIndicator(
            onRefresh: _loadAll,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSizes.baseSpacing),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildOverviewCards(),
                  const SizedBox(height: 12),
                  TimeRangePicker(valueDays: _rangeDays, onChanged: (d) { setState(() => _rangeDays = d); _loadAll(); }),
                  const SizedBox(height: 12),
                  HeatmapChart(rangeDays: _rangeDays, records: _dailyRecords ?? []),
                  const SizedBox(height: 8),
                  TrendChart(title: '正确率趋势', points: _accuracyTrend ?? []),
                  const SizedBox(height: 8),
                  TrendChart(title: '积分累计趋势', points: _pointsTrend ?? [], lineColor: AppColors.success),
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
          _overviewCard('答题数', '${ov.totalQuestions}', Icons.checklist, AppColors.primary),
          const SizedBox(width: 8),
          _overviewCard('正确率', '${ov.accuracyPercent.toStringAsFixed(0)}%', Icons.percent, AppColors.success),
          const SizedBox(width: 8),
          _overviewCard('连续学习', '${ov.streakDays} 天', Icons.local_fire_department, Colors.orange),
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
