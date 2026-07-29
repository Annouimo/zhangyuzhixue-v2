import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/pop_back_guard.dart';
import 'package:shared/shared.dart';

import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/helpers/pdf_helper.dart';
import '../../domain/exam_repository.dart';
import '../../domain/paper_folder_repository.dart';
import '../router.dart';
import 'widgets/exam_question_card.dart';
import 'exam_session_timer.dart';

/// 预览自己创建的组卷。
class ExamQuicklookPage extends StatefulWidget {
  const ExamQuicklookPage({
    super.key,
    required this.examId,
    this.examRepository,
  });

  final int examId;
  final ExamRepository? examRepository;

  @override
  State<ExamQuicklookPage> createState() => _ExamQuicklookPageState();
}

class _ExamQuicklookPageState extends State<ExamQuicklookPage> {
  late final ExamRepository _repo;
  final PopBackGuard _popGuard = PopBackGuard();
  ExamPreview? _preview;
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
      final preview = await _repo.getPreview(widget.examId);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _loading = false;
      });
      AuditLogger.instance.page('ExamQuicklookPage', {
        'hasPreview': _preview != null,
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        final shouldPop = await _popGuard.consume(context, 'exam_quicklook');
        if (shouldPop && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_preview?.name ?? '试卷预览'),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: '打印试卷',
              onPressed: () => PdfHelper.downloadPdf(
                sourceId: widget.examId,
                sourceType: 'paper',
                context: context,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: '更多操作',
              onSelected: (value) async {
                if (value == 'visibility') {
                  await _togglePublic();
                } else if (value == 'delete') {
                  await _delete();
                } else if (value == 'copy_folder') {
                  await _copyToFolder();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'copy_folder',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.create_new_folder_outlined),
                    title: Text('基于此试卷新建组卷夹'),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'visibility',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _preview?.isPublic == true
                          ? Icons.lock_outline
                          : Icons.public,
                    ),
                    title: Text(_preview?.isPublic == true ? '设为私密' : '公开分享'),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(AppIcons.delete, color: context.colors.error),
                    title: Text(
                      '删除试卷',
                      style: TextStyle(color: context.colors.error),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Future<void> _togglePublic() async {
    await _repo.togglePublic(widget.examId);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('公开状态已更新')));
      _load();
    }
  }

  Future<void> _copyToFolder() async {
    final folderId = await PaperFolderRepository.local().copyFromPaper(
      widget.examId,
      name: '${_preview?.name ?? '试卷'}组卷夹',
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
    await _repo.deleteExam(widget.examId);
    if (mounted) safePop(context);
  }

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
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ListenableBuilder(
                listenable: ExamSessionTimer.instance,
                builder: (context, _) => AppButton(
                  label: ExamSessionTimer.instance.isRunning
                      ? '结束计时 · ${ExamSessionTimer.instance.formatted}'
                      : '开始计时',
                  icon: ExamSessionTimer.instance.isRunning
                      ? Icons.timer_off_outlined
                      : Icons.timer_outlined,
                  onPressed: () {
                    if (ExamSessionTimer.instance.isRunning) {
                      ExamSessionTimer.instance.stop();
                    } else {
                      ExamSessionTimer.instance.start(widget.examId);
                    }
                  },
                ),
              ),
              AppButton(
                label: '快速对答案',
                icon: Icons.fact_check_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => RouterUtils.push(
                  context,
                  '${AppRoutes.answerSheet}?id=${widget.examId}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppSectionHeader(
            title: '试卷题目',
            subtitle: '共 ${preview.questions.length} 题，按当前顺序排列。',
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
}
