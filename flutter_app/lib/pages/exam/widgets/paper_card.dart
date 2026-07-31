import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// 组卷卡片（我的组卷 / 发现 / 收藏共用）。
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
    this.trailingWidget,
    this.selected = false,
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback onTap;
  final Widget? trailingWidget;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: EdgeInsets.zero,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
          bottom: Radius.circular(AppRadius.large),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 22,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailingWidget != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailingWidget!,
              ] else if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  trailing!,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
              const SizedBox(width: AppSpacing.xxs),
              Icon(AppIcons.chevronRight, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
