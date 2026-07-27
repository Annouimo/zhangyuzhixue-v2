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

/// 我的收藏。
class ExamFavoritesPage extends StatefulWidget {
  const ExamFavoritesPage({super.key, this.examRepository});

  final ExamRepository? examRepository;

  @override
  State<ExamFavoritesPage> createState() => _ExamFavoritesPageState();
}

class _ExamFavoritesPageState extends State<ExamFavoritesPage> {
  late final ExamRepository _repo;
  final GlobalKey<AsyncLoadWidgetState<List<FavoriteExamSummary>>> _loadKey =
      GlobalKey();

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
        list[index] = FavoriteExamSummary(
          id: old.id,
          name: old.name,
          authorInfo: old.authorInfo,
          summary: old.summary,
          isLiked: !old.isLiked,
        );
      }
      return list;
    });
    await _repo.toggleLike(examId);
  }

  Future<void> _removeCollect(int examId) async {
    _loadKey.currentState?.optimisticUpdate((list) {
      list.removeWhere((item) => item.id == examId);
      return list;
    });
    await _repo.toggleCollect(examId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('我的收藏')),
    body: AsyncLoadWidget<List<FavoriteExamSummary>>(
      contentIsScrollable: true,
      key: _loadKey,
      onLoad: _repo.getFavorites,
      emptyWidget: EmptyPlaceholder(
        icon: Icons.bookmark_outline_rounded,
        message: '还没有收藏试卷，可以去发现页看看',
      ),
      builder: (ctx, list) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AuditLogger.instance.page('ExamFavoritesPage', {
            'total': list.length,
          });
        });
        return AppContentContainer(
          maxWidth: AppContentWidth.standard,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            itemCount: list.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (ctx, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: AppSectionHeader(
                    title: '已收藏 ${list.length} 份',
                    subtitle: '收藏的公开试卷会集中保存在这里。',
                  ),
                );
              }
              final exam = list[index - 1];
              return PaperCard(
                title: exam.name,
                subtitle: exam.authorInfo.isNotEmpty
                    ? exam.authorInfo
                    : exam.summary,
                onTap: () => RouterUtils.push(
                  context,
                  '${AppRoutes.examQuicklookOther}?id=${exam.id}',
                ),
                actions: [
                  ActionChipWidget(
                    icon: exam.isLiked ? AppIcons.likeSelected : AppIcons.like,
                    label: exam.isLiked ? '已点赞' : '点赞',
                    active: exam.isLiked,
                    onTap: () => _toggleLike(exam.id),
                  ),
                  ActionChipWidget(
                    icon: Icons.bookmark_remove_outlined,
                    label: '取消收藏',
                    onTap: () => _removeCollect(exam.id),
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
