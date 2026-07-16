import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../../../app_theme.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/exam_repository.dart';
import '../../../widgets/shared/loading_indicator.dart';
import '../../../widgets/shared/empty_placeholder.dart';
import '../../../widgets/shared/error_placeholder.dart';
import '../../../widgets/shared/action_chip.dart';
import '../../../data/helpers/pdf_helper.dart';
import 'widgets/paper_card.dart';
import '../../data/debug/audit_logger.dart';
import '../../data/debug/operation_log.dart';
import '../../../data/debug/operation_log.dart';

/// 我的收藏 — 匹配 HTML 原型 paper_favorites.html
class ExamFavoritesPage extends StatefulWidget {
  final ExamRepository? examRepository;
  const ExamFavoritesPage({super.key, this.examRepository});

  @override
  State<ExamFavoritesPage> createState() => _ExamFavoritesPageState();
}

class _ExamFavoritesPageState extends State<ExamFavoritesPage> {
  late final ExamRepository _repo;
  List<FavoriteExamSummary>? _list;
  bool _loading = true; String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget.examRepository ?? ExamRepository(
      QuestionDao(DatabaseProvider()), ExamDao(DatabaseProvider()),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final l = await _repo.getFavorites();
      if (!mounted) return;
      setState(() { _list = l; _loading = false; });
      AuditLogger.instance.page('ExamFavoritesPage', {'total': _list?.length});
    } catch (e) { OperationLog.instance.error('exam_favorites_page_load', e);  AuditLogger.instance.error('ExamFavoritesPage._load', e); if (!mounted) return; setState(() { _error = '加载失败，请稍后重试'; _loading = false; }); }
  }

  Future<void> _toggleLike(int examId) async {
    // 乐观更新
    if (_list != null) {
      setState(() {
        final idx = _list!.indexWhere((e) => e.id == examId);
        if (idx >= 0) {
          final old = _list![idx];
          _list![idx] = FavoriteExamSummary(
            id: old.id, name: old.name, authorInfo: old.authorInfo,
            summary: old.summary, isLiked: !old.isLiked,
          );
        }
      });
    }
    await _repo.toggleLike(examId);
  }

  Future<void> _removeCollect(int examId) async {
    // 乐观删除：直接从列表移除
    if (_list != null) {
      setState(() => _list!.removeWhere((e) => e.id == examId));
    }
    await _repo.toggleCollect(examId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('我的收藏')),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载收藏…');
    if (_error != null) return ErrorPlaceholder(message: _error!, onRetry: _load);
    if (_list == null || _list!.isEmpty) return const EmptyPlaceholder(icon: Icons.star, message: '你还没有收藏任何试卷，发现好试卷可以收藏哦');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        itemCount: _list!.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final e = _list![i];
          return PaperCard(
            title: e.name,
            subtitle: e.authorInfo.isNotEmpty ? e.authorInfo : e.summary,
            onTap: () => context.push('${AppRoutes.examQuicklookOther}?id=${e.id}'),
            actions: [
              ActionChipWidget(icon: Icons.favorite, iconColor: Colors.red, label: '点赞', onTap: () => _toggleLike(e.id)),
              const SizedBox(width: 8),
              ActionChipWidget(icon: Icons.bookmark, label: '取消收藏', onTap: () => _removeCollect(e.id)),
              const SizedBox(width: 8),
              ActionChipWidget(icon: Icons.file_download, label: 'PDF', onTap: () => PdfHelper.downloadPdf(sourceId: e.id, sourceType: 'paper', context: context)),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('${AppRoutes.examQuicklookOther}?id=${e.id}'),
                child: const Text('查看试卷', style: TextStyle(fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );
  }
}


