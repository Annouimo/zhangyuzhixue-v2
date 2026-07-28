import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../router.dart';

/// 智能组卷积分消耗
const int _autoPaperCost = 10;

/// 自主选题积分消耗
const int _pickPaperCost = 20;

/// 组卷首页 — 创建、管理与发现试卷。
class ExamHomePage extends StatelessWidget {
  const ExamHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    AuditLogger.instance.page('ExamHomePage', {'visited': true});

    return Scaffold(
      appBar: AppBar(title: const Text('组卷')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: AppContentContainer(
          maxWidth: AppContentWidth.dashboard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: '智能组卷 · $_autoPaperCost 积分',
                    icon: Icons.auto_awesome_rounded,
                    onPressed: () =>
                        RouterUtils.push(context, AppRoutes.examAuto),
                  ),
                  AppButton(
                    label: '自主选题 · $_pickPaperCost 积分',
                    icon: Icons.touch_app_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () =>
                        RouterUtils.push(context, AppRoutes.examPick),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppSectionHeader(
                title: '我的试卷空间',
                subtitle: '管理已创建的试卷，也可以发现和收藏其他同学分享的内容。',
              ),
              const SizedBox(height: AppSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      constraints.maxWidth >= AppBreakpoints.expanded
                      ? 3
                      : constraints.maxWidth >= AppBreakpoints.compact
                      ? 2
                      : 1;
                  const gap = AppSpacing.md;
                  final width = columns == 1
                      ? constraints.maxWidth
                      : (constraints.maxWidth - gap * (columns - 1)) / columns;

                  final entries = [
                    _ExamEntry(
                      icon: Icons.folder_copy_outlined,
                      title: '我的组卷',
                      subtitle: '管理、公开或删除我创建的试卷',
                      tone: AppStatusTone.primary,
                      onTap: () =>
                          RouterUtils.push(context, AppRoutes.examHistory),
                    ),
                    _ExamEntry(
                      icon: Icons.explore_outlined,
                      title: '发现组卷',
                      subtitle: '浏览公开试卷，按热度或时间筛选',
                      tone: AppStatusTone.recommendation,
                      onTap: () =>
                          RouterUtils.push(context, AppRoutes.examExplore),
                    ),
                    _ExamEntry(
                      icon: Icons.bookmark_outline_rounded,
                      title: '我的收藏',
                      subtitle: '随时查看已经收藏的优质试卷',
                      tone: AppStatusTone.success,
                      onTap: () =>
                          RouterUtils.push(context, AppRoutes.examFavorites),
                    ),
                  ];

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: entries
                        .map((entry) => SizedBox(width: width, child: entry))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamEntry extends StatelessWidget {
  const _ExamEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppStatusTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      semanticLabel: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppStatusBadge(
                label: title,
                tone: tone,
                icon: icon,
                compact: true,
              ),
              const Spacer(),
              Icon(AppIcons.chevronRight, color: colors.textMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
