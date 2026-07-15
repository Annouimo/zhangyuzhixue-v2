import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../domain/question_repository.dart';

/// 树状概念标签选择组件
///
/// 选中父节点自动选中全部子节点，取消全部子节点自动取消父节点。
class ConceptTagTreeView extends StatefulWidget {
  final List<ConceptTagNode> nodes;
  final Set<String> selectedNames;
  final ValueChanged<Set<String>> onChanged;

  const ConceptTagTreeView({
    super.key,
    required this.nodes,
    required this.selectedNames,
    required this.onChanged,
  });

  @override
  State<ConceptTagTreeView> createState() => _ConceptTagTreeViewState();
}

class _ConceptTagTreeViewState extends State<ConceptTagTreeView> {
  final _expandedIds = <int>{};

  /// 递归收集节点及其所有子节点的 name
  static Set<String> _collectNames(ConceptTagNode node) {
    final names = <String>{node.name};
    for (final child in node.children) {
      names.addAll(_collectNames(child));
    }
    return names;
  }

  /// 判断节点是否被选中（含间接：父选中 → 子算选中）
  bool _isSelected(ConceptTagNode node) {
    return widget.selectedNames.contains(node.name);
  }

  /// 切换节点选中状态
  void _toggle(ConceptTagNode node) {
    final names = _collectNames(node);
    final allSelected = names.every((n) => widget.selectedNames.contains(n));
    final updated = Set<String>.from(widget.selectedNames);
    if (allSelected) {
      // 全选中 → 取消选中
      updated.removeAll(names);
    } else {
      // 有未选 → 全选
      updated.addAll(names);
    }
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.nodes.map((node) => _buildNode(node, 0)).toList(),
    );
  }

  Widget _buildNode(ConceptTagNode node, int depth) {
    final hasChildren = node.children.isNotEmpty;
    final selected = _isSelected(node);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _toggle(node),
          child: Padding(
            padding: EdgeInsets.only(left: depth * 16.0),
            child: Row(
              children: [
                if (hasChildren)
                  GestureDetector(
                    onTap: () => setState(() {
                      if (_expandedIds.contains(node.id)) {
                        _expandedIds.remove(node.id);
                      } else {
                        _expandedIds.add(node.id);
                      }
                    }),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        _expandedIds.contains(node.id)
                            ? Icons.expand_more
                            : Icons.chevron_right,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 20),
                Icon(
                  selected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  node.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasChildren && _expandedIds.contains(node.id))
          ...node.children.map((child) => _buildNode(child, depth + 1)),
      ],
    );
  }
}
