import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/helpers/pdf_helper.dart';
import '../../domain/exam_repository.dart';
import '../../domain/paper_folder_repository.dart';
import '../../domain/question_repository.dart';
import '../../widgets/question_selection_workspace.dart';
import '../router.dart';
import 'widgets/paper_action_bar.dart';

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
      title: Text(_preview?.name ?? '试卷预览', overflow: TextOverflow.ellipsis),
      actions: _preview == null
          ? null
          : [
              SizedBox(
                width: MediaQuery.sizeOf(context).width >= 800 ? 430 : 190,
                child: _buildPaperActions(_preview!),
              ),
            ],
    ),
    body: _buildBody(),
  );

  Widget _buildPaperActions(ExamPreviewOther preview) => PaperActionBar(
    actions: [
      PaperAction(
        label: '快速对答案',
        compactLabel: '对答案',
        icon: Icons.fact_check_outlined,
        onPressed: () => RouterUtils.push(
          context,
          '${AppRoutes.answerSheet}?id=${widget.examId}',
        ),
      ),
      PaperAction(
        label: _collected
            ? '${preview.collectCount} 已收藏'
            : '${preview.collectCount} 收藏',
        icon: _collected
            ? Icons.bookmark_rounded
            : Icons.bookmark_outline_rounded,
        variant: AppButtonVariant.outlined,
        onPressed: _toggleCollect,
      ),
    ],
    menuActions: [
      PaperMenuAction(
        value: 'like',
        label: _liked ? '${preview.likeCount} 取消点赞' : '${preview.likeCount} 点赞',
        icon: _liked ? AppIcons.likeSelected : AppIcons.like,
      ),
      const PaperMenuAction(
        value: 'print',
        label: '打印试卷',
        icon: Icons.print_outlined,
      ),
    ],
    onMenuSelected: (value) {
      if (value == 'like') _toggleLike();
      if (value == 'print') {
        PdfHelper.downloadPdf(
          sourceId: widget.examId,
          sourceType: 'paper',
          context: context,
        );
      }
    },
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载试卷预览…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    final preview = _preview;
    if (preview == null) return const SizedBox.shrink();

    final sequence = preview.questions
        .map((question) => question.questionId)
        .toList(growable: false);
    final items = preview.questions
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
                  subtitle: '共 ${preview.questions.length} 题，点击可进入练习。',
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
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
