import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/helpers/pdf_helper.dart';
import '../../domain/exam_repository.dart';
import '../../widgets/shared/action_chip.dart';
import '../router.dart';
import 'widgets/exam_question_card.dart';

/// 预览其他用户公开的组卷。
class ExamQuicklookOtherPage extends StatefulWidget {
  const ExamQuicklookOtherPage({
    super.key,
    required this.examId,
    this.examRepository,
  });

  final int examId;
  final ExamRepository? examRepository;

  @override
  State<ExamQuicklookOtherPage> createState() => _ExamQuicklookOtherPageState();
}

class _ExamQuicklookOtherPageState extends State<ExamQuicklookOtherPage> {
  late final ExamRepository _repo;
  ExamPreviewOther? _preview;
  bool _loading = true;
  String? _error;
  bool _liked = false;
  bool _collected = false;

  @override
  void initState() {
    super.initState();
    _repo =
        widget.examRepository ??
        ExamRepository(
          QuestionDao(DatabaseProvider()),
          ExamDao(DatabaseProvider()),
        );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final preview = await _repo.getPreviewOther(widget.examId);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _liked = preview.isLiked;
        _collected = preview.isCollected;
        _loading = false;
      });
      AuditLogger.instance.page('ExamQuicklookOtherPage', {
        'title': _preview?.name,
      });
    } catch (error) {
      OperationLog.instance.error('exam_quicklook_other_page_load', error);
      AuditLogger.instance.error('ExamQuicklookOtherPage._load', error);
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_preview?.name ?? '试卷预览'),
      actions: [
        IconButton(
          icon: const Icon(Icons.fact_check_outlined),
          tooltip: '快速对答案',
          onPressed: () => RouterUtils.push(
            context,
            '${AppRoutes.answerSheet}?id=${widget.examId}',
          ),
        ),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined),
          tooltip: '下载 PDF',
          onPressed: () => PdfHelper.downloadPdf(
            sourceId: widget.examId,
            sourceType: 'paper',
            context: context,
          ),
        ),
      ],
    ),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载试卷预览…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    final preview = _preview;
    if (preview == null) return const SizedBox.shrink();

    return AppContentContainer(
      maxWidth: AppContentWidth.reading,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              ActionChipWidget(
                icon: _liked ? AppIcons.likeSelected : AppIcons.like,
                label: '${preview.likeCount}',
                active: _liked,
                onTap: _toggleLike,
              ),
              ActionChipWidget(
                icon: _collected
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                label: '${preview.collectCount}',
                active: _collected,
                onTap: _toggleCollect,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppSectionHeader(
            title: '试卷题目',
            subtitle: '共 ${preview.questions.length} 题，点击可进入练习。',
          ),
          const SizedBox(height: AppSpacing.md),
          ...preview.questions.map(
            (question) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ExamQuestionCard(
                questionId: question.questionId,
                title: question.title,
                questionType: question.questionType,
                sequence: preview.questions
                    .map((item) => item.questionId)
                    .toList(growable: false),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _toggleLike() async {
    await _repo.toggleLike(widget.examId);
    if (!mounted || _preview == null) return;
    setState(() {
      _liked = !_liked;
      _preview = _preview!.copyWith(
        likeCount: _preview!.likeCount + (_liked ? 1 : -1),
      );
    });
  }

  Future<void> _toggleCollect() async {
    await _repo.toggleCollect(widget.examId);
    if (!mounted || _preview == null) return;
    setState(() {
      _collected = !_collected;
      _preview = _preview!.copyWith(
        collectCount: _preview!.collectCount + (_collected ? 1 : -1),
      );
    });
  }
}
