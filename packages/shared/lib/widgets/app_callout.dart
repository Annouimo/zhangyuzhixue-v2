import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

enum AppCalloutTone { neutral, info, success, warning, error, recommendation }

/// 用于说明、审核意见、成功、警告和错误的语义色提示区。
///
/// Callout 是页面内容的一部分，不使用普通白卡、阴影或悬浮层级。
class AppCallout extends StatelessWidget {
  const AppCallout({
    super.key,
    required this.message,
    this.title,
    this.tone = AppCalloutTone.info,
    this.icon,
    this.action,
  });

  final String? title;
  final String message;
  final AppCalloutTone tone;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final scheme = _scheme(colors);

    return Semantics(
      container: true,
      liveRegion:
          tone == AppCalloutTone.error || tone == AppCalloutTone.warning,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border(left: BorderSide(color: scheme.foreground, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon ?? _defaultIcon, size: 20, color: scheme.foreground),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Text(
                        title!,
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.foreground,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                    ],
                    Text(
                      message,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.foreground,
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      action!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _defaultIcon => switch (tone) {
    AppCalloutTone.neutral => Icons.notes_rounded,
    AppCalloutTone.info => Icons.info_outline_rounded,
    AppCalloutTone.success => Icons.check_circle_outline_rounded,
    AppCalloutTone.warning => Icons.warning_amber_rounded,
    AppCalloutTone.error => Icons.error_outline_rounded,
    AppCalloutTone.recommendation => Icons.auto_awesome_rounded,
  };

  _CalloutScheme _scheme(AppSemanticColors colors) => switch (tone) {
    AppCalloutTone.neutral => _CalloutScheme(
      background: colors.surfaceSubtle,
      foreground: colors.textSecondary,
    ),
    AppCalloutTone.info => _CalloutScheme(
      background: colors.infoContainer,
      foreground: colors.onInfoContainer,
    ),
    AppCalloutTone.success => _CalloutScheme(
      background: colors.successContainer,
      foreground: colors.onSuccessContainer,
    ),
    AppCalloutTone.warning => _CalloutScheme(
      background: colors.warningContainer,
      foreground: colors.onWarningContainer,
    ),
    AppCalloutTone.error => _CalloutScheme(
      background: colors.errorContainer,
      foreground: colors.onErrorContainer,
    ),
    AppCalloutTone.recommendation => _CalloutScheme(
      background: colors.recommendationContainer,
      foreground: colors.onRecommendationContainer,
    ),
  };
}

class _CalloutScheme {
  const _CalloutScheme({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
