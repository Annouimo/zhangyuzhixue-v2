import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

/// 我的组卷列表 — 匹配 HTML 原型 paper_history.html
class ExamHistoryPage extends StatefulWidget {
  final ExamRepository? examRepository;
  const ExamHistoryPage({super.key, this.examRepository});

  @override
  State<ExamHistoryPage> createState() => _ExamHistoryPageState();
}

class _ExamHistoryPageState extends State<ExamHistoryPage> {
  late final ExamRepository _repo;
  List<ExamSummary>? _list;
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
      final l = await _repo.getMyExams();
      if (!mounted) return;
      setState(() { _list = l; _loading = false; });
      AuditLogger.instance.page('ExamHistoryPage', {'total': _list?.length});
    } catch (e) { AuditLogger.instance.error('ExamHistoryPage._load', e); if (!mounted) return; setState(() { _error = e.toString(); _loading = false; }); }
  }

  Future<void> _deleteExam(int examId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此组卷吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      await _repo.deleteExam(examId);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('我的组卷')),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载组卷…');
    if (_error != null) return ErrorPlaceholder(message: _error!, onRetry: _load);
    if (_list == null || _list!.isEmpty) return const EmptyPlaceholder(icon: '📝', message: '暂无组卷');
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
                    onTap: () => context.push('/exam/quicklook?id=${e.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('创建于 ${e.createdAt}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // 公开/私密开关
                      IconButton(
                        icon: Icon(e.isPublic ? Icons.public : Icons.lock, size: 18),
                        tooltip: e.isPublic ? '公开' : '私密',
                        onPressed: () async {
                          await _repo.togglePublic(e.id);
                          _load();
                        },
                      ),
                      _actionChip('📥', 'PDF', () => PdfHelper.downloadPdf(sourceId: e.id, sourceType: 'paper')),
                      const SizedBox(width: 4),
                      _actionChip('✅', '答案', () => context.push('/exam/answersheet?id=${e.id}')),
                      const SizedBox(width: 4),
                      _actionChip('🗑️', '删除', () => _deleteExam(e.id)),
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
            Text(icon, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
