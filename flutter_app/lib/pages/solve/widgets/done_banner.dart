import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_button.dart';
import 'package:shared/widgets/app_section.dart';
import 'package:shared/widgets/app_status_badge.dart';

/// 完成后的下一步操作区。
class DoneBanner extends StatelessWidget {
  const DoneBanner({
    super.key,
    this.isRated = false,
    this.onNext,
    this.onRate,
    this.onFinish,
    this.nextLabel = '下一题',
  });

  final bool isRated;
  final VoidCallback? onNext;
  final VoidCallback? onRate;
  final VoidCallback? onFinish;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppSection(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final message = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  const AppStatusBadge(
                    label: '本题已完成',
                    tone: AppStatusTone.success,
                    icon: Icons.check_circle_rounded,
                  ),
                  if (isRated)
                    const AppStatusBadge(
                      label: '已评分',
                      tone: AppStatusTone.recommendation,
                      icon: Icons.star_rounded,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                onNext != null ? '作答结果已经保存，可以继续完成下一题。' : '作答结果已经保存，可以返回继续学习。',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
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
                  fullWidth: false,
                  onPressed: onRate,
                ),
              if (onNext != null)
                AppButton(
                  label: nextLabel,
                  icon: Icons.arrow_forward_rounded,
                  fullWidth: false,
                  onPressed: onNext,
                ),
              if (onNext == null && onFinish != null)
                AppButton(
                  label: '完成并返回',
                  icon: Icons.check_rounded,
                  fullWidth: false,
                  onPressed: onFinish,
                ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                message,
                if (onRate != null || onNext != null || onFinish != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  actions,
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: message),
              if (onRate != null || onNext != null || onFinish != null) actions,
            ],
          );
        },
      ),
    );
  }
}
