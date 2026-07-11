import 'package:flutter/material.dart';
import '../../app_theme.dart';

/// 统一 Toast（包装 SnackBar，风格对齐 HTML 原型顶部 Toast）
///
/// 用法：AppToast.show(context, icon: '🔥', message: '签到成功');
/// 替代各地零散的 ScaffoldMessenger.showSnackBar(...)
class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    String? icon,
    Color? backgroundColor,
    int durationMs = 3000,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: backgroundColor ?? AppColors.textPrimary,
        duration: Duration(milliseconds: durationMs),
      ),
    );
  }

  static void success(BuildContext context, String message,
      {String icon = '✅'}) {
    show(context, icon: icon, message: message,
        backgroundColor: AppColors.success);
  }

  static void error(BuildContext context, String message,
      {String icon = '❌'}) {
    show(context, icon: icon, message: message,
        backgroundColor: AppColors.error);
  }

  static void info(BuildContext context, String message,
      {String icon = 'ℹ️'}) {
    show(context, icon: icon, message: message);
  }
}
