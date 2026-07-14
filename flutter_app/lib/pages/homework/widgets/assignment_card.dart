import 'package:flutter/material.dart';
import '../../../app_theme.dart';

/// 作业卡片 — 从 homework_list_page 提取的共享组件
///
/// 显示作业标题、课程名、进度条、截止天数。
class AssignmentCard extends StatelessWidget {
  final String title;
  final String courseName;
  final int doneCount;
  final int totalCount;
  final int deadlineDays;
  final VoidCallback onTap;

  const AssignmentCard({
    super.key,
    required this.title,
    required this.courseName,
    required this.doneCount,
    required this.totalCount,
    required this.deadlineDays,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? doneCount / totalCount : 0.0;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
                        ), maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (courseName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(courseName, style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(AppColors.success),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$doneCount/$totalCount', style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              if (deadlineDays > 0) ...[
                const SizedBox(height: 8),
                Text('剩余 $deadlineDays 天', style: TextStyle(
                  fontSize: 12, color: deadlineDays <= 3 ? AppColors.error : AppColors.warning)),
              ] else if (deadlineDays == 0) ...[
                const SizedBox(height: 8),
                const Text('今日截止', style: TextStyle(fontSize: 12, color: AppColors.error)),
              ] else ...[
                const SizedBox(height: 8),
                const Text('已截止', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
