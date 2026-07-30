import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/pop_back_guard.dart';
import 'package:shared/shared.dart';

import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/helpers/pdf_helper.dart';
import '../../domain/exam_repository.dart';
import '../../domain/paper_content.dart';
import '../../domain/paper_folder_repository.dart';
import '../../domain/question_repository.dart';
import '../router.dart';
import 'widgets/exam_question_card.dart';
import 'widgets/paper_action_bar.dart';
import 'exam_session_timer.dart';

/// 预览自己创建的组卷。
class ExamQuicklookPage extends StatefulWidget {
  const ExamQuicklookPage({
    super.key,
    this.examId,
    this.virtualPaper,
    this.examRepository,
  }) : assert(examId != null || virtualPaper != null);

  final int? examId;
  final VirtualPaperRef? virtualPaper;
  final ExamRepository? examRepository;

  @override
  State<ExamQuicklookPage> createState() => _ExamQuicklookPageState();
}

class _ExamQuicklookPageState extends State<ExamQuicklookPage> {
  late final ExamRepository _repo;
  final PopBackGuard _popGuard = PopBackGuard();
  PaperContent? _paper;
  bool _loading = true;
  String? _error;

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
      final paper = await _loadPaper();
      if (!mounted) return;
      setState(() {
        _paper = paper;
        _loading = false;
      });
      AuditLogger.instance.page('ExamQuicklookPage', {
        'hasPreview': _paper != null,
      });
    } catch (error) {
      OperationLog.instance.error('exam_quicklook_page_load', error);
      AuditLogger.instance.error('ExamQuicklookPage._load', error);
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  Future<PaperContent> _loadPaper() async {
    final virtual = widget.virtualPaper;
    if (virtual != null) {
      final rows = await QuestionDao(DatabaseProvider())
          .getVirtualPaperQuestions(
            year: virtual.year,
            examType: virtual.examType,
            region: virtual.region,
          );
      return PaperContent(
        ref: virtual,
        title: virtual.title,
        subtitle: '${virtual.year} · ${virtual.region} · ${virtual.examType}',
        questions: rows
            .map(
              (q) => ExamQuestion(
                questionId: q.id,
                title: '${q.number} ${q.examType} ${q.region}',
                questionType: q.questionType,
              ),
            )
            .toList(growable: false),
      );
    }
    final examId = widget.examId!;
    final preview = await _repo.getPreview(examId);
    return PaperContent(
      ref: SavedPaperRef(examId),
      title: preview.name,
      subtitle: preview.authorInfo,
      isPublic: preview.isPublic,
      questions: preview.questions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        final shouldPop = await _popGuard.consume(context, 'exam_quicklook');
        if (shouldPop && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_paper?.title ?? '试卷预览')),
        body: _buildBody(),
      ),
    );
  }

  Future<void> _togglePublic() async {
    await _repo.togglePublic(widget.examId!);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('公开状态已更新')));
      _load();
    }
  }

  Future<void> _copyToFolder() async {
    final folderId = await PaperFolderRepository.local().copyFromPaper(
      widget.examId!,
      name: '${_paper?.title ?? '试卷'}试题篮',
    );
    if (!mounted) return;
    RouterUtils.push(context, '${AppRoutes.paperFolderDetail}?id=$folderId');
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(AppIcons.delete, color: context.colors.error),
        title: const Text('删除这份试卷？'),
        content: const Text('删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('删除', style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.deleteExam(widget.examId!);
    if (mounted) safePop(context);
  }

  Future<void> _handleMenuAction(String value) async {
    if (value == 'visibility') {
      await _togglePublic();
    } else if (value == 'copy_folder') {
      await _copyToFolder();
    } else if (value == 'delete') {
      await _delete();
    }
  }

  void _startVirtualPaper(PaperContent paper) {
    if (paper.questions.isEmpty) return;
    final first = paper.questions.first;
    SolveRouteHelper.navigateTo(
      context,
      first.questionId,
      first.questionType,
      sequence: paper.questions
          .map((question) => question.questionId)
          .toList(growable: false),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载试卷预览…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    final paper = _paper;
    if (paper == null) return const SizedBox.shrink();

    return AppContentContainer(
      maxWidth: AppContentWidth.reading,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          ListenableBuilder(
            listenable: ExamSessionTimer.instance,
            builder: (context, _) => PaperActionBar(
              actions: [
                PaperAction(
                  label: widget.examId == null
                      ? '开始练习'
                      : ExamSessionTimer.instance.isRunning
                      ? '结束计时 · ${ExamSessionTimer.instance.formatted}'
                      : '开始计时',
                  icon: widget.examId == null
                      ? Icons.play_arrow_rounded
                      : ExamSessionTimer.instance.isRunning
                      ? Icons.timer_off_outlined
                      : Icons.timer_outlined,
                  variant: AppButtonVariant.primary,
                  onPressed: () {
                    if (widget.examId == null) {
                      _startVirtualPaper(paper);
                    } else if (ExamSessionTimer.instance.isRunning) {
                      ExamSessionTimer.instance.stop();
                    } else {
                      ExamSessionTimer.instance.start(widget.examId!);
                    }
                  },
                ),
                PaperAction(
                  label: '快速对答案',
                  icon: Icons.fact_check_outlined,
                  onPressed: () => RouterUtils.push(
                    context,
                    widget.examId != null
                        ? '${AppRoutes.answerSheet}?id=${widget.examId}'
                        : AppRoutes.answerSheet,
                    extra: widget.virtualPaper,
                  ),
                ),
                PaperAction(
                  label: '打印试卷',
                  icon: Icons.picture_as_pdf_outlined,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => PdfHelper.downloadPaperPdf(
                    source:
                        widget.virtualPaper ?? SavedPaperRef(widget.examId!),
                    context: context,
                  ),
                ),
              ],
              menuActions: widget.examId == null
                  ? const []
                  : [
                      PaperMenuAction(
                        value: 'visibility',
                        label: paper.isPublic ? '设为私密' : '公开分享',
                        icon: paper.isPublic
                            ? Icons.lock_outline
                            : Icons.public,
                      ),
                      const PaperMenuAction(
                        value: 'copy_folder',
                        label: '基于此试卷新建试题篮',
                        icon: Icons.create_new_folder_outlined,
                      ),
                      const PaperMenuAction(
                        value: 'delete',
                        label: '删除试卷',
                        icon: AppIcons.delete,
                        destructive: true,
                      ),
                    ],
              onMenuSelected: _handleMenuAction,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSectionHeader(
            title: '试卷题目',
            subtitle: '共 ${paper.questions.length} 题，按当前顺序排列。',
          ),
          const SizedBox(height: AppSpacing.md),
          ...paper.questions.map(
            (question) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ExamQuestionCard(
                questionId: question.questionId,
                title: question.title,
                questionType: question.questionType,
                sequence: paper.questions
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
}
