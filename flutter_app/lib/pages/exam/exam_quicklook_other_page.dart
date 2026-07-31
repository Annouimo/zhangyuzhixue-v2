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
  bool _updatingLike = false;
  bool _updatingCollect = false;

  bool get _liked => _preview?.isLiked ?? false;
  bool get _collected => _preview?.isCollected ?? false;

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
      actions: _preview == null ? null : _buildPaperActions(),
    ),
    body: _buildBody(),
  );

  List<Widget> _buildPaperActions() => [
    IconButton(
      tooltip: _liked ? '取消点赞' : '点赞',
      onPressed: _updatingLike ? null : _toggleLike,
      style: IconButton.styleFrom(
        foregroundColor: _liked
            ? context.colors.primary
            : context.colors.textSecondary,
        backgroundColor: _liked
            ? context.colors.primaryContainer
            : Colors.transparent,
      ),
      icon: Icon(
        _liked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
      ),
    ),
    IconButton(
      tooltip: _collected ? '取消收藏' : '收藏',
      onPressed: _updatingCollect ? null : _toggleCollect,
      style: IconButton.styleFrom(
        foregroundColor: _collected
            ? context.colors.primary
            : context.colors.textSecondary,
        backgroundColor: _collected
            ? context.colors.primaryContainer
            : Colors.transparent,
      ),
      icon: Icon(
        _collected ? Icons.star_rounded : Icons.star_border_rounded,
      ),
    ),
    PopupMenuButton<String>(
      tooltip: '更多试卷操作',
      icon: const Icon(Icons.more_horiz),
      onSelected: (value) {
        if (value == 'answers') {
          RouterUtils.push(
            context,
            '${AppRoutes.answerSheet}?id=${widget.examId}',
          );
        }
        if (value == 'print') {
          PdfHelper.downloadPdf(
            sourceId: widget.examId,
            sourceType: 'paper',
            context: context,
          );
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'answers',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.fact_check_outlined),
            title: Text('快速对答案'),
          ),
        ),
        PopupMenuItem(
          value: 'print',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.print_outlined),
            title: Text('打印试卷'),
          ),
        ),
      ],
    ),
  ];

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
    if (_updatingLike || _preview == null) return;
    final previous = _liked;
    final target = !previous;
    setState(() {
      _updatingLike = true;
      _preview = _preview!.copyWith(
        isLiked: target,
        likeCount: (_preview!.likeCount + (target ? 1 : -1)).clamp(0, 1 << 30),
      );
    });
    try {
      await _repo.setLike(widget.examId, target);
    } catch (_) {
      if (mounted && _preview != null) {
        setState(() {
          _preview = _preview!.copyWith(
            isLiked: previous,
            likeCount: (_preview!.likeCount + (previous ? 1 : -1))
                .clamp(0, 1 << 30),
          );
        });
        AppToast.error(context, '点赞操作失败，请稍后重试');
      }
    } finally {
      _updatingLike = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _toggleCollect() async {
    if (_updatingCollect || _preview == null) return;
    final previous = _collected;
    final target = !previous;
    setState(() {
      _updatingCollect = true;
      _preview = _preview!.copyWith(
        isCollected: target,
        collectCount: (_preview!.collectCount + (target ? 1 : -1))
            .clamp(0, 1 << 30),
      );
    });
    try {
      await _repo.setCollect(widget.examId, target);
    } catch (_) {
      if (mounted && _preview != null) {
        setState(() {
          _preview = _preview!.copyWith(
            isCollected: previous,
            collectCount: (_preview!.collectCount + (previous ? 1 : -1))
                .clamp(0, 1 << 30),
          );
        });
        AppToast.error(context, '收藏操作失败，请稍后重试');
      }
    } finally {
      _updatingCollect = false;
      if (mounted) setState(() {});
    }
  }
}
