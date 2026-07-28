import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'app_card.dart';
import 'app_status_badge.dart';

/// 用于进入功能或详情页的统一卡片。
class AppNavigationCard extends StatelessWidget {
  const AppNavigationCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.tone = AppStatusTone.primary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final AppStatusTone tone;

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

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 88),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Icon(icon, color: foreground, size: 21),
          ),
          title: Text(title, style: Theme.of(context).textTheme.titleSmall),
          subtitle: Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          trailing:
              trailing ??
              (onTap == null
                  ? null
                  : Icon(AppIcons.chevronRight, color: colors.textMuted)),
        ),
      ),
    );
  }
}

/// 为同级导航卡片提供一致的列数、宽度和间距。
class AppResponsiveCardGrid extends StatelessWidget {
  const AppResponsiveCardGrid({
    super.key,
    required this.children,
    this.minItemWidth = 300,
    this.maxColumns = 2,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final possibleColumns =
            ((constraints.maxWidth + gap) / (minItemWidth + gap)).floor();
        final columns = possibleColumns.clamp(1, maxColumns);
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}
