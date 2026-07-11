import 'package:flutter/material.dart';
import '../../../../app_theme.dart';
import '../../../../domain/statistics_repository.dart';

/// 做题热力图 — 自适应粒度（条形图/7行周历/周贡献图/月格）
class HeatmapChart extends StatelessWidget {
  final int rangeDays;
  final List<DailyRecord> records;

  const HeatmapChart({super.key, required this.rangeDays, required this.records});

  String _mode() {
    if (rangeDays <= 14 || rangeDays == 0) return 'bar'; // ≤14天或全部→条形
    if (rangeDays <= 90) return 'weeks'; // 15-90→周历
    if (rangeDays <= 730) return 'weekly'; // 91-730→周贡献
    return 'monthly'; // >730→月格
  }

  @override
  Widget build(BuildContext context) {
    final map = {for (final r in records) r.date: r.level};
    final now = DateTime.now();
    final days = rangeDays > 0 ? rangeDays : 365;
    final mode = _mode();

    Widget chart;
    if (mode == 'bar') {
      // 水平条形图
      chart = SizedBox(
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
    } else if (mode == 'weeks') {
      chart = _buildCalendar(days, now, map);
    } else {
      chart = _buildCalendar(days, now, map);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('做题热力图', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(height: mode == 'bar' ? (days + 1) * 20.0 : 140, child: chart),
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

  Widget _buildCalendar(int days, DateTime now, Map<String, int> map) {
    final start = now.subtract(Duration(days: days - 1));
    final cells = <Widget>[];
    for (int i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      cells.add(Container(
        width: 14, height: 14, margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: _color(map[key] ?? 0), borderRadius: BorderRadius.circular(2)),
      ));
    }
    return Wrap(children: cells);
  }

  Color _color(int level) {
    return switch (level) { 1 => const Color(0xFFD6E4FF), 2 => const Color(0xFF84A9FF), 3 => const Color(0xFF3366FF), _ => Colors.grey[100]! };
  }
}
