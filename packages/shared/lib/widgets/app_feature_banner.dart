import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 页面顶部的功能说明横幅。
///
/// 用于组卷、作业、讲义、统计等入口页，统一表达“当前页面做什么”以及
/// 最重要的下一步操作。紧凑屏幕自动改为纵向布局。
class AppFeatureBanner extends StatelessWidget {
  const AppFeatureBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.action,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? eyebrow;
  final Widget? action;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.surface],
        ),
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        border: Border.all(color: colors.primaryBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < AppBreakpoints.compact;
            final copy = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Icon(icon, color: colors.onPrimary, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow != null) ...[
                        Text(
                          eyebrow!,
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                      ],
                      Text(title, style: textTheme.headlineSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact || action == null)
                  copy
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: AppSpacing.lg),
                      action!,
                    ],
                  ),
                if (compact && action != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  action!,
                ],
                if (footer != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  footer!,
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
