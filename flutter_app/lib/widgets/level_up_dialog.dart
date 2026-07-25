import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_button.dart';
import 'package:shared/widgets/app_status_badge.dart';

Future<void> showLevelUpDialog(
  BuildContext context, {
  required int oldLevel,
  required int newLevel,
  required int percentile,
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
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: BrandColors.gradient),
            borderRadius: BorderRadius.circular(AppRadius.extraLarge),
          ),
          child: const Icon(
            Icons.military_tech_rounded,
            size: 38,
            color: Colors.white,
          ),
        ),
        title: const Text('等级提升'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppStatusBadge(
              label: '成长里程碑',
              tone: AppStatusTone.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text.rich(
              TextSpan(
                text: 'Lv.$oldLevel  →  ',
                children: [
                  TextSpan(
                    text: 'Lv.$newLevel',
                    style: TextStyle(color: context.colors.primary),
                  ),
                ],
              ),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '你的学习积分已超过 $percentile% 的用户。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          AppButton(
            label: '继续学习',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    ),
  );
}
