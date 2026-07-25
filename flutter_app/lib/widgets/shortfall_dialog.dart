import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_button.dart';
import 'package:shared/widgets/app_status_badge.dart';
import 'package:shared/widgets/app_toast.dart';

Future<void> showShortfallDialog(
  BuildContext context, {
  required String type,
  required int needed,
  required int available,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _ShortfallDialog(
      type: type,
      needed: needed,
      available: available,
    ),
  );
  if (result == true && context.mounted) {
    AppToast.show(
      context,
      icon: Icons.description_outlined,
      message: '将按当前可用题目继续组卷',
    );
  }
}

class _ShortfallDialog extends StatelessWidget {
  const _ShortfallDialog({
    required this.type,
    required this.needed,
    required this.available,
  });

  final String type;
  final int needed;
  final int available;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: context.colors.warningContainer,
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            size: 32,
            color: context.colors.onWarningContainer,
          ),
        ),
        title: const Text('题目数量不足'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppStatusBadge(
              label: '需要调整',
              tone: AppStatusTone.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '$type 需要 $needed 道题，当前筛选条件下只有 $available 道。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
            ),
          ],
        ),
        actions: [
          AppButton(
            label: '调整筛选条件',
            onPressed: () => Navigator.of(context).pop(false),
            variant: AppButtonVariant.secondary,
          ),
          AppButton(
            label: '按现有题目组卷',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}
