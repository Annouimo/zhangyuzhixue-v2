import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/widgets/status_style.dart';

/// 作业卡片 — 从 homework_list_page 提取的共享组件
///
/// 显示作业标题、课程名、进度条、截止天数、状态标签。
class AssignmentCard extends StatelessWidget {
  final String title;
  final String courseName;
  final int doneCount;
  final int totalCount;
  final int? deadlineDays; // null = 无截止日期
  final String status;
  final VoidCallback onTap;

  AssignmentCard({
    super.key,
    required this.title,
    required this.courseName,
    required this.doneCount,
    required this.totalCount,
    required this.deadlineDays,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
      final colors = context.colors;
    final progress = totalCount > 0 ? doneCount / totalCount : 0.0;
    final st = _statusStyle(status);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.assignment,
                        color: colors.primary, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        if (courseName.isNotEmpty) ...[
                          SizedBox(height: 2),
                          Text(courseName,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                  // 状态标签
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: st.bg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      st.label,
                      style: TextStyle(
                          fontSize: 11,
                          color: st.color,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: colors.textSecondary),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: colors.surfaceSubtle,
                        valueColor:
                            AlwaysStoppedAnimation(colors.success),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('$doneCount/$totalCount',
                      style: TextStyle(
                          fontSize: 12, color: colors.textSecondary)),
                ],
              ),
              if (deadlineDays != null) ...[
                SizedBox(height: 8),
                if (deadlineDays! > 0)
                  Text('剩余 $deadlineDays 天',
                      style: TextStyle(
                        fontSize: 12,
                        color: deadlineDays! <= 3
                            ? colors.error
                            : colors.warning,
                      ))
                else if (deadlineDays! == 0)
                  Text('今日截止',
                      style:
                          TextStyle(fontSize: 12, color: colors.error))
                else
                  Text('已截止',
                      style: TextStyle(
                          fontSize: 12, color: colors.textSecondary)),
              ] else ...[
                SizedBox(height: 8),
                Text('无截止日期',
                    style: TextStyle(
                        fontSize: 12, color: colors.textSecondary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 状态标签样式
({String label, Color color, Color bg}) _statusStyle(String status) {
  return statusStyle(status);
}
