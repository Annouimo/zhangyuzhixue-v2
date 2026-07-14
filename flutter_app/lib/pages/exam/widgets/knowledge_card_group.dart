import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../domain/exam_repository.dart';

/// 分类知识卡片选择组件
///
/// 按 category 分组展示，每组支持折叠/展开和全选/全不选。
class KnowledgeCardGroupView extends StatefulWidget {
  final List<KnowledgeCardGroup> groups;
  final Set<String> selectedTitles;
  final ValueChanged<Set<String>> onChanged;

  const KnowledgeCardGroupView({
    super.key,
    required this.groups,
    required this.selectedTitles,
    required this.onChanged,
  });

  @override
  State<KnowledgeCardGroupView> createState() => _KnowledgeCardGroupViewState();
}

class _KnowledgeCardGroupViewState extends State<KnowledgeCardGroupView> {
  final _expandedCategories = <String>{};

  @override
  void initState() {
    super.initState();
    // 默认全部展开
    for (final g in widget.groups) {
      _expandedCategories.add(g.category);
    }
  }

  void _toggleCategory(String cat) {
    setState(() {
      if (_expandedCategories.contains(cat)) {
        _expandedCategories.remove(cat);
      } else {
        _expandedCategories.add(cat);
      }
    });
  }

  void _selectAll(String category) {
    final group = widget.groups.firstWhere((g) => g.category == category);
    final updated = Set<String>.from(widget.selectedTitles);
    for (final card in group.cards) {
      updated.add(card.title);
    }
    widget.onChanged(updated);
  }

  void _deselectAll(String category) {
    final group = widget.groups.firstWhere((g) => g.category == category);
    final updated = Set<String>.from(widget.selectedTitles);
    for (final card in group.cards) {
      updated.remove(card.title);
    }
    widget.onChanged(updated);
  }

  void _toggleCard(String title) {
    final updated = Set<String>.from(widget.selectedTitles);
    if (updated.contains(title)) {
      updated.remove(title);
    } else {
      updated.add(title);
    }
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.groups.map(_buildGroup).toList(),
    );
  }

  Widget _buildGroup(KnowledgeCardGroup group) {
    final expanded = _expandedCategories.contains(group.category);
    final categorySelected = group.cards.every((c) => widget.selectedTitles.contains(c.title));
    final categoryPartial = group.cards.any((c) => widget.selectedTitles.contains(c.title)) && !categorySelected;
    final selectedCount = group.cards.where((c) => widget.selectedTitles.contains(c.title)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _toggleCategory(group.category),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    '${group.category}（${group.cards.length}）',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (categorySelected)
                  TextButton(
                    onPressed: () => _deselectAll(group.category),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('全不选', style: TextStyle(fontSize: 11)),
                  )
                else
                  TextButton(
                    onPressed: () => _selectAll(group.category),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('全选', style: TextStyle(fontSize: 11)),
                  ),
                if (categoryPartial)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '$selectedCount/${group.cards.length}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          Wrap(
            spacing: 6,
            runSpacing: 4,
            padding: const EdgeInsets.only(left: 20, bottom: 4),
            children: group.cards.map((card) => FilterChip(
              label: Text(card.title, style: const TextStyle(fontSize: 12)),
              selected: widget.selectedTitles.contains(card.title),
              onSelected: (_) => _toggleCard(card.title),
              selectedColor: AppColors.primaryLight,
              checkmarkColor: AppColors.primary,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            )).toList(),
          ),
          const SizedBox(height: 2),
        ],
      ],
    );
  }
}
