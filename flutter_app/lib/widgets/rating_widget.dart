import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 星星评分组件（三个维度 + 算法分显示）
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

  Widget _starRow(String label, int value, double algorithmScore, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
              ...List.generate(10, (i) {
                final starIdx = i + 1;
                return GestureDetector(
                  onTap: () => onChanged(starIdx),
                  child: Icon(
                    starIdx <= value ? Icons.star : Icons.star_border,
                    color: starIdx <= value ? Colors.amber : AppTheme.dividerColor,
                    size: 22,
                  ),
                );
              }),
              const SizedBox(width: 8),
              Text('$value', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 80),
            child: Text('算法分 $algorithmScore', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ),
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
            _starRow('难度', _difficulty, 6.6, (v) => setState(() => _difficulty = v)),
            _starRow('计算量', _calculation, 6.6, (v) => setState(() => _calculation = v)),
            _starRow('优雅度', _elegance, 0.0, (v) => setState(() => _elegance = v)),
            const SizedBox(height: 12),
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
