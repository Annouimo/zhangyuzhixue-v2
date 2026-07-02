import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 题目条目组件（来源/难度/计算量/标签预览）
class QuestionTile extends StatelessWidget {
  final Map<String, dynamic> question;
  final bool isSelected;
  final VoidCallback onToggle;

  const QuestionTile({
    super.key,
    required this.question,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
      child: ListTile(
        leading: Checkbox(value: isSelected, onChanged: (_) => onToggle()),
        title: Text(question['source'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: AppTheme.fontSizeBody)),
        subtitle: Text(
          '难度 ${question['difficulty'] ?? 0}  计算量 ${question['calculation'] ?? 0}',
          style: const TextStyle(fontSize: AppTheme.fontSizeSmall),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onToggle,
      ),
    );
  }
}
