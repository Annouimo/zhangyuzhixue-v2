import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../domain/achievement_repository.dart';

/// 成就解锁弹窗 — 匹配 HTML 原型 achievement-popup
Future<void> showAchievementUnlockDialog(
  BuildContext context, {
  required AchievementItem achievement,
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
              Text(achievement.iconEmoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('🏆 新成就解锁',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                ),
              ),
              const SizedBox(height: 8),
              Text(achievement.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(achievement.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              if (achievement.unlockedAt != null) ...[
                const SizedBox(height: 4),
                Text('${achievement.unlockedAt} 解锁',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
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
                  child: const Text('太棒了', style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
