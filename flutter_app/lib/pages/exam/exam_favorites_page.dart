import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/exam_repository.dart';
import '../../widgets/shared/async_load_widget.dart';
import '../router.dart';
import 'widgets/paper_card.dart';

/// 我的收藏。
class ExamFavoritesPage extends StatefulWidget {
  const ExamFavoritesPage({
    super.key,
    this.examRepository,
    this.embedded = false,
  });

  final ExamRepository? examRepository;
  final bool embedded;

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

  Future<void> _removeCollect(FavoriteExamSummary exam) async {
    _loadKey.currentState?.optimisticUpdate((list) {
      list.removeWhere((item) => item.id == exam.id);
      return list;
    });
    await _repo.toggleCollect(exam.id);
    if (!mounted) return;
    AppToast.info(
      context,
      '已取消收藏',
      actionLabel: '撤销',
      onAction: () async {
        await _repo.toggleCollect(exam.id);
        _loadKey.currentState?.refresh();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = AsyncLoadWidget<List<FavoriteExamSummary>>(
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
                trailingWidget: IconButton(
                  tooltip: '取消收藏',
                  icon: Icon(
                    Icons.bookmark_rounded,
                    color: context.colors.primary,
                  ),
                  onPressed: () => _removeCollect(exam),
                ),
                onTap: () => RouterUtils.push(
                  context,
                  '${AppRoutes.examQuicklookOther}?id=${exam.id}',
                ),
              );
            },
          ),
        );
      },
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('收藏')),
      body: body,
    );
  }
}
