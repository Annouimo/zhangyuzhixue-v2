import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_button.dart';
import 'package:shared/widgets/app_status_badge.dart';

import '../domain/achievement_repository.dart';

Future<void> showAchievementUnlockDialog(
  BuildContext context, {
  required AchievementItem achievement,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        icon: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.successContainer,
            borderRadius: BorderRadius.circular(AppRadius.extraLarge),
            border: Border.all(color: context.colors.success),
          ),
          child: Text(achievement.iconEmoji, style: const TextStyle(fontSize: 38)),
        ),
        title: Text(achievement.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppStatusBadge(
              label: '新成就解锁',
              tone: AppStatusTone.success,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
            ),
            if (achievement.unlockedAt != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${achievement.unlockedAt} 解锁',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
        actions: [
          AppButton(
            label: '继续加油',
            icon: Icons.celebration_rounded,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    ),
  );
}
