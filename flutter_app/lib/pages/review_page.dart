import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../data/daos/progress_dao.dart';
import '../data/daos/question_dao.dart';
import '../data/database/database_provider.dart';
import '../domain/review_repository.dart';
import 'router.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, this.reviewRepository});

  final ReviewRepository? reviewRepository;

  @override
  State<ReviewPage> createState() => ReviewPageState();
}

class ReviewPageState extends State<ReviewPage> {
  late final ReviewRepository _repository =
      widget.reviewRepository ??
      ReviewRepository(
        QuestionDao(DatabaseProvider()),
        ProgressDao(DatabaseProvider()),
      );
  List<ConceptProgress>? _concepts;
  String? _error;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    try {
      final concepts = await _repository.getConceptProgress();
      if (!mounted) return;
      setState(() {
        _concepts = concepts;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '学习记录加载失败，请稍后重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('复盘')),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: AppContentContainer(
          maxWidth: AppContentWidth.dashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              const AppFeatureBanner(
                eyebrow: '学习反馈',
                icon: Icons.radar_rounded,
                title: '从记录中找到下一步',
                subtitle: '掌握状态根据现有答题结果动态计算，不需要手工维护复习计划。',
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildActions(),
              const SizedBox(height: AppSpacing.xl),
              const AppSectionHeader(
                title: '知识点状态',
                subtitle: '当前为第一版动态判断，会随新的答题结果即时变化。',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildConcepts(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: AppCard(
            onTap: () => RouterUtils.push(context, AppRoutes.statistics),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.insights_rounded),
              title: Text('学习统计'),
              subtitle: Text('正确率、活跃度与题型分布'),
              trailing: Icon(AppIcons.chevronRight),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppCard(
            onTap: () => RouterUtils.push(context, AppRoutes.profileHistory),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.history_rounded),
              title: Text('做题记录'),
              subtitle: Text('继续作答或回顾已完成题目'),
              trailing: Icon(AppIcons.chevronRight),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConcepts() {
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: refresh);
    }
    final concepts = _concepts;
    if (concepts == null) return const LoadingIndicator(message: '正在整理学习记录…');
    if (concepts.isEmpty) {
      return EmptyPlaceholder(
        icon: Icons.radar_outlined,
        message: '完成几道推荐题后，这里会显示知识点掌握状态',
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: concepts.take(12).map(_buildConceptCard).toList(),
    );
  }

  Widget _buildConceptCard(ConceptProgress concept) {
    final (label, tone) = switch (concept.status) {
      ConceptProgressStatus.insufficient => ('数据不足', AppStatusTone.neutral),
      ConceptProgressStatus.forming => ('正在形成', AppStatusTone.info),
      ConceptProgressStatus.needsReview => ('待巩固', AppStatusTone.warning),
      ConceptProgressStatus.stable => ('基本掌握', AppStatusTone.success),
    };
    return SizedBox(
      width: 240,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStatusBadge(label: label, tone: tone, compact: true),
            const SizedBox(height: AppSpacing.sm),
            Text(concept.name, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${concept.attemptCount} 次记录 · 正确率 ${(concept.accuracy * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
