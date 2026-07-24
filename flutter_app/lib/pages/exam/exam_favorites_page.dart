import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import 'package:shared/theme/app_theme.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/exam_repository.dart';
import 'package:shared/widgets/empty_placeholder.dart';
import '../../../widgets/shared/action_chip.dart';
import '../../../widgets/shared/async_load_widget.dart';
import '../../../data/helpers/pdf_helper.dart';
import 'widgets/paper_card.dart';
import 'package:shared/debug/audit_logger.dart';


/// 我的收藏 — 匹配 HTML 原型 paper_favorites.html
class ExamFavoritesPage extends StatefulWidget {
  final ExamRepository? examRepository;
  ExamFavoritesPage({super.key, this.examRepository});

  @override
  State<ExamFavoritesPage> createState() => _ExamFavoritesPageState();
}

class _ExamFavoritesPageState extends State<ExamFavoritesPage> {
  late final ExamRepository _repo;
  final GlobalKey<AsyncLoadWidgetState<List<FavoriteExamSummary>>> _loadKey = GlobalKey();

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
        list[idx] = FavoriteExamSummary(
          id: old.id, name: old.name, authorInfo: old.authorInfo,
          summary: old.summary, isLiked: !old.isLiked,
        );
      }
      return list;
    });
    await _repo.toggleLike(examId);
  }

  Future<void> _removeCollect(int examId) async {
    // 乐观删除
    _loadKey.currentState?.optimisticUpdate((list) {
      list.removeWhere((e) => e.id == examId);
      return list;
    });
    await _repo.toggleCollect(examId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('我的收藏')),
    body: AsyncLoadWidget<List<FavoriteExamSummary>>(
      key: _loadKey,
      onLoad: () => _repo.getFavorites(),
      emptyWidget: EmptyPlaceholder(
        icon: Icons.star,
        message: '你还没有收藏任何试卷，发现好试卷可以收藏哦',
      ),
      builder: (ctx, list) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AuditLogger.instance.page('ExamFavoritesPage', {'total': list.length});
        });
        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.baseSpacing),
          itemCount: list.length,
          separatorBuilder: (_, _) => SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final e = list[i];
            return PaperCard(
              title: e.name,
              subtitle: e.authorInfo.isNotEmpty ? e.authorInfo : e.summary,
              onTap: () => context.push('${AppRoutes.examQuicklookOther}?id=${e.id}'),
              actions: [
                ActionChipWidget(icon: Icons.favorite, iconColor: context.colors.primary, label: '点赞', onTap: () => _toggleLike(e.id)),
                SizedBox(width: 8),
                ActionChipWidget(icon: Icons.bookmark, label: '取消收藏', onTap: () => _removeCollect(e.id)),
                SizedBox(width: 8),
                ActionChipWidget(icon: Icons.file_download, label: 'PDF', onTap: () => PdfHelper.downloadPdf(sourceId: e.id, sourceType: 'paper', context: context)),
                Spacer(),
                TextButton(
                  onPressed: () => context.push('${AppRoutes.examQuicklookOther}?id=${e.id}'),
                  child: Text('查看试卷', style: TextStyle(fontSize: 12)),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}
