import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import '../../../widgets/shared/format_utils.dart';

/// 积分概览卡片 — 4 列数值展示
///
/// PointsPage / LevelDetailPage 共用。
class PointSummaryCard extends StatelessWidget {
  final double earned;
  final double bonus;
  final double spent;
  final double available;
  final double valueFontSize;

  const PointSummaryCard({
    super.key,
    required this.earned,
    required this.bonus,
    required this.spent,
    required this.available,
    this.valueFontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            _item(context, '学习积分', earned, colors.primary),
            _item(context, '赠送积分', bonus, colors.warning),
            _item(context, '消耗积分', spent, colors.error),
            _item(context, '可用积分', available, colors.primary),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, String label, double value, Color color) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            formatAmount(value),
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
