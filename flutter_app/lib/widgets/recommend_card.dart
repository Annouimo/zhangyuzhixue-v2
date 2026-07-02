import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 推荐题目卡片
class RecommendCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final VoidCallback onTap;

  const RecommendCard({super.key, required this.question, required this.onTap});

  Color _statusColor(String? status) {
    switch (status) {
      case '已完成': return AppTheme.statusGreen;
      case '进行中': return AppTheme.statusOrange;
      default: return AppTheme.statusGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = question['status'] as String? ?? '未做';
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium, vertical: 6),
        title: Text(question['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(question['course'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontSizeSmall)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(status).withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(status, style: TextStyle(color: _statusColor(status), fontSize: AppTheme.fontSizeSmall)),
        ),
        onTap: onTap,
      ),
    );
  }
}
