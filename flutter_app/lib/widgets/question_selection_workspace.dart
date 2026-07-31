import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../domain/paper_folder_repository.dart';
import 'selected_questions_panel.dart';

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

class QuestionWorkspaceController extends AppSelectionController<int> {}

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
    this.onRemove,
    this.selectionEnabled = true,
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
  final ValueChanged<QuestionWorkspaceItem>? onRemove;
  final bool selectionEnabled;
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

  Future<void> _manageSelected() async {
    final repository = widget.basketRepository;
    if (repository == null) return;
    final completed = await manageSelectedQuestions(
      context: context,
      repository: repository,
      questionIds: _controller.selectedIds,
    );
    if (completed) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIds = _controller.selectedIds;
    final customBottom = widget.bottomBuilder?.call(context, selectedIds);
    final defaultBottom = widget.basketRepository != null
        ? AppSelectionActionBar(
            selectedCount: selectedIds.length,
            totalCount: widget.items.length,
            itemUnit: ' 道题',
            onSelectAll: () =>
                _controller.selectAll(widget.items.map((item) => item.id)),
            onClear: _controller.clear,
            actionLabel: '整理已选',
            actionIcon: Icons.checklist_rounded,
            onAction: selectedIds.isEmpty ? null : _manageSelected,
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
      onRemove: widget.onRemove == null ? null : () => widget.onRemove!(item),
      selectionEnabled: widget.selectionEnabled,
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
    required this.selectionEnabled,
    this.onRemove,
    this.reorderIndex,
  });

  final QuestionWorkspaceItem item;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final VoidCallback? onRemove;
  final bool selectionEnabled;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: QuestionCard(
      questionId: item.id,
      title: item.title,
      questionType: item.questionType,
      subtitle: item.subtitle,
      difficulty: item.difficulty,
      status: item.status,
      selected: selected,
      compact: true,
      onTap: onOpen,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectionEnabled)
            AppSelectionToggle(
              selected: selected,
              onPressed: onToggle,
              selectTooltip: '选择题目',
            ),
          if (onRemove != null)
            IconButton(
              tooltip: '移除题目',
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: Icon(
                Icons.remove_circle_outline,
                color: context.colors.error,
              ),
            ),
          if (reorderIndex != null)
            ReorderableDragStartListener(
              index: reorderIndex!,
              child: const Tooltip(
                message: '拖动排序',
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
