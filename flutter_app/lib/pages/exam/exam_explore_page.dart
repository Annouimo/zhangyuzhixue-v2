import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/exam_repository.dart';
import '../../widgets/shared/async_load_widget.dart';
import '../../widgets/question_search_field.dart';
import '../router.dart';
import 'widgets/paper_card.dart';

/// 发现公开组卷。
class ExamExplorePage extends StatefulWidget {
  const ExamExplorePage({
    super.key,
    this.examRepository,
    this.embedded = false,
  });

  final ExamRepository? examRepository;
  final bool embedded;

  @override
  State<ExamExplorePage> createState() => _ExamExplorePageState();
}

class _ExamExplorePageState extends State<ExamExplorePage> {
  late final ExamRepository _repo;
  final GlobalKey<AsyncLoadWidgetState<List<ExploreExamSummary>>> _loadKey =
      GlobalKey();
  final _searchController = TextEditingController();
  String _sortBy = 'diff';

  static const _sortOptions = [
    ('latest', '最新发布'),
    ('collectCount', '收藏最多'),
    ('likeCount', '点赞最多'),
    ('diff', '综合热度'),
  ];

  String get _currentSortLabel => _sortOptions
      .firstWhere((option) => option.$1 == _sortBy)
      .$2;

  void _cycleSort() {
    final currentIndex = _sortOptions.indexWhere(
      (option) => option.$1 == _sortBy,
    );
    setState(() {
      _sortBy = _sortOptions[(currentIndex + 1) % _sortOptions.length].$1;
    });
  }

  @override
  void initState() {
    super.initState();
    _repo =
        widget.examRepository ??
        ExamRepository(
          QuestionDao(DatabaseProvider()),
          ExamDao(DatabaseProvider()),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExploreExamSummary> _sorted(List<ExploreExamSummary> source) {
    final query = _searchController.text.trim().toLowerCase();
    final sorted = source
        .where(
          (paper) =>
              query.isEmpty ||
              paper.name.toLowerCase().contains(query) ||
              paper.authorInfo.toLowerCase().contains(query) ||
              paper.summary.toLowerCase().contains(query),
        )
        .toList(growable: false);
    switch (_sortBy) {
      case 'collectCount':
        sorted.sort((a, b) => b.collectCount.compareTo(a.collectCount));
        break;
      case 'likeCount':
        sorted.sort((a, b) => b.likeCount.compareTo(a.likeCount));
        break;
      case 'diff':
        sorted.sort(
          (a, b) => (b.likeCount + b.collectCount).compareTo(
            a.likeCount + a.collectCount,
          ),
        );
        break;
      default:
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final body = AsyncLoadWidget<List<ExploreExamSummary>>(
      key: _loadKey,
      onLoad: _repo.getExploreList,
      contentIsScrollable: true,
      emptyWidget: EmptyPlaceholder(
        icon: Icons.explore_outlined,
        message: '暂时没有公开试卷，可以先创建并分享一份',
      ),
      builder: (ctx, list) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AuditLogger.instance.page('ExamExplorePage', {
            'totalPapers': list.length,
          });
        });
        final sorted = _sorted(list);
        return AppContentContainer(
          maxWidth: AppContentWidth.standard,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            itemCount: sorted.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (ctx, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      QuestionSearchField(
                        controller: _searchController,
                        hintText: '搜索试卷名称、内容或作者',
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => setState(() {}),
                        trailing: TextButton(
                          onPressed: _cycleSort,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            textStyle: Theme.of(ctx).textTheme.bodyMedium,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_currentSortLabel),
                              const SizedBox(width: AppSpacing.xs),
                              const Icon(Icons.swap_vert_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final exam = sorted[index - 1];
              final subtitle = exam.summary.isNotEmpty
                  ? exam.summary
                  : '${exam.likeCount} 赞 · ${exam.collectCount} 收藏';
              return PaperCard(
                title: exam.name,
                subtitle: exam.authorInfo.isNotEmpty
                    ? '${exam.authorInfo} · $subtitle'
                    : subtitle,
                onTap: () async {
                  await RouterUtils.push(
                    context,
                    '${AppRoutes.examQuicklookOther}?id=${exam.id}',
                  );
                  _loadKey.currentState?.refresh();
                },
              );
            },
          ),
        );
      },
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('发现试卷')),
      body: body,
    );
  }
}
