import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import '../../widgets/exit_rating_popup.dart';
import 'widgets/exam_question_card.dart';
import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/helpers/pdf_helper.dart';
import '../../domain/exam_repository.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

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
    _repo = widget.examRepository ?? ExamRepository(
      QuestionDao(DatabaseProvider()), ExamDao(DatabaseProvider()),
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
    } catch (e) { OperationLog.instance.error('exam_quicklook_page_load', e);  AuditLogger.instance.error('ExamQuicklookPage._load', e); if (!mounted) return; setState(() { _error = '加载失败，请稍后重试'; _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        await showExitRatingIfNeeded(context, 'exam_quicklook', _entryTime);
        if (context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_preview?.name ?? '预览'),
          actions: [
            IconButton(icon: const Icon(Icons.assignment), tooltip: '快对答案',
              onPressed: () => RouterUtils.push(context,'${AppRoutes.answerSheet}?id=${widget.examId}')),
            IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: '下载PDF',
              onPressed: () => PdfHelper.downloadPdf(sourceId: widget.examId, sourceType: 'paper', context: context)),
            IconButton(
              icon: Icon(_preview?.isPublic == true ? Icons.public : Icons.lock),
              tooltip: _preview?.isPublic == true ? '公开' : '私密',
              onPressed: _togglePublic
            ),
            IconButton(icon: const Icon(Icons.delete_outline), tooltip: '删除',
              onPressed: () async {
                await _repo.deleteExam(widget.examId);
                if (context.mounted) { safePop(context); }
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
      _load();
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
        if (p.authorInfo.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(p.authorInfo, style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
          ),
        const SizedBox(height: 4),
        Text('共 ${p.totalCount} 题 · 选择 ${p.choiceCount} 填空 ${p.fillCount} 解答 ${p.solutionCount}',
          style: TextStyle(fontSize: 14, color: context.colors.textSecondary)),
        const SizedBox(height: 16),
        ...p.questions.map((q) => ExamQuestionCard(
          questionId: q.questionId,
          title: q.title,
          questionType: q.questionType,
        )),
      ],
    );
  }
}

