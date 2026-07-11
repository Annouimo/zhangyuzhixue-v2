import 'package:flutter/material.dart';
import '../../../app_theme.dart';

/// 时间范围选择 pill 组（5 选 1）
class TimeRangePicker extends StatelessWidget {
  final int valueDays;
  final ValueChanged<int> onChanged;

  static const _options = [
    (label: '近一周', days: 7),
    (label: '近一月', days: 30),
    (label: '近三月', days: 90),
    (label: '近一年', days: 365),
    (label: '全部', days: 0),
  ];

  const TimeRangePicker({super.key, required this.valueDays, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.baseSpacing),
      child: Row(
        children: _options.map((o) {
          final sel = valueDays == o.days;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(o.label, style: TextStyle(fontSize: 13, color: sel ? Colors.white : AppColors.textPrimary)),
              selected: sel,
              onSelected: (_) => onChanged(o.days),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.grey[100],
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          );
        }).toList(),
      ),
    );
  }
}
