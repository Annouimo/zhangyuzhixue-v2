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
    final concepts = _reviewConcepts;
    return AppSection(
      title: _concepts == null ? '学习反馈' : '${concepts.length} 个知识点需要复习',
      description: _concepts == null || concepts.isEmpty ? null : '按复习优先级排列',
      trailing: FilledButton(
        onPressed: concepts.isEmpty ? null : _startReview,
        child: const Text('开始复习'),
      ),
      child: const SizedBox.shrink(),
    );
  }

  List<ConceptProgress> get _reviewConcepts {
    final concepts = (_concepts ?? const <ConceptProgress>[])
        .where((concept) => concept.status == ConceptProgressStatus.needsReview)
        .toList();
    concepts.sort((a, b) {
      final accuracy = a.accuracy.compareTo(b.accuracy);
      return accuracy != 0
          ? accuracy
          : b.attemptCount.compareTo(a.attemptCount);
    });
    return concepts;
  }

  void _startReview() => RouterUtils.push(context, AppRoutes.recommend);

  Widget _buildConcepts() {
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: refresh);
    }
    if (_concepts == null) {
      return const LoadingIndicator(message: '正在整理学习记录…');
    }
    final concepts = _reviewConcepts;
    if (concepts.isEmpty) {
      return EmptyPlaceholder(
        icon: Icons.task_alt_rounded,
        message: _concepts!.isEmpty ? '完成几道推荐题后，这里会生成复习任务' : '当前没有需要复习的知识点',
      );
    }
    return Column(
      children: [
        for (var index = 0; index < concepts.length; index++) ...[
          _ReviewTaskRow(concept: concepts[index], onTap: _startReview),
          if (index < concepts.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Divider(height: 1),
            ),
        ],
      ],
    );
  }
}

class _ReviewTaskRow extends StatelessWidget {
  const _ReviewTaskRow({required this.concept, required this.onTap});

  final ConceptProgress concept;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accuracy = (concept.accuracy * 100).round();
    final accuracyColor = accuracy < 30
        ? colors.warning
        : accuracy <= 60
        ? colors.textPrimary
        : colors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return colors.primary.withValues(alpha: 0.06);
          }
          return null;
        }),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        concept.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${concept.attemptCount} 次记录',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$accuracy%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: accuracyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
