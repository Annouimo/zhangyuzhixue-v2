import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class BasketSelectionItem {
  const BasketSelectionItem({
    required this.id,
    required this.name,
    required this.subtitle,
  });

  final int id;
  final String name;
  final String subtitle;
}

class BasketSelectionFooter {
  const BasketSelectionFooter({
    required this.summary,
    required this.confirmLabel,
    required this.confirmIcon,
    this.destructive = false,
  });

  final String summary;
  final String confirmLabel;
  final IconData confirmIcon;
  final bool destructive;
}

typedef BasketFooterBuilder = BasketSelectionFooter Function(Set<int> ids);
typedef BasketCreator = Future<BasketSelectionItem?> Function();

Future<Set<int>?> showBasketSelectionPanel({
  required BuildContext context,
  required String title,
  required String subtitle,
  required List<BasketSelectionItem> items,
  required Set<int> initialSelectedIds,
  required bool multiple,
  bool allowEmpty = false,
  required BasketFooterBuilder footerBuilder,
  BasketCreator? onCreate,
}) {
  final panel = BasketSelectionPanel(
    title: title,
    subtitle: subtitle,
    items: items,
    initialSelectedIds: initialSelectedIds,
    multiple: multiple,
    allowEmpty: allowEmpty,
    footerBuilder: footerBuilder,
    onCreate: onCreate,
  );
  if (MediaQuery.sizeOf(context).width < 600) {
    return showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(heightFactor: 0.9, child: panel),
    );
  }
  return showDialog<Set<int>>(
    context: context,
    builder: (_) => AppDialogFrame(child: SizedBox(height: 640, child: panel)),
  );
}

class BasketSelectionPanel extends StatefulWidget {
  const BasketSelectionPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.initialSelectedIds,
    required this.multiple,
    required this.allowEmpty,
    required this.footerBuilder,
    this.onCreate,
  });

  final String title;
  final String subtitle;
  final List<BasketSelectionItem> items;
  final Set<int> initialSelectedIds;
  final bool multiple;
  final bool allowEmpty;
  final BasketFooterBuilder footerBuilder;
  final BasketCreator? onCreate;

  @override
  State<BasketSelectionPanel> createState() => _BasketSelectionPanelState();
}

class _BasketSelectionPanelState extends State<BasketSelectionPanel> {
  late final List<BasketSelectionItem> _items = List.of(widget.items);
  late final Set<int> _selectedIds = Set.of(widget.initialSelectedIds);

  Future<void> _create() async {
    final item = await widget.onCreate?.call();
    if (item == null || !mounted) return;
    setState(() {
      _items.removeWhere((existing) => existing.id == item.id);
      _items.insert(0, item);
      if (!widget.multiple) _selectedIds.clear();
      _selectedIds.add(item.id);
    });
  }

  void _toggle(BasketSelectionItem item, bool selected) {
    setState(() {
      if (!widget.multiple) _selectedIds.clear();
      selected ? _selectedIds.add(item.id) : _selectedIds.remove(item.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final footer = widget.footerBuilder(Set.unmodifiable(_selectedIds));
    return Material(
      color: context.colors.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          if (widget.onCreate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(color: context.colors.border),
                ),
                leading: Icon(Icons.add_rounded, color: context.colors.primary),
                title: const Text('新建试题篮'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _create,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final selected = _selectedIds.contains(item.id);
                return CheckboxListTile(
                  value: selected,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(item.name),
                  subtitle: Text(item.subtitle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  onChanged: (value) => _toggle(item, value == true),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.colors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      footer.summary,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: footer.destructive
                            ? context.colors.error
                            : context.colors.textSecondary,
                        fontWeight: footer.destructive
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  AppButton(
                    label: footer.confirmLabel,
                    icon: footer.confirmIcon,
                    onPressed: _selectedIds.isEmpty && !widget.allowEmpty
                        ? null
                        : () => Navigator.pop(context, Set.of(_selectedIds)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> showCreateBasketDialog(BuildContext context) {
  return AppDialog.prompt(
    context,
    title: '新建试题篮',
    initialValue: '新试题篮',
    confirmLabel: '创建',
    validator: (value) => value.isEmpty ? '请输入名称' : null,
  );
}
