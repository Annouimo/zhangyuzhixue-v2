import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../domain/paper_folder_repository.dart';
import '../pages/router.dart';
import 'basket_selection_panel.dart';

class QuestionWorkspaceItem {
  const QuestionWorkspaceItem({
    required this.id,
    required this.title,
    required this.questionType,
    this.subtitle,
    this.difficulty,
    this.status,
  });

  final int id;
  final String title;
  final String questionType;
  final String? subtitle;
  final double? difficulty;
  final String? status;
}

class QuestionWorkspaceController extends ChangeNotifier {
  final Set<int> _selectedIds = {};

  Set<int> get selectedIds => Set.unmodifiable(_selectedIds);
  int get selectedCount => _selectedIds.length;

  void toggle(int id) {
    _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id);
    notifyListeners();
  }

  void selectAll(Iterable<int> ids) {
    _selectedIds.addAll(ids);
    notifyListeners();
  }

  void clear() {
    if (_selectedIds.isEmpty) return;
    _selectedIds.clear();
    notifyListeners();
  }

  void replace(Iterable<int> ids) {
    final next = ids.toSet();
    if (_selectedIds.length == next.length && _selectedIds.containsAll(next)) {
      return;
    }
    _selectedIds
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  void retain(Iterable<int> ids) {
    final allowed = ids.toSet();
    if (_selectedIds.every(allowed.contains)) return;
    _selectedIds.removeWhere((id) => !allowed.contains(id));
    notifyListeners();
  }
}

typedef QuestionWorkspaceSliversBuilder =
    List<Widget> Function(BuildContext context, Set<int> selectedIds);
typedef QuestionWorkspaceBottomBuilder =
    Widget? Function(BuildContext context, Set<int> selectedIds);

class QuestionWorkspace extends StatefulWidget {
  const QuestionWorkspace({
    super.key,
    required this.items,
    required this.onOpen,
    this.controller,
    this.basketRepository,
    this.headerSliversBuilder,
    this.stateSlivers,
    this.bottomBuilder,
    this.onReorder,
    this.onEdit,
    this.scrollController,
    this.physics = const AlwaysScrollableScrollPhysics(),
    this.bottomSpacing = AppSpacing.xl,
    this.onSelectionChanged,
  });

  final List<QuestionWorkspaceItem> items;
  final ValueChanged<QuestionWorkspaceItem> onOpen;
  final QuestionWorkspaceController? controller;
  final PaperFolderRepository? basketRepository;
  final QuestionWorkspaceSliversBuilder? headerSliversBuilder;
  final List<Widget>? stateSlivers;
  final QuestionWorkspaceBottomBuilder? bottomBuilder;
  final ReorderCallback? onReorder;
  final ValueChanged<QuestionWorkspaceItem>? onEdit;
  final ScrollController? scrollController;
  final ScrollPhysics physics;
  final double bottomSpacing;
  final ValueChanged<Set<int>>? onSelectionChanged;

  @override
  State<QuestionWorkspace> createState() => _QuestionWorkspaceState();
}

class _QuestionWorkspaceState extends State<QuestionWorkspace> {
  late final QuestionWorkspaceController _ownedController =
      QuestionWorkspaceController();
  QuestionWorkspaceController get _controller =>
      widget.controller ?? _ownedController;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant QuestionWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldController = oldWidget.controller ?? _ownedController;
    if (oldController != _controller) {
      oldController.removeListener(_changed);
      _controller.addListener(_changed);
    }
    _controller.retain(widget.items.map((item) => item.id));
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _ownedController.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    widget.onSelectionChanged?.call(_controller.selectedIds);
    setState(() {});
  }

  Future<void> _addToBasket() async {
    final repository = widget.basketRepository;
    if (repository == null) return;
    final added = await addQuestionsToBaskets(
      context: context,
      repository: repository,
      questionIds: _controller.selectedIds,
    );
    if (added) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIds = _controller.selectedIds;
    final customBottom = widget.bottomBuilder?.call(context, selectedIds);
    final defaultBottom =
        widget.basketRepository != null && selectedIds.isNotEmpty
        ? _QuestionSelectionBottomBar(
            selectedCount: selectedIds.length,
            onAddToBasket: _addToBasket,
          )
        : null;
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: widget.scrollController,
            physics: widget.physics,
            slivers: [
              ...?widget.headerSliversBuilder?.call(context, selectedIds),
              ...?widget.stateSlivers,
              if (widget.stateSlivers == null)
                _buildQuestionSliver(selectedIds),
              SliverToBoxAdapter(child: SizedBox(height: widget.bottomSpacing)),
            ],
          ),
        ),
        ?customBottom,
        ?defaultBottom,
      ],
    );
  }

  Widget _buildQuestionSliver(Set<int> selectedIds) {
    if (widget.onReorder != null) {
      return SliverReorderableList(
        itemCount: widget.items.length,
        onReorderItem: widget.onReorder!,
        itemBuilder: (context, index) => _buildCard(
          widget.items[index],
          index,
          selectedIds,
          reorderable: true,
        ),
      );
    }
    return SliverList.builder(
      itemCount: widget.items.length,
      itemBuilder: (context, index) =>
          _buildCard(widget.items[index], index, selectedIds),
    );
  }

  Widget _buildCard(
    QuestionWorkspaceItem item,
    int index,
    Set<int> selectedIds, {
    bool reorderable = false,
  }) {
    final card = _QuestionSelectionCard(
      key: ValueKey(item.id),
      item: item,
      selected: selectedIds.contains(item.id),
      onOpen: () => widget.onOpen(item),
      onToggle: () => _controller.toggle(item.id),
      reorderIndex: reorderable ? index : null,
    );
    if (widget.onEdit == null) return card;
    return GestureDetector(
      key: ValueKey('edit-${item.id}'),
      onLongPress: () => widget.onEdit!(item),
      onSecondaryTap: () => widget.onEdit!(item),
      child: card,
    );
  }
}

