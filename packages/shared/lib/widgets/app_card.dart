import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// 章鱼智学统一卡片组件
///
/// 支持边框、选中态和可选悬浮层级。
/// 默认无 elevation，通过选中 / 悬浮效果表达层级。
class AppCard extends StatefulWidget {
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
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isClickable = widget.onTap != null;
    final radius = BorderRadius.circular(AppRadius.lg);
    final shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: BorderSide(
        color: widget.selected
            ? colors.primary
            : (widget.borderColor ?? colors.border),
        width: widget.selected ? 1.5 : 1,
      ),
    );

    Widget content = Material(
      color: colors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: isClickable
          ? InkWell(
              onTap: widget.onTap,
              onHighlightChanged: _setPressed,
              onHover: _setHovered,
              borderRadius: radius,
              child: Padding(padding: widget.padding, child: widget.child),
            )
          : Padding(padding: widget.padding, child: widget.child),
    );

    content = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _hovered
            ? AppShadows.level2
            : widget.elevated
            ? AppShadows.level1
            : const [],
      ),
      child: content,
    );

    final card = AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: _pressed ? AppMotion.instant : AppMotion.fast,
      curve: AppMotion.easeOut,
      child: Container(margin: widget.margin, child: content),
    );

    if (!isClickable) {
      if (widget.semanticLabel != null) {
        return Semantics(
          label: widget.semanticLabel,
          excludeSemantics: true,
          child: card,
        );
      }
      return card;
    }

    return Semantics(
      label: widget.semanticLabel,
      button: true,
      focusable: true,
      onTap: widget.onTap,
      excludeSemantics: widget.semanticLabel != null,
      child: card,
    );
  }
}
