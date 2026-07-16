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
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.groups.map((group) => _buildGroup(group)).toList(),
    );
  }

  Widget _buildGroup(KnowledgeCardGroup group) {
    final groupTitles = group.cards.map((c) => c.title).toSet();
    final selectedCount = widget.selectedTitles.where((t) => groupTitles.contains(t)).length;
    final allSelected = selectedCount == group.cards.length;
    final showToggle = group.cards.length > 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(group.category,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
                    style: const TextStyle(fontSize: 11, color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: group.cards.map((card) => FilterChip(
              label: Text(card.title, style: const TextStyle(fontSize: 12)),
              selected: widget.selectedTitles.contains(card.title),
              onSelected: (v) {
                final newSet = Set<String>.from(widget.selectedTitles);
                v ? newSet.add(card.title) : newSet.remove(card.title);
                widget.onChanged(newSet);
              },
              selectedColor: AppColors.primaryLight,
              checkmarkColor: AppColors.primary,
              side: widget.selectedTitles.contains(card.title)
                  ? BorderSide.none
                  : const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
