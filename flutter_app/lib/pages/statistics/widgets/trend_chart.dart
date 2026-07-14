import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app_theme.dart';
import '../../../../domain/statistics_repository.dart';

/// 折线图（正确率趋势 / 积分累计趋势）
class TrendChart extends StatelessWidget {
  final String title;
  final List<TrendPoint> points;
  final Color lineColor;
  final bool fixedYRange;
  final String? summaryLabel;
  final String? summaryValue;

  const TrendChart({super.key, required this.title, required this.points, this.lineColor = AppColors.primary, this.fixedYRange = false, this.summaryLabel, this.summaryValue});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (points.length < 2)
              SizedBox(
                width: double.infinity, height: 160,
                child: Center(
                  child: Text('暂无数据', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ),
              )
            else
              SizedBox(
              width: double.infinity, height: 160,
              child: CustomPaint(painter: _TrendPainter(points, lineColor, fixedYRange: fixedYRange)),
            ),
          if (summaryLabel != null && summaryValue != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(summaryLabel!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(summaryValue!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: lineColor)),
                ],
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<TrendPoint> points;
  final Color color;
  final bool fixedYRange;
  _TrendPainter(this.points, this.color, {this.fixedYRange = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    final fillPaint = Paint()..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final maxVal = fixedYRange ? 100 : points.map((p) => p.value).reduce(math.max);
    final minVal = fixedYRange ? 0 : points.map((p) => p.value).reduce(math.min);
    final range = (maxVal - minVal).clamp(1e-6, double.maxFinite);
    final stepX = size.width / (points.length - 1);

    final path = Path();
    final pts = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - ((points[i].value - minVal) / range) * (size.height - 20) - 10;
      pts.add(Offset(x, y));
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    // Fill
    final fillPath = Path.from(path);
    fillPath.lineTo(pts.last.dx, size.height);
    fillPath.lineTo(pts.first.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    // Line
    canvas.drawPath(path, paint);
    // Dots
    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
    for (final pt in pts) { canvas.drawCircle(pt, 3, dotPaint); }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.points != points;
}
