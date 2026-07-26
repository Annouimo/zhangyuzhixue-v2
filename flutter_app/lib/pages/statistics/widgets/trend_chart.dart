import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import '../../../../domain/statistics_repository.dart';

/// 折线图（正确率趋势 / 积分累计趋势）
class TrendChart extends StatelessWidget {
  final String title;
  final List<TrendPoint> points;
  final Color? lineColor;
  final bool fixedYRange;
  final String? summaryLabel;
  final String? summaryValue;

  const TrendChart({
    super.key,
    required this.title,
    required this.points,
    this.lineColor,
    this.fixedYRange = false,
    this.summaryLabel,
    this.summaryValue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolvedLineColor = lineColor ?? colors.primary;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: 12),
            if (points.length < 2)
              SizedBox(
                width: double.infinity,
                height: 160,
                child: Center(
                  child: Text(
                    '暂无数据',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 160,
                child: CustomPaint(
                  painter: _TrendPainter(
                    points,
                    resolvedLineColor,
                    colors,
                    fixedYRange: fixedYRange,
                  ),
                ),
              ),
            if (summaryLabel != null && summaryValue != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      summaryLabel!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      summaryValue!,
                      style: textTheme.labelLarge?.copyWith(
                        color: resolvedLineColor,
                      ),
                    ),
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
  final AppSemanticColors colors;
  final bool fixedYRange;
  _TrendPainter(
    this.points,
    this.color,
    this.colors, {
    this.fixedYRange = false,
  });

  static const _yAxisWidth = 40.0;
  static const _xAxisHeight = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final chartRect = Rect.fromLTWH(
      _yAxisWidth,
      0,
      size.width - _yAxisWidth,
      size.height - _xAxisHeight,
    );
    if (chartRect.width <= 0 || chartRect.height <= 0) return;

    final maxVal = fixedYRange
        ? 100
        : points.map((p) => p.value).reduce(math.max);
    final minVal = fixedYRange
        ? 0
        : points.map((p) => p.value).reduce(math.min);
    final valRange = (maxVal - minVal).clamp(1e-6, double.maxFinite);
    final stepX = chartRect.width / (points.length - 1);

    // ── Grid lines (5 horizontal) ──
    final gridPaint = Paint()
      ..color = colors.border.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    final yLabelStyle = TextStyle(fontSize: 9, color: colors.textMuted);
    for (var i = 0; i < 5; i++) {
      final y = chartRect.top + chartRect.height * i / 4;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
      // Y-axis label
      final tickVal = maxVal - (maxVal - minVal) * i / 4;
      final label = fixedYRange
          ? '${tickVal.toInt()}%'
          : tickVal.toStringAsFixed(0);
      final tp = TextPainter(
        text: TextSpan(text: label, style: yLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: _yAxisWidth - 4);
      tp.paint(canvas, Offset(_yAxisWidth - tp.width - 4, y - tp.height / 2));
    }

    // ── X-axis labels (first, middle, last) ──
    final xLabelStyle = TextStyle(fontSize: 9, color: colors.textMuted);
    for (final idx in [0, points.length ~/ 2, points.length - 1]) {
      final x = chartRect.left + idx * stepX;
      final label = points[idx].label.length >= 10
          ? points[idx].label.substring(5, 10)
          : points[idx].label;
      final tp = TextPainter(
        text: TextSpan(text: label, style: xLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartRect.bottom + 2));
    }

    // ── Line chart within chartRect ──
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
      ).createShader(chartRect);

    final path = Path();
    final pts = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final x = chartRect.left + i * stepX;
      final y =
          chartRect.bottom -
          ((points[i].value - minVal) / valRange) * chartRect.height;
      pts.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    // Fill
    final fillPath = Path.from(path);
    fillPath.lineTo(pts.last.dx, chartRect.bottom);
    fillPath.lineTo(pts.first.dx, chartRect.bottom);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    // Line
    canvas.drawPath(path, linePaint);
    // Dots
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final pt in pts) {
      canvas.drawCircle(pt, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.points != points || old.color != color || old.colors != colors;
}
