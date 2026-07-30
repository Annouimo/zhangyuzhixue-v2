import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class PaperAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final AppButtonVariant variant;

  const PaperAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.variant = AppButtonVariant.secondary,
  });
}

class PaperMenuAction {
  final String value;
  final String label;
  final IconData icon;
  final bool destructive;

  const PaperMenuAction({
    required this.value,
    required this.label,
    required this.icon,
    this.destructive = false,
  });
}

class PaperActionBar extends StatelessWidget {
  final List<PaperAction> actions;
  final List<PaperMenuAction> menuActions;
  final ValueChanged<String>? onMenuSelected;

  const PaperActionBar({
    super.key,
    required this.actions,
    this.menuActions = const [],
    this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...actions.map(
          (action) => AppButton(
            label: action.label,
            icon: action.icon,
            variant: action.variant,
            expanded: false,
            size: AppButtonSize.md,
            onPressed: action.onPressed,
          ),
        ),
        if (menuActions.isNotEmpty)
          PopupMenuButton<String>(
            tooltip: '更多试卷操作',
            onSelected: onMenuSelected,
            icon: const Icon(Icons.more_horiz),
            itemBuilder: (context) => menuActions
                .map(
                  (action) => PopupMenuItem<String>(
                    value: action.value,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        action.icon,
                        color: action.destructive ? context.colors.error : null,
                      ),
                      title: Text(
                        action.label,
                        style: action.destructive
                            ? TextStyle(color: context.colors.error)
                            : null,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}
