import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'app_status_badge.dart';

/// A lightweight, single-column group of navigation entrances.
class AppNavigationList extends StatelessWidget {
  const AppNavigationList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final divider = context.colors.divider;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md + AppControlSize.md + AppSpacing.md,
                right: AppSpacing.md,
              ),
              child: Divider(height: 1, thickness: 1, color: divider),
            ),
        ],
      ],
    );
  }
}

/// A full-row navigation entrance without a card container.
class AppNavigationListItem extends StatelessWidget {
  const AppNavigationListItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.tone = AppStatusTone.primary,
    this.semanticLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final AppStatusTone tone;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (foreground, background) = switch (tone) {
      AppStatusTone.success => (colors.success, colors.successContainer),
      AppStatusTone.warning => (colors.warning, colors.warningContainer),
      AppStatusTone.error => (colors.error, colors.errorContainer),
      AppStatusTone.info => (colors.info, colors.infoContainer),
      AppStatusTone.recommendation => (
        colors.recommendation,
        colors.recommendationContainer,
      ),
      AppStatusTone.neutral => (colors.textSecondary, colors.surfaceSubtle),
      AppStatusTone.primary => (colors.primary, colors.primaryContainer),
    };

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 88),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: AppControlSize.md,
              height: AppControlSize.md,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(icon, color: foreground, size: 21),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ] else if (onTap != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(AppIcons.chevronRight, size: 18, color: colors.textMuted),
            ],
          ],
        ),
      ),
    );

    final item = Material(
      color: Colors.transparent,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              mouseCursor: SystemMouseCursors.click,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return colors.primary.withValues(alpha: 0.10);
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)) {
                  return colors.primary.withValues(alpha: 0.06);
                }
                return null;
              }),
              child: content,
            ),
    );

    if (onTap == null) return item;
    return Semantics(
      label: semanticLabel,
      button: true,
      focusable: true,
      onTap: onTap,
      excludeSemantics: semanticLabel != null,
      child: item,
    );
  }
}
