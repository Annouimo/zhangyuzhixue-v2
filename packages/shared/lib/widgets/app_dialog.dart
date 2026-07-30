import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Standard sizes used by application dialogs.
enum AppDialogSize { compact, regular, wide }

class AppDialogOption<T> {
  const AppDialogOption({
    required this.value,
    required this.label,
    this.detail,
  });

  final T value;
  final String label;
  final String? detail;
}

/// Shared dialog entry points and layout conventions.
abstract final class AppDialog {
  static const EdgeInsets insetPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.lg,
  );

  static double maxWidth(AppDialogSize size) => switch (size) {
    AppDialogSize.compact => 400,
    AppDialogSize.regular => 520,
    AppDialogSize.wide => 720,
  };

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String cancelLabel = '取消',
    String confirmLabel = '确定',
    IconData? icon,
    bool destructive = false,
    bool barrierDismissible = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AlertDialog(
        icon: icon == null
            ? null
            : Icon(
                icon,
                color: destructive
                    ? dialogContext.colors.error
                    : dialogContext.colors.primary,
              ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: dialogContext.colors.error,
                    foregroundColor: dialogContext.colors.onError,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<String?> prompt(
    BuildContext context, {
    required String title,
    String? message,
    String? initialValue,
    String label = '名称',
    String cancelLabel = '取消',
    String confirmLabel = '确定',
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String value)? validator,
  }) async {
    var value = initialValue ?? '';
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          void submit() {
            final submittedValue = value.trim();
            final error = validator?.call(submittedValue);
            if (error != null) {
              setState(() => errorText = error);
              return;
            }
            Navigator.of(dialogContext).pop(submittedValue);
          }

          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: maxWidth(AppDialogSize.compact),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message != null) ...[
                    Text(message),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  TextFormField(
                    initialValue: initialValue,
                    autofocus: true,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    decoration: InputDecoration(
                      labelText: label,
                      errorText: errorText,
                    ),
                    onChanged: (nextValue) {
                      value = nextValue;
                      if (errorText != null) setState(() => errorText = null);
                    },
                    onFieldSubmitted: (_) => submit(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(cancelLabel),
              ),
              FilledButton(onPressed: submit, child: Text(confirmLabel)),
            ],
          );
        },
      ),
    );
    return result;
  }

  static Future<T?> select<T>(
    BuildContext context, {
    required String title,
    required List<AppDialogOption<T>> options,
  }) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        contentPadding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        content: SizedBox(
          width: maxWidth(AppDialogSize.compact),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              return ListTile(
                title: Text(option.label),
                subtitle: option.detail == null ? null : Text(option.detail!),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(dialogContext).pop(option.value),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}

/// Constrains complex custom dialogs to the same responsive geometry.
class AppDialogFrame extends StatelessWidget {
  const AppDialogFrame({
    required this.child,
    super.key,
    this.size = AppDialogSize.regular,
  });

  final Widget child;
  final AppDialogSize size;

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: AppDialog.insetPadding,
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: AppDialog.maxWidth(size)),
      child: child,
    ),
  );
}
