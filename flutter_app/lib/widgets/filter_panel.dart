import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 筛选面板（展开/收起）
class FilterPanel extends StatefulWidget {
  final Map<String, dynamic> options;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const FilterPanel({super.key, required this.options, required this.onChanged});

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('筛选条件', style: TextStyle(fontWeight: FontWeight.w600, fontSize: AppTheme.fontSizeTitle)),
                  const Spacer(),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.paddingMedium, 0, AppTheme.paddingMedium, AppTheme.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('按来源选题', style: TextStyle(fontWeight: FontWeight.w500)),
                  Wrap(
                    spacing: 8,
                    children: [
                      filterChip('2025'), filterChip('2024'), filterChip('海淀'), filterChip('东城'),
                      filterChip('一模'), filterChip('二模'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('按难度', style: TextStyle(fontWeight: FontWeight.w500)),
                  RangeSlider(
                    values: const RangeValues(0, 10),
                    min: 0, max: 10,
                    divisions: 20,
                    labels: const RangeLabels('0', '10'),
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget filterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: AppTheme.fontSizeSmall)),
        selected: false,
        onSelected: (_) {},
      ),
    );
  }
}
