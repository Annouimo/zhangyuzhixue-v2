import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class PaperAction {
  final String label;
  final String? compactLabel;
  final IconData icon;
  final VoidCallback onPressed;
  final AppButtonVariant variant;

  const PaperAction({
    required this.label,
    this.compactLabel,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSecondary = constraints.maxWidth >= 360;
        final visibleCount = showSecondary
            ? (actions.length > 2 ? 2 : actions.length)
            : (actions.isEmpty ? 0 : 1);
        final overflowActions = actions
            .skip(visibleCount)
            .toList(growable: false);
        final hasMenu = overflowActions.isNotEmpty || menuActions.isNotEmpty;

        void handleSelection(String value) {
          if (value.startsWith('_action:')) {
            final index = int.parse(value.substring('_action:'.length));
            overflowActions[index].onPressed();
            return;
          }
          onMenuSelected?.call(value);
        }

        final entries = <PopupMenuEntry<String>>[];
        for (var index = 0; index < overflowActions.length; index++) {
          final action = overflowActions[index];
          entries.add(
            _menuItem(
              context,
              '_action:$index',
              action.label,
              action.icon,
              false,
            ),
          );
        }
        var dividerAdded = false;
        for (final action in menuActions) {
          if (action.destructive && !dividerAdded && entries.isNotEmpty) {
            entries.add(const PopupMenuDivider());
            dividerAdded = true;
          }
          entries.add(
            _menuItem(
              context,
              action.value,
              action.label,
              action.icon,
              action.destructive,
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ...actions
                .take(visibleCount)
                .map(
                  (action) => AppButton(
            label: constraints.maxWidth < 240
                        ? action.compactLabel ?? action.label
                        : action.label,
                    icon: action.icon,
                    variant: action.variant,
                    expanded: false,
                    size: AppButtonSize.md,
                    onPressed: action.onPressed,
                  ),
                )
                .expand(
                  (button) => [button, const SizedBox(width: AppSpacing.sm)],
                ),
            if (hasMenu)
              PopupMenuButton<String>(
                tooltip: '更多试卷操作',
                onSelected: handleSelection,
                icon: const Icon(Icons.more_horiz),
                itemBuilder: (context) => entries,
              ),
          ],
        );
      },
    );
  }

  PopupMenuItem<String> _menuItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    bool destructive,
  ) => PopupMenuItem<String>(
    value: value,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: destructive ? context.colors.error : null),
      title: Text(
        label,
        style: destructive ? TextStyle(color: context.colors.error) : null,
      ),
    ),
  );
}
