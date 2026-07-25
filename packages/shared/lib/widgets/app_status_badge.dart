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
    this.tone,
    this.icon,
    this.size = AppBadgeSize.sm,
    this.compact,
  }) : _useCompact = compact ?? (size == AppBadgeSize.sm);

  /// 状态文字
  final String label;

  /// 状态类型（决定颜色）
  final AppStatusType type;

  /// 状态色调别名（与原 Phase 1 兼容，覆盖 type）
  final AppStatusTone? tone;

  /// 可选前置图标（不设置时使用类型默认图标）
  final IconData? icon;

  /// 尺寸
  final AppBadgeSize size;

  /// 紧凑模式（true 时使用 sm 尺寸样式）
  final bool? compact;

  /// 内部计算的紧凑标记
  final bool _useCompact;

  AppStatusType get _effectiveType => tone != null ? AppStatusType.fromTone(tone!) : type;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectiveType = _effectiveType;

    final (Color bg, Color fg, IconData defaultIcon) = switch (effectiveType) {
      AppStatusType.success => (colors.successContainer, colors.onSuccessContainer, Icons.check_circle),
      AppStatusType.warning => (colors.warningContainer, colors.onWarningContainer, Icons.warning_amber),
      AppStatusType.error => (colors.errorContainer, colors.onErrorContainer, Icons.cancel),
      AppStatusType.info => (colors.infoContainer, colors.onInfoContainer, Icons.info),
      AppStatusType.recommendation => (colors.recommendationContainer, colors.onRecommendationContainer, Icons.auto_awesome),
      AppStatusType.neutral => (colors.surfaceSubtle, colors.textSecondary, Icons.circle_outlined),
      AppStatusType.primary => (colors.primaryContainer, colors.onPrimaryContainer, Icons.bolt_rounded),
    };

    final effectiveIcon = icon ?? defaultIcon;
    final fontScale = _useCompact ? 11.0 : 13.0;
    final iconScale = _useCompact ? 14.0 : 16.0;
    final vPadding = _useCompact ? 2.0 : 4.0;
    final hPadding = _useCompact ? 6.0 : 8.0;

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

  /// 主色/强调
  primary;

  static AppStatusType fromTone(AppStatusTone tone) => switch (tone) {
        AppStatusTone.success => success,
        AppStatusTone.warning => warning,
        AppStatusTone.error => error,
        AppStatusTone.info => info,
        AppStatusTone.recommendation => recommendation,
        AppStatusTone.neutral => neutral,
        AppStatusTone.primary => primary,
      };
}

/// 状态色调（原 Phase 1 兼容性别名）
enum AppStatusTone {
  success,
  warning,
  error,
  info,
  recommendation,
  neutral,
  primary,
}

/// 徽标尺寸
enum AppBadgeSize {
  sm,
  md,
}
