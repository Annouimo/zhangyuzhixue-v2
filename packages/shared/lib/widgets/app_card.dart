import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// 章鱼智学统一卡片组件
///
/// 支持边框、选中态和可选悬浮层级。
/// 默认无 elevation，通过选中 / 悬浮效果表达层级。
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.selected = false,
    this.elevated = false,
    this.borderColor,
    this.semanticLabel,
  });

  /// 卡片内容
  final Widget child;

  /// 点击回调（提供时表示可点击）
  final VoidCallback? onTap;

  /// 内边距
  final EdgeInsetsGeometry padding;

  /// 外边距
  final EdgeInsetsGeometry? margin;

  /// 选中态
  final bool selected;

  /// 是否显示悬浮阴影层级
  final bool elevated;

  /// 边框颜色覆盖
  final Color? borderColor;

  /// 无障碍语义标签
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isClickable = onTap != null;
    final radius = BorderRadius.circular(AppRadius.lg);
    final shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: BorderSide(
        color: selected ? colors.primary : (borderColor ?? colors.border),
        width: selected ? 1.5 : 1,
      ),
    );

    Widget content = Material(
      color: colors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: isClickable
          ? InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(padding: padding, child: child),
            )
          : Padding(padding: padding, child: child),
    );

    if (elevated) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppShadows.level1,
        ),
        child: content,
      );
    }

    final card = Container(margin: margin, child: content);

    if (!isClickable) {
      if (semanticLabel != null) {
        return Semantics(
          label: semanticLabel,
          excludeSemantics: true,
          child: card,
        );
      }
      return card;
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      focusable: true,
      onTap: onTap,
      excludeSemantics: semanticLabel != null,
      child: card,
    );
  }
}
