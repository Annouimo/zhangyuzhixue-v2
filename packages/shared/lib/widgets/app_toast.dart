import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';

/// 统一 Toast（包装 SnackBar，风格对齐 HTML 原型顶部 Toast）
///
/// 用法：AppToast.show(context, icon: Icons.local_fire_department, message: '签到成功');
/// 替代各地零散的 ScaffoldMessenger.showSnackBar(...)
class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    int durationMs = 3000,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = context.colors;
    final effectiveBackground = backgroundColor ?? colors.textPrimary;
    final effectiveForeground = foregroundColor ?? colors.textInverse;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: effectiveForeground),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: effectiveForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: effectiveBackground,
        duration: Duration(milliseconds: durationMs),
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: effectiveForeground,
                disabledTextColor: effectiveForeground.withValues(alpha: 0.6),
                onPressed: onAction,
              ),
      ),
    );
  }

  static void success(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_rounded,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      icon: icon,
      message: message,
      backgroundColor: context.colors.successContainer,
      foregroundColor: context.colors.onSuccessContainer,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    IconData icon = Icons.error_rounded,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      icon: icon,
      message: message,
      backgroundColor: context.colors.errorContainer,
      foregroundColor: context.colors.onErrorContainer,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    IconData icon = Icons.warning_amber_rounded,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      icon: icon,
      message: message,
      backgroundColor: context.colors.warningContainer,
      foregroundColor: context.colors.onWarningContainer,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_outline_rounded,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      icon: icon,
      message: message,
      backgroundColor: context.colors.infoContainer,
      foregroundColor: context.colors.onInfoContainer,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
