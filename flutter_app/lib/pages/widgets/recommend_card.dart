import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/theme/app_icons.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_status_badge.dart';
import 'package:shared/widgets/md_latex_body.dart';

/// 推荐页专用题目卡片。
///
/// 强化推荐原因和“开始练习”行动，避免与普通题库列表使用完全相同的视觉层级。
class RecommendCard extends StatelessWidget {
  const RecommendCard({
    super.key,
    required this.title,
    required this.questionType,
    required this.difficulty,
    required this.reason,
    required this.onTap,
    this.status,
  });

  final String title;
  final String questionType;
  final double difficulty;
  final String reason;
  final String? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      semanticLabel: '推荐题目：$title',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusBadge(
                label: QuestionTypeLabels.of(questionType),
                tone: AppStatusTone.primary,
                compact: true,
              ),
              AppStatusBadge(
                label: DifficultySegments.diffNameFor(difficulty),
                tone: AppStatusTone.warning,
                icon: Icons.signal_cellular_alt_rounded,
                compact: true,
              ),
              if (status != null) _buildStatusBadge(status!),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          MdLatexBody(title, fontSize: 15),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: colors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    reason.isEmpty ? '推荐原因：适合你当前的学习进度' : '推荐原因：$reason',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                status == 'in_progress' ? '继续作答' : '开始练习',
                style: textTheme.labelLarge?.copyWith(color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Icon(AppIcons.chevronRight, size: 20, color: colors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String value) {
    return switch (value) {
      'completed' => const AppStatusBadge(
          label: '已完成',
          tone: AppStatusTone.success,
          compact: true,
        ),
      'in_progress' => const AppStatusBadge(
          label: '进行中',
          tone: AppStatusTone.warning,
          compact: true,
        ),
      _ => const AppStatusBadge(
          label: '未作答',
          tone: AppStatusTone.neutral,
          compact: true,
        ),
    };
  }
}
