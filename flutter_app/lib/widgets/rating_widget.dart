import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 星星评分组件（三个维度）
class RatingWidget extends StatefulWidget {
  final void Function(int difficulty, int calculation, int elegance) onSubmit;

  const RatingWidget({super.key, required this.onSubmit});

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  int _difficulty = 0;
  int _calculation = 0;
  int _elegance = 0;

  Widget _starRow(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          ...List.generate(10, (i) {
            final starIdx = i + 1;
            return GestureDetector(
              onTap: () => onChanged(starIdx),
              child: Icon(
                starIdx <= value ? Icons.star : Icons.star_border,
                color: starIdx <= value ? Colors.amber : AppTheme.dividerColor,
                size: 24,
              ),
            );
          }),
          const SizedBox(width: 8),
          Text('$value', style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          children: [
            _starRow('难度', _difficulty, (v) => setState(() => _difficulty = v)),
            _starRow('计算量', _calculation, (v) => setState(() => _calculation = v)),
            _starRow('优雅度', _elegance, (v) => setState(() => _elegance = v)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onSubmit(_difficulty, _calculation, _elegance),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                child: const Text('提交评分'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
