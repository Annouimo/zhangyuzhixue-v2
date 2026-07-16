import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';

/// 升级弹窗 — 匹配 HTML 原型 levelup-popup
///
/// 用户等级提升时弹出，显示新旧等级和超过百分比。
Future<void> showLevelUpDialog(BuildContext context, {
  required int oldLevel,
  required int newLevel,
  required int percentile,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, size: 48, color: AppColors.primary),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF1FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('🏆 等级提升',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  children: [
                    TextSpan(text: 'Lv.$oldLevel → '),
                    TextSpan(text: 'Lv.$newLevel', style: const TextStyle(color: AppColors.primary)),
                    const TextSpan(text: ' 🎊'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '超过 $percentile% 的用户',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('👏 继续加油', style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
