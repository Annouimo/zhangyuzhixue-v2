import 'package:flutter/material.dart';

/// 时间范围选择器。
class TimeRangePicker extends StatelessWidget {
  const TimeRangePicker({
    super.key,
    required this.valueDays,
    required this.onChanged,
  });

  final int valueDays;
  final ValueChanged<int> onChanged;

  static const _options = [
    (label: '近一周', days: 7),
    (label: '近一月', days: 30),
    (label: '近三月', days: 90),
    (label: '近一年', days: 365),
    (label: '全部', days: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<int>(
        segments: _options
            .map(
              (option) => ButtonSegment<int>(
                value: option.days,
                label: Text(option.label),
              ),
            )
            .toList(),
        selected: {valueDays},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}
