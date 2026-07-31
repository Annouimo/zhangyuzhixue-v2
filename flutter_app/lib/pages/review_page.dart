import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../data/daos/progress_dao.dart';
import '../data/daos/question_dao.dart';
import '../data/database/database_provider.dart';
import '../domain/review_repository.dart';

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
      appBar: AppBar(title: const Text('学习复盘')),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: AppContentContainer(
          maxWidth: AppContentWidth.dashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              _buildSummary(),
              const SizedBox(height: AppSpacing.md),
              _buildConcepts(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final needsReview = _concepts
        ?.where(
          (concept) => concept.status == ConceptProgressStatus.needsReview,
        )
        .length;
    return AppSectionHeader(
      title: needsReview == null ? '学习反馈' : '$needsReview 个知识点需要复习',
      subtitle: '掌握状态会随作答结果自动更新。',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 600
            ? 1
            : constraints.maxWidth < 900
            ? 2
            : constraints.maxWidth < 1200
            ? 3
            : 4;
        const gap = AppSpacing.sm;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: concepts
              .take(12)
              .map(
                (concept) => SizedBox(
                  width: width,
                  child: _buildConceptCard(concept, compact: columns == 1),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildConceptCard(ConceptProgress concept, {required bool compact}) {
    final (label, tone) = switch (concept.status) {
      ConceptProgressStatus.insufficient => ('数据不足', AppStatusTone.neutral),
      ConceptProgressStatus.forming => ('正在形成', AppStatusTone.info),
      ConceptProgressStatus.needsReview => ('待巩固', AppStatusTone.warning),
      ConceptProgressStatus.stable => ('基本掌握', AppStatusTone.success),
    };
    return AppSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  concept.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppStatusBadge(label: label, tone: tone, compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${concept.attemptCount} 次记录 · 正确率 ${(concept.accuracy * 100).round()}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
