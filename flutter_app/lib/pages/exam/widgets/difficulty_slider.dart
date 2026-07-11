import 'package:flutter/material.dart';
import '../../../app_theme.dart';

/// 难度/计算量 5 段滑块
class DifficultySlider extends StatelessWidget {
  final double min;
  final double max;
  final double lower;
  final double upper;
  final ValueChanged<RangeValues> onChanged;
  final String label;

  static const _labels = ['基础', '中档', '中难', '较难', '压轴'];
  static const _breaks = [0.0, 2.5, 5.0, 7.5, 10.0];

  const DifficultySlider({
    super.key,
    required this.min,
    required this.max,
    required this.lower,
    required this.upper,
    required this.onChanged,
    this.label = '难度',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        RangeSlider(
          values: RangeValues(lower, upper),
          min: min,
          max: max,
          divisions: 20,
          labels: RangeLabels(
            _labelFor(lower), _labelFor(upper),
          ),
          onChanged: onChanged,
          activeColor: AppColors.primary,
          inactiveColor: Colors.grey[200],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _labels.map((l) => Text(l, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))).toList(),
          ),
        ),
      ],
    );
  }

  String _labelFor(double v) {
    final idx = _breaks.lastIndexWhere((b) => v >= b);
    return _labels[idx.clamp(0, _labels.length - 1)];
  }
}
