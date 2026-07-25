import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_button.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_status_badge.dart';

/// 完成后的下一步操作区。
class DoneBanner extends StatelessWidget {
  const DoneBanner({
    super.key,
    this.isRated = false,
    this.onNext,
    this.onRate,
  });

  final bool isRated;
  final VoidCallback? onNext;
  final VoidCallback? onRate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final message = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppStatusBadge(
                label: '本题已完成',
                tone: AppStatusTone.success,
                icon: Icons.celebration_rounded,
              ),
              if (isRated) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.star_rounded, size: 18, color: colors.warning),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  '已评分',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.warning,
                      ),
                ),
              ],
            ],
          );

          final actions = Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.end,
            children: [
              if (onRate != null)
                AppButton(
                  label: isRated ? '查看评分' : '给题目评分',
                  icon: Icons.star_outline_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: onRate,
                ),
              if (onNext != null)
                AppButton(
                  label: '下一题',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: onNext,
                ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                message,
                if (onRate != null || onNext != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  actions,
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: message),
              if (onRate != null || onNext != null) actions,
            ],
          );
        },
      ),
    );
  }
}
