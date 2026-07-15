import 'package:flutter/material.dart';
import '../../app_theme.dart';
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            _item('学习积分', earned, AppColors.primary),
            _item('赠送积分', bonus, AppColors.warning),
            _item('消耗积分', spent, AppColors.error),
            _item('可用积分', available, AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _item(String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(formatAmount(value),
            style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
