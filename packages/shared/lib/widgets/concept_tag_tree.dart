import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/domain/models.dart';

/// 树状概念标签选择视图
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
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.nodes.map((node) => _buildNode(node, 0)).toList(),
    );
  }

  Widget _buildNode(ConceptTagNode node, int depth) {
    final isLeaf = node.children.isEmpty;
    final isSelected = widget.selectedNames.contains(node.name);
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              final newSet = Set<String>.from(widget.selectedNames);
              if (isSelected) {
                newSet.remove(node.name);
              } else {
                newSet.add(node.name);
              }
              widget.onChanged(newSet);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 18,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    node.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isLeaf)
            ...node.children.map((child) => _buildNode(child, depth + 1)),
        ],
      ),
    );
  }
}
