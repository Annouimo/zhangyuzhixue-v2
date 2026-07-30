import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'app_dialog.dart';

class AppActionSheetItem<T> {
  const AppActionSheetItem({
    required this.value,
    required this.label,
    required this.icon,
    this.detail,
    this.destructive = false,
  });

  final T value;
  final String label;
  final IconData icon;
  final String? detail;
  final bool destructive;
}

abstract final class AppActionSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required List<AppActionSheetItem<T>> items,
  }) {
    final content = _ActionSheetContent<T>(title: title, items: items);
    if (MediaQuery.sizeOf(context).width < AppBreakpoints.medium) {
      return showModalBottomSheet<T>(
        context: context,
        useSafeArea: true,
        builder: (_) => content,
      );
    }
    return showDialog<T>(
      context: context,
      builder: (_) =>
          AppDialogFrame(size: AppDialogSize.compact, child: content),
    );
  }
}

class _ActionSheetContent<T> extends StatelessWidget {
  const _ActionSheetContent({required this.title, required this.items});

  final String? title;
  final List<AppActionSheetItem<T>> items;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          for (final item in items)
            ListTile(
              leading: Icon(
                item.icon,
                color: item.destructive ? context.colors.error : null,
              ),
              title: Text(
                item.label,
                style: item.destructive
                    ? TextStyle(color: context.colors.error)
                    : null,
              ),
              subtitle: item.detail == null ? null : Text(item.detail!),
              onTap: () => Navigator.of(context).pop(item.value),
            ),
        ],
      ),
    ),
  );
}
