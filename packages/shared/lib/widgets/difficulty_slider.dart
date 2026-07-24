import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';

/// 难度/计算量滑块（RangeSlider 封装）
class DifficultySlider extends StatelessWidget {
  final String label;
  final double min;
  final double max;
  final double lower;
  final double upper;
  final ValueChanged<RangeValues> onChanged;
  final int divisions;

  const DifficultySlider({
    super.key,
    required this.label,
    required this.min,
    required this.max,
    required this.lower,
    required this.upper,
    required this.onChanged,
    this.divisions = 20,
  });

  @override
  Widget build(BuildContext context) {
      final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: colors.textPrimary,
          ),
        ),
        if (lower == upper)
          Slider(
            value: lower,
            min: min,
            max: max,
            divisions: divisions,
            label: lower.toStringAsFixed(1),
            onChanged: (v) => onChanged(RangeValues(v, v)),
            activeColor: colors.primary,
            inactiveColor: colors.border,
          )
        else
          RangeSlider(
            values: RangeValues(lower, upper),
            min: min,
            max: max,
            divisions: divisions,
            labels: RangeLabels(
              lower.toStringAsFixed(1),
              upper.toStringAsFixed(1),
            ),
            onChanged: onChanged,
            activeColor: colors.primary,
            inactiveColor: colors.border,
          ),
      ],
    );
  }
}
