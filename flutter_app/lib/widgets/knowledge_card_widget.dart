import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 知识卡片组件（点击展开/收起，展开后显示详情 + 卡片反馈按钮）
class KnowledgeCardWidget extends StatefulWidget {
  final String title;
  final String content;

  const KnowledgeCardWidget({super.key, required this.title, this.content = '（知识卡片详细内容略）'});

  @override
  State<KnowledgeCardWidget> createState() => _KnowledgeCardWidgetState();
}

class _KnowledgeCardWidgetState extends State<KnowledgeCardWidget> {
  bool _expanded = false;
  String? _feedback;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 卡片标签（可点击）
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _expanded ? AppTheme.primaryColor.withAlpha(30) : AppTheme.primaryLight.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.primaryColor.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline, size: 14, color: _expanded ? AppTheme.primaryDark : AppTheme.primaryColor),
                const SizedBox(width: 4),
                Text(widget.title, style: TextStyle(
                  fontSize: 12,
                  color: _expanded ? AppTheme.primaryDark : AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                )),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: _expanded ? AppTheme.primaryDark : AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
        // 展开详情
        if (_expanded) ...[
          const SizedBox(height: 4),
          Container(
            width: 200,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.dividerColor),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.content, style: const TextStyle(fontSize: AppTheme.fontSizeSmall, height: 1.5)),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 4),
                const Text('掌握情况', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _feedbackChip('完全掌握', AppTheme.statusGreen),
                    const SizedBox(width: 4),
                    _feedbackChip('了解', Colors.orange),
                    const SizedBox(width: 4),
                    _feedbackChip('不理解', Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _feedbackChip(String label, Color color) {
    final selected = _feedback == label;
    return GestureDetector(
      onTap: () {
        setState(() => _feedback = label);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('正在进行记录卡片反馈操作，需要写入卡片反馈数据（$label）')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: selected ? color : color.withAlpha(80)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: selected ? color : color.withAlpha(180))),
      ),
    );
  }
}
