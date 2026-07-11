import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app_theme.dart';
import '../../../../domain/statistics_repository.dart';

/// 环形图（题型分布）
class DonutChart extends StatelessWidget {
  final Distribution data;

  const DonutChart({super.key, required this.data});

  static const _colors = [Color(0xFF4A6CF7), Color(0xFF10B981), Color(0xFFF59E0B)];
  static const _labels = ['选择题', '填空题', '解答题'];

  @override
  Widget build(BuildContext context) {
    final counts = [data.choiceCount, data.fillCount, data.solutionCount];
    final pcts = [data.choicePercent, data.fillPercent, data.solutionPercent];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('题型分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (data.total == 0)
              SizedBox(height: 120, child: Center(child: Text('暂无数据', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))))
            else
              Row(
                children: [
                  SizedBox(width: 100, height: 100, child: CustomPaint(painter: _DonutPainter(pcts, _colors))),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: List.generate(3, (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: _colors[i], shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Expanded(child: Text(_labels[i], style: const TextStyle(fontSize: 13))),
                          Text('${counts[i]} 题', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(width: 8),
                          Text('${pcts[i].toStringAsFixed(0)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ]),
                      )),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  _DonutPainter(this.values, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 20;
    double start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = values[i] / 100 * 2 * math.pi;
      if (sweep > 0) {
        paint.color = colors[i];
        canvas.drawArc(rect, start, sweep, false, paint);
        start += sweep;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.values != values;
}
