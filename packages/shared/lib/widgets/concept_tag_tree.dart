import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/domain/models.dart';

/// 树状概念标签选择视图
///
/// 父节点联动子节点：
/// - 点父节点 → 全选/全取消该节点及其所有子节点
/// - 单独点子节点 → 子状态改变后自动同步父节点（全部子选中→父选中，全部未选→父取消）
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
  // name → 所有子孙节点的 name 集合（含自身）
  late Map<String, Set<String>> _descMap;
  // name → 父节点 name（根节点为 null）
  late Map<String, String?> _parentMap;

  @override
  void initState() {
    super.initState();
    _buildMaps();
  }

  @override
  void didUpdateWidget(ConceptTagTreeView old) {
    super.didUpdateWidget(old);
    if (old.nodes != widget.nodes) _buildMaps();
  }

  void _buildMaps() {
    _descMap = {};
    _parentMap = {};
    for (final node in widget.nodes) {
      _walk(node, null);
    }
  }

  Set<String> _walk(ConceptTagNode node, String? parent) {
    _parentMap[node.name] = parent;
    final all = <String>{node.name};
    for (final child in node.children) {
      all.addAll(_walk(child, node.name));
    }
    _descMap[node.name] = all;
    return all;
  }

  /// 点击节点：切换该节点及其所有子孙的选中态
  void _toggleNode(ConceptTagNode node) {
    final newSet = Set<String>.from(widget.selectedNames);
    final all = _descMap[node.name]!;
    if (widget.selectedNames.contains(node.name)) {
      newSet.removeAll(all);
    } else {
      newSet.addAll(all);
    }
    widget.onChanged(newSet);
  }

  /// 叶子节点被单独点击后，向上同步父节点状态
  Set<String> _syncParents(Set<String> set, String name) {
    var p = _parentMap[name];
    while (p != null) {
      // 查找该父节点的所有直接子节点
      final children = _findDirectChildren(p);
      if (children == null) break;
      final allSel = children.every((c) => set.contains(c));
      final noneSel = children.every((c) => !set.contains(c));
      if (allSel) {
        set.add(p);
      } else if (noneSel) {
        set.remove(p);
      }
      p = _parentMap[p];
    }
    return set;
  }

  /// 查找 name 对应的 ConceptTagNode 的直接子节点名列表
  List<String>? _findDirectChildren(String name) {
    for (final root in widget.nodes) {
      final result = _findInNode(root, name);
      if (result != null) return result;
    }
    return null;
  }

  List<String>? _findInNode(ConceptTagNode node, String target) {
    if (node.name == target) {
      return node.children.map((c) => c.name).toList();
    }
    for (final child in node.children) {
      final r = _findInNode(child, target);
      if (r != null) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
      final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.nodes.map((node) => _buildNode(node, 0)).toList(),
    );
  }

  Widget _buildNode(ConceptTagNode node, int depth) {
      final colors = context.colors;
    final isLeaf = node.children.isEmpty;
    final isSelected = widget.selectedNames.contains(node.name);
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => isLeaf
                ? widget.onChanged(
                    _syncParents(
                      Set<String>.from(widget.selectedNames)..toggle(node.name),
                      node.name,
                    ),
                  )
                : _toggleNode(node),
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
                    color: isSelected ? colors.primary : colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    node.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? colors.primary : colors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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

extension _ToggleSet on Set<String> {
  void toggle(String value) {
    if (contains(value)) { remove(value); } else { add(value); }
  }
}
