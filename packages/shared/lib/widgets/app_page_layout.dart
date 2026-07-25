import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_icons.dart';

/// 页面容器 — 统一边距与最大内容宽度
///
/// 控制页面内容在宽屏下的最大宽度，自动居中。
/// 使用 [layout] 或 [maxWidth] 指定宽度。
class AppContentContainer extends StatelessWidget {
  const AppContentContainer({
    super.key,
    required this.child,
    this.layout = AppContentLayout.standard,
    this.maxWidth,
    this.useSafeArea = true,
    this.padding,
  });

  /// 页面内容
  final Widget child;

  /// 布局类型（决定最大宽度，与 [maxWidth] 二选一）
  final AppContentLayout layout;

  /// 直接指定最大宽度（覆盖 layout，与 [layout] 二选一）
  final double? maxWidth;

  /// 是否启用 SafeArea（默认 true）
  final bool useSafeArea;

  /// 水平内边距覆盖（默认使用响应式间距）
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final w = maxWidth ?? switch (layout) {
      AppContentLayout.form => AppContentWidth.form,
      AppContentLayout.reading => AppContentWidth.reading,
      AppContentLayout.standard => AppContentWidth.standard,
      AppContentLayout.dashboard => AppContentWidth.dashboard,
      AppContentLayout.solving => AppContentWidth.solving,
    };

    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: w),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
          ),
          child: child,
        ),
      ),
    );

    if (useSafeArea) {
      return SafeArea(child: content);
    }
    return content;
  }
}

/// 内容布局类型
enum AppContentLayout {
  /// 表单类页面（登录、注册、设置）
  form,

  /// 阅读类页面（讲义、解析）
  reading,

  /// 标准内容区（列表、详情）
  standard,

  /// 仪表盘/概览页面（首页、统计）
  dashboard,

  /// 做题区域
  solving,
}

/// 页面分区标题 — 统一"标题 + 查看更多/副操作"模式
///
/// 典型用法：作业、讲义、推荐等列表模块的分区头部。
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
    this.icon,
    this.trailing,
    this.action,
  });

  /// 分区标题
  final String title;

  /// 副标题（显示在标题下方）
  final String? subtitle;

  /// "查看更多"等操作文字
  final String? actionLabel;

  /// 操作点击回调
  final VoidCallback? onActionTap;

  /// 标题前置图标（可选）
  final IconData? icon;

  /// 自定义尾部组件（优先级高于 actionLabel）
  final Widget? trailing;

  /// 自定义操作组件别名（兼容 Phase 1 命名，优先级高于 trailing）
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: colors.textPrimary),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textMuted,
                          ),
                    ),
                  ),
              ],
            ),
          ),
          if (action != null)
            action!
          else if (trailing != null)
            trailing!
          else if (actionLabel != null && onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    AppIcons.chevronRight,
                    size: 16,
                    color: colors.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
