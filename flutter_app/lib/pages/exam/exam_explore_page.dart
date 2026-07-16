import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../../../app_theme.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/exam_repository.dart';
import '../../../widgets/shared/empty_placeholder.dart';
import '../../../widgets/shared/action_chip.dart';
import '../../../widgets/shared/async_load_widget.dart';
import '../../../data/helpers/pdf_helper.dart';
import 'widgets/paper_card.dart';
import '../../data/debug/audit_logger.dart';


/// 发现组卷 — 匹配 HTML 原型 paper_explore.html
class ExamExplorePage extends StatefulWidget {
  final ExamRepository? examRepository;
  const ExamExplorePage({super.key, this.examRepository});

  @override
  State<ExamExplorePage> createState() => _ExamExplorePageState();
}

class _ExamExplorePageState extends State<ExamExplorePage> {
  late final ExamRepository _repo;
  final GlobalKey<AsyncLoadWidgetState<List<ExploreExamSummary>>> _loadKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _repo = widget.examRepository ?? ExamRepository(
      QuestionDao(DatabaseProvider()), ExamDao(DatabaseProvider()),
    );
  }

  Future<void> _toggleLike(int examId) async {
    // 乐观更新
    _loadKey.currentState?.optimisticUpdate((list) {
      final idx = list.indexWhere((e) => e.id == examId);
      if (idx >= 0) {
        final old = list[idx];
        list[idx] = ExploreExamSummary(
          id: old.id, name: old.name, authorInfo: old.authorInfo,
          summary: old.summary,
          likeCount: old.isLiked ? old.likeCount - 1 : old.likeCount + 1,
          collectCount: old.collectCount, createdAt: old.createdAt,
          isLiked: !old.isLiked, isCollected: old.isCollected,
        );
      }
      return list;
    });
    await _repo.toggleLike(examId);
  }

  Future<void> _toggleCollect(int examId) async {
    // 乐观更新
    _loadKey.currentState?.optimisticUpdate((list) {
      final idx = list.indexWhere((e) => e.id == examId);
      if (idx >= 0) {
        final old = list[idx];
        list[idx] = ExploreExamSummary(
          id: old.id, name: old.name, authorInfo: old.authorInfo,
          summary: old.summary,
          likeCount: old.likeCount,
          collectCount: old.isCollected ? old.collectCount - 1 : old.collectCount + 1,
          createdAt: old.createdAt,
          isLiked: old.isLiked, isCollected: !old.isCollected,
        );
      }
      return list;
    });
    await _repo.toggleCollect(examId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('发现组卷')),
    body: Column(
      children: [
        // 排序栏（仅视觉展示，排序逻辑待后续实现）
        Container(
          width: double.infinity, color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['最新', '热度', '点赞', '收藏'].map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  selected: false,
                  onSelected: (_) {},
                  selectedColor: AppColors.primaryLight,
                  side: BorderSide.none,
                ),
              )).toList(),
            ),
          ),
        ),
        Expanded(
          child: AsyncLoadWidget<List<ExploreExamSummary>>(
            key: _loadKey,
            onLoad: () => _repo.getExploreList(),
            emptyWidget: const EmptyPlaceholder(
              icon: Icons.search,
              message: '还没有人公开分享试卷，去首页试试快速练习吧',
            ),
            builder: (ctx, list) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AuditLogger.instance.page('ExamExplorePage', {'totalPapers': list.length});
              });
              return ListView.separated(
                padding: const EdgeInsets.all(AppSizes.baseSpacing),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final e = list[i];
                  return PaperCard(
                    title: e.name,
                    subtitle: e.summary.isNotEmpty ? e.summary : '${e.likeCount} 赞 · ${e.collectCount} 收藏',
                    onTap: () => context.push('${AppRoutes.examQuicklookOther}?id=${e.id}'),
                    actions: [
                      ActionChipWidget(
                        icon: e.isLiked ? Icons.favorite : Icons.favorite_border,
                        iconColor: e.isLiked ? Colors.red : null,
                        label: '${e.likeCount}',
                        onTap: () => _toggleLike(e.id),
                      ),
                      const SizedBox(width: 8),
                      ActionChipWidget(
                        icon: e.isCollected ? Icons.bookmark : Icons.label_outline,
                        label: '${e.collectCount}',
                        onTap: () => _toggleCollect(e.id),
                      ),
                      const SizedBox(width: 8),
                      ActionChipWidget(
                        icon: Icons.file_download,
                        label: 'PDF',
                        onTap: () => PdfHelper.downloadPdf(sourceId: e.id, sourceType: 'paper', context: context),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.push('${AppRoutes.examQuicklookOther}?id=${e.id}'),
                        child: const Text('查看试卷', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
