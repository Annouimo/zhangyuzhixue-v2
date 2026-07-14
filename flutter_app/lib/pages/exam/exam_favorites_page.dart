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
import '../../../data/helpers/pdf_helper.dart';
import '../../data/debug/audit_logger.dart';

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
    final db = DatabaseProvider();
    _repo = widget.examRepository ?? ExamRepository(
      QuestionDao(db.assetsDb), ExamDao(db.appDb),
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
    } catch (e) { AuditLogger.instance.error('ExamFavoritesPage._load', e); if (!mounted) return; setState(() { _error = e.toString(); _loading = false; }); }
  }

  Future<void> _toggleLike(int examId) async {
    await _repo.toggleLike(examId);
    _load();
  }

  Future<void> _removeCollect(int examId) async {
    await _repo.toggleCollect(examId);
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('我的收藏')),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载收藏…');
    if (_error != null) return ErrorPlaceholder(message: _error!, onRetry: _load);
    if (_list == null || _list!.isEmpty) return const EmptyPlaceholder(icon: '⭐', message: '暂无收藏');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        itemCount: _list!.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final e = _list![i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => context.push('${AppRoutes.examQuicklookOther}?id=${e.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(e.authorInfo.isNotEmpty ? e.authorInfo : e.summary,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _actionChip('❤️', '点赞', () => _toggleLike(e.id)),
                      const SizedBox(width: 8),
                      _actionChip('🔖', '取消收藏', () => _removeCollect(e.id)),
                      const SizedBox(width: 8),
                      _actionChip('📥', 'PDF', () => PdfHelper.downloadPdf(sourceId: e.id, sourceType: 'paper', context: context)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.push('${AppRoutes.examQuicklookOther}?id=${e.id}'),
                        child: const Text('查看试卷', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _actionChip(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
