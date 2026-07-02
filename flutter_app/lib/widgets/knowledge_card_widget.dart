import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 知识卡片组件（点击展开/收起）
class KnowledgeCardWidget extends StatefulWidget {
  final String title;
  final String content;

  const KnowledgeCardWidget({super.key, required this.title, this.content = '（知识卡片详细内容略）'});

  @override
  State<KnowledgeCardWidget> createState() => _KnowledgeCardWidgetState();
}

class _KnowledgeCardWidgetState extends State<KnowledgeCardWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.primaryLight.withAlpha(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.buttonRadius)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.primaryColor))),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.primaryColor),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text(widget.content, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
            ),
        ],
      ),
    );
  }
}
