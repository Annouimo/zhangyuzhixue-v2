import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_icons.dart';
import 'app_button.dart';

/// 页面加载、空内容、错误与完成状态的统一展示。
enum AppStateTone { loading, empty, error, success, info }

class AppStatePanel extends StatelessWidget {
  const AppStatePanel({
    super.key,
    required this.title,
    this.message,
    this.tone = AppStateTone.info,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? message;
  final AppStateTone tone;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final scheme = _scheme(colors);
    final resolvedIcon = icon ?? _defaultIcon;

    return Semantics(
      container: true,
      liveRegion: tone == AppStateTone.loading || tone == AppStateTone.error,
      label: [title, if (message != null) message].join('，'),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: compact ? 52 : 64,
                  height: compact ? 52 : 64,
                  decoration: BoxDecoration(
                    color: scheme.background,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    border: Border.all(color: scheme.border),
                  ),
                  alignment: Alignment.center,
                  child: tone == AppStateTone.loading
                      ? SizedBox(
                          width: compact ? 24 : 28,
                          height: compact ? 24 : 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: scheme.foreground,
                          ),
                        )
                      : Icon(
                          resolvedIcon,
                          size: compact ? 26 : 30,
                          color: scheme.foreground,
                        ),
                ),
                SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                Text(
                  title,
                  style: compact ? textTheme.titleMedium : textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (message != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: actionLabel!,
                    icon: tone == AppStateTone.error
                        ? AppIcons.refresh
                        : AppIcons.arrowForward,
                    onPressed: onAction,
                    variant: tone == AppStateTone.error
                        ? AppButtonVariant.secondary
                        : AppButtonVariant.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _defaultIcon => switch (tone) {
        AppStateTone.loading => AppIcons.refresh,
        AppStateTone.empty => Icons.inbox_outlined,
        AppStateTone.error => AppIcons.error,
        AppStateTone.success => AppIcons.success,
        AppStateTone.info => AppIcons.info,
      };

  _StateScheme _scheme(AppSemanticColors colors) => switch (tone) {
        AppStateTone.loading => _StateScheme(
            background: colors.primaryContainer,
            foreground: colors.primary,
            border: colors.primaryBorder,
          ),
        AppStateTone.empty => _StateScheme(
            background: colors.surfaceSubtle,
            foreground: colors.textSecondary,
            border: colors.border,
          ),
        AppStateTone.error => _StateScheme(
            background: colors.errorContainer,
            foreground: colors.onErrorContainer,
            border: colors.error,
          ),
        AppStateTone.success => _StateScheme(
            background: colors.successContainer,
            foreground: colors.onSuccessContainer,
            border: colors.success,
          ),
        AppStateTone.info => _StateScheme(
            background: colors.infoContainer,
            foreground: colors.onInfoContainer,
            border: colors.primaryBorder,
          ),
      };
}

class _StateScheme {
  const _StateScheme({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}