import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/progress_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/question_review_repository.dart';
import '../router.dart';

class StudyArchivePage extends StatefulWidget {
  const StudyArchivePage({super.key});

  @override
  State<StudyArchivePage> createState() => _StudyArchivePageState();
}

class _StudyArchivePageState extends State<StudyArchivePage> {
  late final QuestionReviewRepository _reviewRepository =
      LocalQuestionReviewRepository(
        ProgressDao(DatabaseProvider()),
        QuestionDao(DatabaseProvider()),
      );
  QuestionReviewSummary? _reviewSummary;

  @override
  void initState() {
    super.initState();
    _loadReviewSummary();
  }

  Future<void> _loadReviewSummary() async {
    try {
      final summary = await _reviewRepository.getSummary();
      if (mounted) setState(() => _reviewSummary = summary);
    } catch (_) {
      // The archive remains usable if the local review summary is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习档案')),
      body: AppContentContainer(
        maxWidth: AppContentWidth.reading,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            AppResponsiveCardGrid(
              children: [
                AppNavigationCard(
                  icon: Icons.radar_rounded,
                  title: '学习复盘',
                  subtitle: '查看掌握状态和需要巩固的知识点',
                  onTap: () => RouterUtils.push(context, AppRoutes.review),
                ),
                AppNavigationCard(
                  icon: Icons.insights_rounded,
                  title: '学习统计',
                  subtitle: '查看正确率、活跃度和题型分布',
                  onTap: () => RouterUtils.push(context, AppRoutes.statistics),
                ),
                AppNavigationCard(
                  icon: Icons.history_rounded,
                  title: '做题记录',
                  subtitle: '继续未完成的作答或回顾历史题目',
                  onTap: () =>
                      RouterUtils.push(context, AppRoutes.profileHistory),
                ),
                AppNavigationCard(
                  icon: Icons.error_outline_rounded,
                  title: '当前错题',
                  subtitle: _reviewSummary == null
                      ? '查看尚未订正的题目'
                      : '${_reviewSummary!.currentWrongCount} 题尚未订正',
                  onTap: () => RouterUtils.push(
                    context,
                    '${AppRoutes.questionBank}?review=current-wrong',
                  ),
                ),
                AppNavigationCard(
                  icon: Icons.task_alt_rounded,
                  title: '已订正',
                  subtitle: _reviewSummary == null
                      ? '回顾已经订正的错题'
                      : '${_reviewSummary!.correctedCount} 题已订正',
                  onTap: () => RouterUtils.push(
                    context,
                    '${AppRoutes.questionBank}?review=corrected',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
