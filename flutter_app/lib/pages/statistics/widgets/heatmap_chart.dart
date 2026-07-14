import 'package:flutter/material.dart';
import '../../../../app_theme.dart';
import '../../../../domain/statistics_repository.dart';

/// 做题热力图 — 自适应粒度（条形图/7行周历/周贡献图/月格）
class HeatmapChart extends StatelessWidget {
  final int rangeDays;
  final List<DailyRecord> records;

  const HeatmapChart({super.key, required this.rangeDays, required this.records});

  int _actualDataDays() {
    if (records.isEmpty) return rangeDays > 0 ? rangeDays : 365;
    final dates = records.map((r) => DateTime.parse(r.date));
    final earliest = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime.now().difference(earliest).inDays + 1;
  }

  int _displayDays() {
    final d = rangeDays > 0 ? rangeDays : _actualDataDays();
    if (d <= 14) return d; // bar mode: full range
    return d;
  }

  String _mode(int actualDays) {
    if (actualDays <= 14) return 'bar';
    if (actualDays <= 90) return 'weeks';
    if (actualDays <= 730) return 'weekly';
    return 'monthly';
  }

  @override
  Widget build(BuildContext context) {
    final map = {for (final r in records) r.date: r.level};
    final countMap = {for (final r in records) r.date: r.count};
    final now = DateTime.now();
    final actualDays = _actualDataDays();
    final mode = _mode(actualDays);
    final displayDays = _displayDays();

    Widget chart;
    if (mode == 'bar') {
      chart = _buildBar(displayDays, now, map);
    } else if (mode == 'weeks') {
      chart = _buildWeekCalendar(displayDays, now, map);
    } else if (mode == 'weekly') {
      chart = _buildWeeklyGrid(displayDays, now, map, countMap);
    } else {
      chart = _buildMonthlyGrid(displayDays, now, map, countMap);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('做题热力图', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(height: mode == 'bar' ? (displayDays + 1) * 20.0 : 160, child: chart),
            const SizedBox(height: 8),
            Row(children: [
              ...List.generate(4, (i) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(width: 12, height: 12, decoration: BoxDecoration(color: _color(i), borderRadius: BorderRadius.circular(2))),
              )),
              const SizedBox(width: 4),
              const Text('少', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              const Spacer(),
              const Text('多', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ]),
          ],
        ),
      ),
    );
  }

  // ── 水平条形图（≤14天） ──
  Widget _buildBar(int days, DateTime now, Map<String, int> map) {
    return SizedBox(
      height: (days + 1) * 20.0,
      child: ListView.builder(
        itemCount: days,
        itemBuilder: (_, i) {
          final d = now.subtract(Duration(days: days - 1 - i));
          final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          final lv = map[key] ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(children: [
              SizedBox(width: 70, child: Text('${d.month}/${d.day}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))),
              const SizedBox(width: 4),
              Expanded(child: Container(height: 16, decoration: BoxDecoration(
                color: _color(lv), borderRadius: BorderRadius.circular(2)))),
            ]),
          );
        },
      ),
    );
  }

  // ── 7行周历（15~90天） ──
  Widget _buildWeekCalendar(int days, DateTime now, Map<String, int> map) {
    final start = now.subtract(Duration(days: days - 1));
    final monday = _getMonday(start);
    // Build date map
    final dMap = <String, int>{};
    for (var i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      dMap[key] = map[key] ?? 0;
    }

    // Generate week columns
    final weeks = <DateTime>[];
    var w = DateTime(monday.year, monday.month, monday.day);
    while (w.compareTo(now) <= 0) {
      weeks.add(DateTime(w.year, w.month, w.day));
      w = w.add(const Duration(days: 7));
    }

    final dayLabels = ['', '一', '二', '三', '四', '五', '六', '日'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 行标列
          Column(
            children: [
              const SizedBox(height: 14, width: 22), // 列头占位
              ...dayLabels.skip(1).map((lbl) => Container(
                width: 22, height: 14, alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 2),
                child: Text(lbl, style: const TextStyle(fontSize: 8, color: AppColors.textMuted)),
              )),
            ],
          ),
          // 每周列
          ...weeks.map((weekStart) {
            final colHeader = '${weekStart.month}/${weekStart.day}';
            return Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Column(
                children: [
                  SizedBox(
                    height: 14,
                    child: Text(colHeader, style: const TextStyle(fontSize: 7, color: AppColors.textMuted)),
                  ),
                  ...List.generate(7, (wd) {
                    final d = weekStart.add(Duration(days: wd));
                    final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                    final lv = dMap[key] ?? 0;
                    return Container(
                      width: 12, height: 12, margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: d.isAfter(now) ? Colors.transparent : _color(lv),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 周格（91~730天） ──
  Widget _buildWeeklyGrid(int days, DateTime now, Map<String, int> map, Map<String, int> countMap) {
    final start = now.subtract(Duration(days: days - 1));
    // Group by ISO week
    final weekData = <String, int>{};
    final weekLabels = <String, String>{};
    for (var i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      final key = '${d.year}-W${_isoWeek(d)}';
      if (!weekLabels.containsKey(key)) {
        weekLabels[key] = '${d.month}月';
      }
      weekData[key] = (weekData[key] ?? 0) + (countMap[_dateKey(d)] ?? 0);
    }

    final maxVal = weekData.values.isEmpty ? 0 : weekData.values.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: weekData.entries.map((e) {
          final lv = _levelOf(e.value, maxVal);
          return Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            decoration: BoxDecoration(
              color: _color(lv),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Text('${e.value}', style: TextStyle(fontSize: 11, fontWeight: lv >= 2 ? FontWeight.w600 : FontWeight.normal,
                  color: lv >= 2 ? Colors.white : AppColors.textPrimary)),
                if (weekLabels.containsKey(e.key))
                  Text(weekLabels[e.key]!, style: TextStyle(fontSize: 8, color: lv >= 2 ? Colors.white70 : AppColors.textMuted)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 月格（>730天） ──
  Widget _buildMonthlyGrid(int days, DateTime now, Map<String, int> map, Map<String, int> countMap) {
    final start = now.subtract(Duration(days: days - 1));
    // Group by month
    final monthData = <String, int>{};
    final monthLabels = <String, String>{};
    for (var i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      monthData[key] = (monthData[key] ?? 0) + (countMap[_dateKey(d)] ?? 0);
      monthLabels[key] = '${d.month}月';
    }

    final maxVal = monthData.values.isEmpty ? 0 : monthData.values.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: monthData.entries.map((e) {
          final lv = _levelOf(e.value, maxVal);
          return Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: _color(lv),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Text('${e.value}', style: TextStyle(fontSize: 13, fontWeight: lv >= 2 ? FontWeight.w600 : FontWeight.normal,
                  color: lv >= 2 ? Colors.white : AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(monthLabels[e.key] ?? '', style: TextStyle(fontSize: 9, color: lv >= 2 ? Colors.white70 : AppColors.textMuted)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 工具方法 ──

  String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _getMonday(DateTime d) {
    final weekday = d.weekday; // 1=Mon, 7=Sun
    return d.subtract(Duration(days: weekday - 1));
  }

  int _isoWeek(DateTime d) {
    // Approximate ISO week number (not exact but good enough for grouping)
    final startOfYear = DateTime(d.year, 1, 1);
    final diff = d.difference(startOfYear).inDays;
    return ((diff + startOfYear.weekday - 1) / 7).floor() + 1;
  }

  int _levelOf(int val, int maxVal) {
    if (maxVal == 0) return 0;
    final r = val / maxVal;
    if (r == 0) return 0;
    if (r <= 0.33) return 1;
    if (r <= 0.66) return 2;
    return 3;
  }

  Color _color(int level) {
    return switch (level) { 1 => const Color(0xFFD6E4FF), 2 => const Color(0xFF84A9FF), 3 => const Color(0xFF3366FF), _ => Colors.grey[100]! };
  }
}
