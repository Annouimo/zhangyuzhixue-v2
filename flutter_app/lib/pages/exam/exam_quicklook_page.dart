import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../widgets/md_latex_body.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_placeholder.dart';
import '../../widgets/exit_rating_popup.dart';
import '../../data/daos/exam_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/helpers/pdf_helper.dart';
import '../../domain/exam_repository.dart';
import '../../domain/question_repository.dart';
import '../../data/debug/audit_logger.dart';

/// 预览（自己的组卷）
class ExamQuicklookPage extends StatefulWidget {
  final int examId;
  final ExamRepository? examRepository;
  const ExamQuicklookPage({super.key, required this.examId, this.examRepository});

  @override
  State<ExamQuicklookPage> createState() => _ExamQuicklookPageState();
}

class _ExamQuicklookPageState extends State<ExamQuicklookPage> {
  late final ExamRepository _repo;
  ExamPreview? _preview;
  bool _loading = true; String? _error;
  final DateTime _entryTime = DateTime.now();

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
      final p = await _repo.getPreview(widget.examId);
      if (!mounted) return;
      setState(() { _preview = p; _loading = false; });
      AuditLogger.instance.page('ExamQuicklookPage', {'hasPreview': _preview != null});
    } catch (e) { AuditLogger.instance.error('ExamQuicklookPage._load', e); if (!mounted) return; setState(() { _error = e.toString(); _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shown = await showExitRatingIfNeeded(context, 'exam_quicklook', _entryTime);
        if (shown && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_preview?.name ?? '预览'),
          actions: [
            IconButton(icon: const Icon(Icons.assignment), tooltip: '快对答案',
              onPressed: () => context.push('/exam/answersheet?id=${widget.examId}')),
            IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: '下载PDF',
              onPressed: () => PdfHelper.downloadPdf(sourceId: widget.examId, sourceType: 'paper', context: context)),
            IconButton(icon: const Icon(Icons.share), tooltip: '公开/私密', onPressed: _togglePublic),
            IconButton(icon: const Icon(Icons.delete_outline), tooltip: '删除',
              onPressed: () async {
                await _repo.deleteExam(widget.examId);
                if (context.mounted) { context.pop(); }
              }),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Future<void> _togglePublic() async {
    await _repo.togglePublic(widget.examId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('公开状态已切换'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载预览…');
    if (_error != null) return ErrorPlaceholder(message: _error!, onRetry: _load);
    final p = _preview;
    if (p == null) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.all(AppSizes.baseSpacing),
      children: [
        Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('共 ${p.totalCount} 题 · 选择 ${p.choiceCount} 填空 ${p.fillCount} 解答 ${p.solutionCount}',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ...p.questions.map((q) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            child: InkWell(
              onTap: () async {
                final repo = QuestionRepository(
                  QuestionDao(DatabaseProvider().assetsDb),
                  ProgressDao(DatabaseProvider().appDb),
                );
                final attempts = await repo.getAttempts(q.questionId);
                final mode = attempts.isEmpty ? 'first' : 'review';
                final attemptId = attempts.isNotEmpty ? attempts.last.id.toString() : null;
                final page = SolveRouteHelper.pageName('choice');
                if (!context.mounted) return;
                context.push('/$page?id=${q.questionId}'
                    '${mode != 'first' ? '&mode=$mode' : ''}'
                    '${attemptId != null ? '&attemptId=$attemptId' : ''}');
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: MdLatexBody(q.title, fontSize: 14),
              ),
            ),
          ),
        )),
      ],
    );
  }
}
