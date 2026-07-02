import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 作业卡片（可复用组件）
class AssignmentCard extends StatelessWidget {
  final String name;
  final String progress;
  final String course;
  final int daysLeft;
  final VoidCallback onTap;

  const AssignmentCard({
    super.key,
    required this.name,
    required this.progress,
    required this.course,
    required this.daysLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.paddingMedium),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: AppTheme.fontSizeTitle)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('完成 $progress', style: const TextStyle(color: AppTheme.primaryColor)),
              const SizedBox(height: 4),
              Text('所属课程：$course', style: const TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontSizeSmall)),
              Text('还有 $daysLeft 天截止', style: const TextStyle(color: AppTheme.statusOrange, fontSize: AppTheme.fontSizeSmall)),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
