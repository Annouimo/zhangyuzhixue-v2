import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'app_card.dart';
import 'app_status_badge.dart';

/// 仪表盘数据卡片。
class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone = AppStatusTone.primary,
    this.supportingText,
  });

  final String label;
  final String value;
  final IconData icon;
  final AppStatusTone tone;
  final String? supportingText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = _resolve(colors);
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.background,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Icon(icon, color: scheme.foreground, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: textTheme.titleLarge?.copyWith(
                    color: scheme.foreground,
                  ),
                ),
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (supportingText != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    supportingText!,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({Color background, Color foreground}) _resolve(
    AppSemanticColors colors,
  ) => switch (tone) {
        AppStatusTone.neutral => (
            background: colors.surfaceSubtle,
            foreground: colors.textSecondary,
          ),
        AppStatusTone.primary => (
            background: colors.primaryContainer,
            foreground: colors.onPrimaryContainer,
          ),
        AppStatusTone.info => (
            background: colors.infoContainer,
            foreground: colors.onInfoContainer,
          ),
        AppStatusTone.success => (
            background: colors.successContainer,
            foreground: colors.onSuccessContainer,
          ),
        AppStatusTone.warning => (
            background: colors.warningContainer,
            foreground: colors.onWarningContainer,
          ),
        AppStatusTone.error => (
            background: colors.errorContainer,
            foreground: colors.onErrorContainer,
          ),
        AppStatusTone.recommendation => (
            background: colors.recommendationContainer,
            foreground: colors.onRecommendationContainer,
          ),
      };
}
