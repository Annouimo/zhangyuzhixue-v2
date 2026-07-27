import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/helpers/pdf_helper.dart';
import '../../domain/exam_repository.dart';
import '../../widgets/shared/action_chip.dart';
import '../../widgets/shared/async_load_widget.dart';
import '../router.dart';
import 'widgets/paper_card.dart';

/// 发现公开组卷。
class ExamExplorePage extends StatefulWidget {
  const ExamExplorePage({super.key, this.examRepository});

  final ExamRepository? examRepository;

  @override
  State<ExamExplorePage> createState() => _ExamExplorePageState();
}

class _ExamExplorePageState extends State<ExamExplorePage> {
  late final ExamRepository _repo;
  final GlobalKey<AsyncLoadWidgetState<List<ExploreExamSummary>>> _loadKey =
      GlobalKey();
  String _sortBy = 'latest';

  static const _sortOptions = [
    ('latest', '最新发布'),
    ('collectCount', '收藏最多'),
    ('likeCount', '点赞最多'),
    ('diff', '综合热度'),
  ];

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

  Future<void> _toggleLike(int examId) async {
    _loadKey.currentState?.optimisticUpdate((list) {
      final index = list.indexWhere((item) => item.id == examId);
      if (index >= 0) {
        final old = list[index];
        list[index] = ExploreExamSummary(
          id: old.id,
          name: old.name,
          authorInfo: old.authorInfo,
          summary: old.summary,
          likeCount: old.isLiked ? old.likeCount - 1 : old.likeCount + 1,
          collectCount: old.collectCount,
          createdAt: old.createdAt,
          isLiked: !old.isLiked,
          isCollected: old.isCollected,
        );
      }
      return list;
    });
    await _repo.toggleLike(examId);
  }

  Future<void> _toggleCollect(int examId) async {
    _loadKey.currentState?.optimisticUpdate((list) {
      final index = list.indexWhere((item) => item.id == examId);
      if (index >= 0) {
        final old = list[index];
        list[index] = ExploreExamSummary(
          id: old.id,
          name: old.name,
          authorInfo: old.authorInfo,
          summary: old.summary,
          likeCount: old.likeCount,
          collectCount: old.isCollected
              ? old.collectCount - 1
              : old.collectCount + 1,
          createdAt: old.createdAt,
          isLiked: old.isLiked,
          isCollected: !old.isCollected,
        );
      }
      return list;
    });
    await _repo.toggleCollect(examId);
  }

  List<ExploreExamSummary> _sorted(List<ExploreExamSummary> source) {
    final sorted = List<ExploreExamSummary>.from(source);
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('发现组卷')),
    body: AsyncLoadWidget<List<ExploreExamSummary>>(
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
                      AppSectionHeader(
                        title: '公开试卷',
                        subtitle: '发现其他同学分享的内容，收藏后可以随时查看。',
                        action: IconButton(
                          tooltip: '刷新',
                          onPressed: () => _loadKey.currentState?.refresh(),
                          icon: const Icon(AppIcons.refresh),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<String>(
                          segments: _sortOptions
                              .map(
                                (option) => ButtonSegment<String>(
                                  value: option.$1,
                                  label: Text(option.$2),
                                ),
                              )
                              .toList(),
                          selected: {_sortBy},
                          showSelectedIcon: false,
                          onSelectionChanged: (value) {
                            setState(() => _sortBy = value.first);
                          },
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
                onTap: () => RouterUtils.push(
                  context,
                  '${AppRoutes.examQuicklookOther}?id=${exam.id}',
                ),
                actions: [
                  ActionChipWidget(
                    icon: exam.isLiked ? AppIcons.likeSelected : AppIcons.like,
                    label: '${exam.likeCount}',
                    active: exam.isLiked,
                    onTap: () => _toggleLike(exam.id),
                  ),
                  ActionChipWidget(
                    icon: exam.isCollected
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    label: '${exam.collectCount}',
                    active: exam.isCollected,
                    onTap: () => _toggleCollect(exam.id),
                  ),
                  ActionChipWidget(
                    icon: Icons.picture_as_pdf_outlined,
                    label: '下载 PDF',
                    onTap: () => PdfHelper.downloadPdf(
                      sourceId: exam.id,
                      sourceType: 'paper',
                      context: context,
                    ),
                  ),
                  ActionChipWidget(
                    icon: Icons.visibility_outlined,
                    label: '查看试卷',
                    onTap: () => RouterUtils.push(
                      context,
                      '${AppRoutes.examQuicklookOther}?id=${exam.id}',
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    ),
  );
}
