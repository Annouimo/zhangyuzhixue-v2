import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';

/// 统一 Toast（包装 SnackBar，风格对齐 HTML 原型顶部 Toast）
///
/// 用法：AppToast.show(context, icon: Icons.local_fire_department, message: '签到成功');
class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
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
              Icon(icon, size: 18, color: Colors.white),
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
      {IconData icon = Icons.check_circle}) {
    show(context, icon: icon, message: message,
        backgroundColor: AppColors.success);
  }

  static void error(BuildContext context, String message,
      {IconData icon = Icons.error}) {
    show(context, icon: icon, message: message,
        backgroundColor: AppColors.error);
  }

  static void info(BuildContext context, String message,
      {IconData icon = Icons.info_outline}) {
    show(context, icon: icon, message: message);
  }
}
