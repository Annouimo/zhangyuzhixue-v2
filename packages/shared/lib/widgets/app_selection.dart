import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// 通用列表选择状态。
///
/// 列表内容发生变化时，调用 [retain] 清理已经不在当前列表中的选中项。
class AppSelectionController<T> extends ChangeNotifier {
  final Set<T> _selectedIds = <T>{};

  Set<T> get selectedIds => Set<T>.unmodifiable(_selectedIds);
  int get selectedCount => _selectedIds.length;
  bool get isEmpty => _selectedIds.isEmpty;

  bool isSelected(T id) => _selectedIds.contains(id);

  void toggle(T id) {
    _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id);
    notifyListeners();
  }

  void selectAll(Iterable<T> ids) {
    final previousCount = _selectedIds.length;
    _selectedIds.addAll(ids);
    if (_selectedIds.length != previousCount) notifyListeners();
  }

  void clear() {
    if (_selectedIds.isEmpty) return;
    _selectedIds.clear();
    notifyListeners();
  }

  void replace(Iterable<T> ids) {
    final next = ids.toSet();
    if (_selectedIds.length == next.length && _selectedIds.containsAll(next)) {
      return;
    }
    _selectedIds
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  void retain(Iterable<T> ids) {
    final allowed = ids.toSet();
    if (_selectedIds.every(allowed.contains)) return;
    _selectedIds.removeWhere((id) => !allowed.contains(id));
    notifyListeners();
  }
}

/// 列表项统一选择按钮。
class AppSelectionToggle extends StatelessWidget {
  const AppSelectionToggle({
    super.key,
    required this.selected,
    required this.onPressed,
    this.selectTooltip = '选择',
    this.deselectTooltip = '取消选择',
  });

  final bool selected;
  final VoidCallback? onPressed;
  final String selectTooltip;
  final String deselectTooltip;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: selected ? deselectTooltip : selectTooltip,
    visualDensity: VisualDensity.compact,
    onPressed: onPressed,
    icon: Icon(
      selected
          ? Icons.check_circle_rounded
          : Icons.radio_button_unchecked_rounded,
      color: selected ? context.colors.primary : context.colors.textSecondary,
    ),
  );
}

/// 通用选择操作底栏。仅在存在选中项时显示。
class AppSelectionActionBar extends StatelessWidget {
  const AppSelectionActionBar({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onClear,
    required this.actionLabel,
    required this.onAction,
    this.itemUnit = '项',
    this.actionIcon,
    this.actionLoading = false,
  });

  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final String itemUnit;
  final String actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool actionLoading;

  bool get _allSelected => totalCount > 0 && selectedCount == totalCount;

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();
    final partiallySelected = selectedCount > 0 && !_allSelected;
    final canSelect = totalCount > 0;
    return SafeArea(
      top: false,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.colors.divider)),
        ),
        child: Row(
          children: [
            Semantics(
              checked: _allSelected,
              mixed: partiallySelected,
              button: true,
              label: '全选',
              child: InkWell(
                onTap: !canSelect
                    ? null
                    : _allSelected
                    ? onClear
                    : onSelectAll,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: partiallySelected ? null : _allSelected,
                        tristate: true,
                        onChanged: !canSelect
                            ? null
                            : (_) => _allSelected ? onClear() : onSelectAll(),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        '全选',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '已选 '),
                    TextSpan(
                      text: '$selectedCount',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: ' / $totalCount'),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                maximumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onPressed: selectedCount == 0 || actionLoading ? null : onAction,
              icon: actionLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(actionIcon ?? Icons.check_rounded, size: 18),
              label: Text(actionLabel, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
