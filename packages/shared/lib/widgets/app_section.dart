import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// 页面中的透明内容章节。
///
/// 用标题、留白和可选分隔线建立层级，不制造额外 surface、边框或阴影。
/// 独立、可点击或可选择的实体仍应使用 [AppCard] 等实体组件。
class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    required this.child,
    this.title,
    this.description,
    this.leading,
    this.trailing,
    this.padding = EdgeInsets.zero,
    this.showDivider = false,
  });

  final String? title;
  final String? description;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final bool showDivider;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;
    final hasHeader =
        title != null ||
        description != null ||
        leading != null ||
        trailing != null;

    return Semantics(
      container: true,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDivider) ...[
              const Divider(),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (hasHeader) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxs),
                      child: leading!,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Semantics(
                            headingLevel: 2,
                            child: Text(title!, style: textTheme.titleLarge),
                          ),
                        if (description != null) ...[
                          if (title != null)
                            const SizedBox(height: AppSpacing.xxs),
                          Text(
                            description!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
