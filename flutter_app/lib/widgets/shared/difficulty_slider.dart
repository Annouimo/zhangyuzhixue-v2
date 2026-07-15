import 'package:flutter/material.dart';
import '../../app_theme.dart';

/// 难度/计算量 5 段滑块
///
/// label 含 '难度' → 难度断点+标签；含 '计算' → 计算量断点+标签
class DifficultySlider extends StatelessWidget {
  final double min;
  final double max;
  final double lower;
  final double upper;
  final ValueChanged<RangeValues> onChanged;
  final String label;

  bool get _isDifficulty => label.contains('难度');

  List<double> get _breaks => _isDifficulty ? DifficultySegments.diffBreaks : DifficultySegments.calcBreaks;
  List<String> get _labels => _isDifficulty ? DifficultySegments.diffLabels : DifficultySegments.calcLabels;

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
          labels: RangeLabels(_segNameFor(lower), _segNameFor(upper)),
          onChanged: onChanged,
          activeColor: AppColors.primary,
          inactiveColor: Colors.grey[200],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _labels.map((l) => Text(l, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))).toList(),
          ),
        ),
      ],
    );
  }

  String _segNameFor(double v) {
    return DifficultySegments.nameFor(v, breaks: _breaks, labels: _labels);
  }
}
