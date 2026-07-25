import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// 作业摘要卡片。
class AssignmentCard extends StatelessWidget {
  const AssignmentCard({
    super.key,
    required this.title,
    required this.courseName,
    required this.doneCount,
    required this.totalCount,
    required this.deadlineDays,
    required this.status,
    required this.onTap,
  });

  final String title;
  final String courseName;
  final int doneCount;
  final int totalCount;
  final int? deadlineDays;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final progress = totalCount > 0 ? doneCount / totalCount : 0.0;
    final statusInfo = statusStyle(status, colors);

    return AppCard(
      onTap: onTap,
      semanticLabel: title,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  color: colors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (courseName.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        courseName,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppStatusBadge(
                label: statusInfo.label,
                tone: _statusTone(status),
                compact: true,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Icon(AppIcons.chevronRight, color: colors.textMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: colors.surfaceSubtle,
                    valueColor: AlwaysStoppedAnimation(
                      progress >= 1 ? colors.success : colors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$doneCount / $totalCount',
                style: textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                _deadlineIcon,
                size: 16,
                color: _deadlineColor(colors),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                _deadlineLabel,
                style: textTheme.bodySmall?.copyWith(
                  color: _deadlineColor(colors),
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}% 完成',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  AppStatusTone _statusTone(String value) {
    if (value == 'completed') return AppStatusTone.success;
    if (value == 'in_progress' || value == 'inProgress') {
      return AppStatusTone.info;
    }
    return AppStatusTone.neutral;
  }

  String get _deadlineLabel {
    if (deadlineDays == null) return '无截止日期';
    if (deadlineDays! < 0) return '已截止';
    if (deadlineDays == 0) return '今日截止';
    return '剩余 $deadlineDays 天';
  }

  IconData get _deadlineIcon {
    if (deadlineDays == null) return Icons.event_available_outlined;
    if (deadlineDays! <= 0) return Icons.event_busy_outlined;
    return Icons.schedule_rounded;
  }

  Color _deadlineColor(AppSemanticColors colors) {
    if (deadlineDays == null) return colors.textMuted;
    if (deadlineDays! <= 0) return colors.error;
    if (deadlineDays! <= 3) return colors.warning;
    return colors.textSecondary;
  }
}
