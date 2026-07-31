import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'app_button.dart';

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
      selected ? Icons.check_circle : Icons.add_circle_outline,
      color: selected ? context.colors.primary : context.colors.textSecondary,
    ),
  );
}

/// 通用选择操作底栏。未选中任何项目时不占用布局空间。
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
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.colors.surfaceSubtle,
          border: Border(top: BorderSide(color: context.colors.border)),
        ),
        child: Row(
          children: [
            AppButton(
              onPressed: _allSelected ? onClear : onSelectAll,
              label: _allSelected ? '取消全选' : '全选 $totalCount$itemUnit',
              type: AppButtonType.text,
              size: AppButtonSize.md,
              expanded: false,
            ),
            Expanded(
              child: Text(
                '已选 $selectedCount$itemUnit',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            AppButton(
              onPressed: onAction,
              icon: actionIcon,
              label: actionLabel,
              size: AppButtonSize.md,
              expanded: false,
              loading: actionLoading,
            ),
          ],
        ),
      ),
    );
  }
}
