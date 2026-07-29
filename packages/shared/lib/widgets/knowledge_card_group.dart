import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/domain/models.dart';

/// 分类知识卡片组选择视图
///
/// 每组标题旁带「全选/取消全选」按钮，支持整组一键操作。
class KnowledgeCardGroupView extends StatefulWidget {
  final List<KnowledgeCardGroup> groups;
  final Set<String> selectedTitles;
  final ValueChanged<Set<String>> onChanged;
  final bool compact;
  final int previewCount;

  const KnowledgeCardGroupView({
    super.key,
    required this.groups,
    required this.selectedTitles,
    required this.onChanged,
    this.compact = false,
    this.previewCount = 10,
  });

  @override
  State<KnowledgeCardGroupView> createState() => _KnowledgeCardGroupViewState();
}

class _KnowledgeCardGroupViewState extends State<KnowledgeCardGroupView> {
  String? _expandedCategory;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.groups.map((group) {
        if (!widget.compact) return _buildGroup(group);
        final expanded = _expandedCategory == group.category;
        return ExpansionTile(
          key: PageStorageKey(group.category),
          initiallyExpanded: expanded,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: Text(group.category),
          subtitle: Text('${group.cards.length} 项'),
          onExpansionChanged: (value) =>
              setState(() => _expandedCategory = value ? group.category : null),
          children: [_buildGroup(group, hideHeader: true, previewOnly: true)],
        );
      }).toList(),
    );
  }

  Widget _buildGroup(
    KnowledgeCardGroup group, {
    bool hideHeader = false,
    bool previewOnly = false,
  }) {
    final colors = context.colors;
    final groupTitles = group.cards.map((c) => c.title).toSet();
    final selectedCount = widget.selectedTitles
        .where((t) => groupTitles.contains(t))
        .length;
    final allSelected = selectedCount == group.cards.length;
    final showToggle = group.cards.length > 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hideHeader)
            Row(
              children: [
                Text(
                  group.category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (showToggle) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      final newSet = Set<String>.from(widget.selectedTitles);
                      if (allSelected) {
                        newSet.removeAll(groupTitles);
                      } else {
                        newSet.addAll(groupTitles);
                      }
                      widget.onChanged(newSet);
                    },
                    child: Text(
                      allSelected ? '取消全选' : '全选',
                      style: TextStyle(fontSize: 11, color: colors.primary),
                    ),
                  ),
                ],
              ],
            ),
          if (!hideHeader) const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children:
                (previewOnly
                        ? group.cards.take(widget.previewCount)
                        : group.cards)
                    .map(
                      (card) => FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              card.title,
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (card.questionCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${card.questionCount}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ],
                        ),
                        selected: widget.selectedTitles.contains(card.title),
                        onSelected: (v) {
                          final newSet = Set<String>.from(
                            widget.selectedTitles,
                          );
                          v
                              ? newSet.add(card.title)
                              : newSet.remove(card.title);
                          widget.onChanged(newSet);
                        },
                        selectedColor: colors.primaryContainer,
                        checkmarkColor: colors.primary,
                        side: widget.selectedTitles.contains(card.title)
                            ? BorderSide.none
                            : BorderSide(color: colors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    )
                    .toList(),
          ),
          if (previewOnly && group.cards.length > widget.previewCount)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showAllCards(group),
                icon: const Icon(Icons.search_rounded),
                label: Text('查看全部 ${group.cards.length} 项'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAllCards(KnowledgeCardGroup group) async {
    final controller = TextEditingController();
    var query = '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final cards = group.cards
              .where((card) => card.title.toLowerCase().contains(query))
              .toList();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.category,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: '搜索知识卡片',
                      ),
                      onChanged: (value) => setSheetState(
                        () => query = value.trim().toLowerCase(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          final selected = widget.selectedTitles.contains(
                            card.title,
                          );
                          return CheckboxListTile(
                            value: selected,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(card.title),
                            subtitle: card.questionCount > 0
                                ? Text('${card.questionCount} 题')
                                : null,
                            onChanged: (_) {
                              final next = Set<String>.from(
                                widget.selectedTitles,
                              );
                              selected
                                  ? next.remove(card.title)
                                  : next.add(card.title);
                              widget.onChanged(next);
                              setSheetState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    controller.dispose();
  }
}