class _QuestionSelectionCard extends StatelessWidget {
  const _QuestionSelectionCard({
    super.key,
    required this.item,
    required this.selected,
    required this.onOpen,
    required this.onToggle,
    this.reorderIndex,
  });

  final QuestionWorkspaceItem item;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: QuestionCard(
      questionId: item.id,
      title: item.title,
      questionType: item.questionType,
      subtitle: item.subtitle,
      difficulty: item.difficulty,
      status: item.status,
      compact: true,
      onTap: onOpen,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: selected ? '取消选择' : '选择题目',
            visualDensity: VisualDensity.compact,
            onPressed: onToggle,
            icon: Icon(
              selected ? Icons.check_circle : Icons.add_circle_outline,
              color: selected
                  ? context.colors.primary
                  : context.colors.textSecondary,
            ),
          ),
          if (reorderIndex != null)
            ReorderableDelayedDragStartListener(
              index: reorderIndex!,
              child: const Tooltip(
                message: '长按拖动排序',
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Icon(Icons.drag_handle_rounded),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _QuestionSelectionBottomBar extends StatelessWidget {
  const _QuestionSelectionBottomBar({
    required this.selectedCount,
    required this.onAddToBasket,
  });

  final int selectedCount;
  final VoidCallback onAddToBasket;

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();
    return SafeArea(
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
            Expanded(
              child: Text(
                '已选 $selectedCount 道题',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            AppButton(
              onPressed: onAddToBasket,
              icon: Icons.shopping_cart_checkout_outlined,
              label: '加入试题篮',
              expanded: false,
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> addQuestionsToBaskets({
  required BuildContext context,
  required PaperFolderRepository repository,
  required Set<int> questionIds,
}) async {
  if (questionIds.isEmpty) return false;
  var folders = await repository.list();
  if (folders.isEmpty) {
    await repository.defaultFolderId();
    folders = await repository.list();
  }
  if (!context.mounted) return false;
  final duplicateCounts = <int, int>{};
  final items = await Future.wait(
    folders.map((folder) async {
      final detail = await repository.detail(folder.id);
      final duplicateCount = detail.questions
          .where((question) => questionIds.contains(question.id))
          .length;
      duplicateCounts[folder.id] = duplicateCount;
      return BasketSelectionItem(
        id: folder.id,
        name: folder.name,
        subtitle:
            '${folder.questionCount} 道题 · 新增 ${questionIds.length - duplicateCount} 道 · 已有 $duplicateCount 道',
      );
    }),
  );
  if (!context.mounted) return false;
  final selectedFolderIds = await showBasketSelectionPanel(
    context: context,
    title: '加入试题篮',
    subtitle: '已选择 ${questionIds.length} 道题',
    items: items,
    initialSelectedIds: items.isEmpty ? const {} : {items.first.id},
    multiple: true,
    footerBuilder: (ids) {
      final duplicateCount = ids.fold<int>(
        0,
        (sum, id) => sum + (duplicateCounts[id] ?? 0),
      );
      final addedCount = ids.length * questionIds.length - duplicateCount;
      return BasketSelectionFooter(
        summary: ids.isEmpty
            ? '请选择至少一个试题篮'
            : '将 ${questionIds.length} 道题加入 ${ids.length} 个试题篮，新增 $addedCount 道次，已有 $duplicateCount 道次',
        confirmLabel: ids.isEmpty ? '请选择试题篮' : '加入所选试题篮',
        confirmIcon: Icons.shopping_cart_checkout_outlined,
      );
    },
    onCreate: () async {
      final name = await showCreateBasketDialog(context);
      if (name == null || name.isEmpty) return null;
      final id = await repository.create(name);
      duplicateCounts[id] = 0;
      return BasketSelectionItem(
        id: id,
        name: name,
        subtitle: '0 道题 · 新增 ${questionIds.length} 道 · 已有 0 道',
      );
    },
  );
  if (selectedFolderIds == null || selectedFolderIds.isEmpty) return false;
  final result = await repository.prependQuestionsToFolders(
    selectedFolderIds,
    questionIds,
  );
  final folderId = selectedFolderIds.first;
  await repository.setActiveFolder(folderId);
  if (!context.mounted) return false;
  AppToast.success(
    context,
    '已加入 ${selectedFolderIds.length} 个试题篮：新增 ${result.added} 道次，${result.existing} 道次已存在',
    actionLabel: '查看试题篮',
    onAction: () => RouterUtils.push(
      context,
      '${AppRoutes.paperFolderDetail}?id=$folderId',
    ),
  );
  return true;
}
