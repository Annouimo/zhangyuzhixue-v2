import 'package:flutter/material.dart';
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
import '../../widgets/question_selection_workspace.dart';
import '../router.dart';
import 'widgets/paper_action_bar.dart';

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
                title: q.stem,
                questionType: q.questionType,
                source: '${q.year} ${q.examType} ${q.region}',
                difficulty: q.difficulty,
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
      onPopInvokedWithResult: (didPop, _) =>
          _popGuard.handlePop(context, 'exam_quicklook'),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_paper?.title ?? '试卷预览', overflow: TextOverflow.ellipsis),
          actions: _paper == null
              ? null
              : [
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width >= 800 ? 430 : 190,
                    child: _buildPaperActions(_paper!),
                  ),
                ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Future<void> _togglePublic() async {
    await _repo.togglePublic(widget.examId!);
    if (mounted) {
      AppToast.success(context, '公开状态已更新');
      _load();
    }
  }

  Future<void> _delete() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: '删除这份试卷？',
      message: '删除后无法恢复。',
      icon: AppIcons.delete,
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed) return;
    await _repo.deleteExam(widget.examId!);
    if (mounted) safePop(context);
  }

  Future<void> _handleMenuAction(String value) async {
    if (value == 'answers') {
      await RouterUtils.push(
        context,
        widget.examId != null
            ? '${AppRoutes.answerSheet}?id=${widget.examId}'
            : AppRoutes.answerSheet,
        extra: widget.virtualPaper,
      );
    } else if (value == 'print') {
      await PdfHelper.downloadPaperPdf(
        source: widget.virtualPaper ?? SavedPaperRef(widget.examId!),
        context: context,
      );
    } else if (value == 'visibility') {
      await _togglePublic();
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

  Widget _buildPaperActions(PaperContent paper) => PaperActionBar(
    actions: [
      if (widget.examId == null)
        PaperAction(
          label: '开始练习',
          compactLabel: '开始',
          icon: Icons.play_arrow_rounded,
          variant: AppButtonVariant.primary,
          onPressed: () => _startVirtualPaper(paper),
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
    ],
    menuActions: [
      const PaperMenuAction(
        value: 'print',
        label: '打印试卷',
        icon: Icons.print_outlined,
      ),
      if (widget.examId != null) ...[
        PaperMenuAction(
          value: 'visibility',
          label: paper.isPublic ? '设为私密' : '公开分享',
          icon: paper.isPublic ? Icons.lock_outline : Icons.public,
        ),
        const PaperMenuAction(
          value: 'delete',
          label: '删除试卷',
          icon: AppIcons.delete,
          destructive: true,
        ),
      ],
    ],
    onMenuSelected: _handleMenuAction,
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载试卷预览…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    final paper = _paper;
    if (paper == null) return const SizedBox.shrink();

    final sequence = paper.questions
        .map((question) => question.questionId)
        .toList(growable: false);
    final items = paper.questions
        .asMap()
        .entries
        .map(
          (entry) => QuestionWorkspaceItem(
            id: entry.value.questionId,
            title: entry.value.title,
            questionType: entry.value.questionType,
            subtitle: '${entry.key + 1}. ${entry.value.source}',
            difficulty: entry.value.difficulty,
          ),
        )
        .toList(growable: false);
    return AppContentContainer(
      maxWidth: AppContentWidth.reading,
      child: QuestionWorkspace(
        items: items,
        basketRepository: PaperFolderRepository.local(),
        onOpen: (item) => SolveRouteHelper.navigateTo(
          context,
          item.id,
          item.questionType,
          sequence: sequence,
        ),
        headerSliversBuilder: (context, selectedIds) => [
          SliverToBoxAdapter(
            child: Column(
              children: [
                AppSectionHeader(
                  title: '试卷题目',
                  subtitle: '共 ${paper.questions.length} 题，按当前顺序排列。',
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
