import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// 章鱼智学统一状态徽标
///
/// 用文字 + 图标 + 颜色的联合表达替代单纯颜色标记。
/// 用于题目状态、作业状态、签到状态等场景。
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.type = AppStatusType.neutral,
    this.icon,
    this.size = AppBadgeSize.sm,
  });

  /// 状态文字
  final String label;

  /// 状态类型（决定颜色）
  final AppStatusType type;

  /// 可选前置图标（不设置时使用类型默认图标）
  final IconData? icon;

  /// 尺寸
  final AppBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final (Color bg, Color fg, IconData defaultIcon) = switch (type) {
      AppStatusType.success => (colors.successContainer, colors.onSuccessContainer, Icons.check_circle),
      AppStatusType.warning => (colors.warningContainer, colors.onWarningContainer, Icons.warning_amber),
      AppStatusType.error => (colors.errorContainer, colors.onErrorContainer, Icons.cancel),
      AppStatusType.info => (colors.infoContainer, colors.onInfoContainer, Icons.info),
      AppStatusType.recommendation => (colors.recommendationContainer, colors.onRecommendationContainer, Icons.auto_awesome),
      AppStatusType.neutral => (colors.surfaceSubtle, colors.textSecondary, Icons.circle_outlined),
    };

    final effectiveIcon = icon ?? defaultIcon;
    final fontScale = size == AppBadgeSize.sm ? 11.0 : 13.0;
    final iconScale = size == AppBadgeSize.sm ? 14.0 : 16.0;
    final vPadding = size == AppBadgeSize.sm ? 2.0 : 4.0;
    final hPadding = size == AppBadgeSize.sm ? 6.0 : 8.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: hPadding,
        vertical: vPadding,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(effectiveIcon, size: iconScale, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: fontScale,
              fontWeight: FontWeight.w500,
              color: fg,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 状态徽标类型
enum AppStatusType {
  /// 成功/已完成
  success,

  /// 警告/待处理
  warning,

  /// 错误/失败
  error,

  /// 信息提示
  info,

  /// 推荐标记
  recommendation,

  /// 中性/默认
  neutral,
}

/// 徽标尺寸
enum AppBadgeSize {
  sm,
  md,
}
