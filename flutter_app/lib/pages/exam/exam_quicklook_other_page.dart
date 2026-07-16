import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../../../app_theme.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../data/helpers/pdf_helper.dart';
import '../../../domain/exam_repository.dart';
import '../../../widgets/shared/loading_indicator.dart';
import '../../../widgets/shared/error_placeholder.dart';
import '../../../widgets/shared/action_chip.dart';
import '../../data/debug/audit_logger.dart';
import '../../../data/debug/operation_log.dart';
import 'widgets/exam_question_card.dart';

/// 预览（他人的组卷）
class ExamQuicklookOtherPage extends StatefulWidget {
  final int examId;
  final ExamRepository? examRepository;
  const ExamQuicklookOtherPage({super.key, required this.examId, this.examRepository});

  @override
  State<ExamQuicklookOtherPage> createState() => _ExamQuicklookOtherPageState();
}

class _ExamQuicklookOtherPageState extends State<ExamQuicklookOtherPage> {
  late final ExamRepository _repo;
  ExamPreviewOther? _preview;
  bool _loading = true; String? _error;
  bool _liked = false, _collected = false;

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
      final p = await _repo.getPreviewOther(widget.examId);
      if (!mounted) return;
      setState(() { _preview = p; _liked = p.isLiked; _collected = p.isCollected; _loading = false; });
      AuditLogger.instance.page('ExamQuicklookOtherPage', {'title': _preview?.name});
    } catch (e) { OperationLog.instance.error('exam_quicklook_other_page_load', e);  AuditLogger.instance.error('ExamQuicklookOtherPage._load', e); if (!mounted) return; setState(() { _error = '加载失败，请稍后重试'; _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_preview?.name ?? '预览'),
      actions: [
            IconButton(icon: const Icon(Icons.assignment), tooltip: '快对答案',
              onPressed: () => context.push('${AppRoutes.answerSheet}?id=${widget.examId}')),
            IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: '下载PDF',
          onPressed: () => PdfHelper.downloadPdf(sourceId: widget.examId, sourceType: 'paper', context: context)),
      ],
    ),
    body: _buildBody(),
  );

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
        const SizedBox(height: 12),
        Row(children: [
          ActionChipWidget(icon: Icons.thumb_up_alt_outlined, label: '${p.likeCount}', active: _liked, onTap: _toggleLike),
          const SizedBox(width: 8),
          ActionChipWidget(icon: Icons.bookmark_border, label: '${p.collectCount}', active: _collected, onTap: _toggleCollect),
        ]),
        const SizedBox(height: 16),
        ...p.questions.map((q) => ExamQuestionCard(
          questionId: q.questionId,
          title: q.title,
          questionType: q.questionType,
        )),
      ],
    );
  }

  Future<void> _toggleLike() async {
    await _repo.toggleLike(widget.examId);
    setState(() {
      _liked = !_liked;
      _preview = _preview!.copyWith(likeCount: _preview!.likeCount + (_liked ? 1 : -1));
    });
  }

  Future<void> _toggleCollect() async {
    await _repo.toggleCollect(widget.examId);
    setState(() {
      _collected = !_collected;
      _preview = _preview!.copyWith(collectCount: _preview!.collectCount + (_collected ? 1 : -1));
    });
  }
}

