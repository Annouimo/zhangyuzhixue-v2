import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/assignment_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/helpers/pdf_helper.dart';
import '../../domain/assignment_repository.dart';
import '../../domain/question_repository.dart';
import '../router.dart';

/// 作业详情页。
class HomeworkDetailPage extends StatefulWidget {
  HomeworkDetailPage({
    super.key,
    required this.assignmentId,
    this.assignmentRepository,
  });

  final int assignmentId;
  final AssignmentRepository? assignmentRepository;

  @override
  State<HomeworkDetailPage> createState() => _HomeworkDetailPageState();
}

class _HomeworkDetailPageState extends State<HomeworkDetailPage> {
  late final AssignmentRepository _repo;
  late final QuestionRepository _questionRepo;
  AssignmentDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget.assignmentRepository ??
        AssignmentRepository(
          AssignmentDao(DatabaseProvider()),
          ProgressDao(DatabaseProvider()),
          QuestionDao(DatabaseProvider()),
        );
    _questionRepo = QuestionRepository(
      QuestionDao(DatabaseProvider()),
      ProgressDao(DatabaseProvider()),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _repo.getQuestions(widget.assignmentId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
      AuditLogger.instance.page(
        'HomeworkDetailPage',
        {'qCount': _detail?.questions.length},
      );
    } catch (error) {
      OperationLog.instance.error('homework_detail_page_load', error);
      AuditLogger.instance.error('HomeworkDetailPage._load', error);
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
          title: Text(_detail?.title ?? '作业详情'),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: '下载 PDF',
              onPressed: () => PdfHelper.downloadPdf(
                sourceId: widget.assignmentId,
                sourceType: 'assignment',
                context: context,
              ),
            ),
          ],
        ),
        body: _buildBody(),
      );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载作业详情…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    final detail = _detail;
    if (detail == null) return const SizedBox.shrink();

    final progress = detail.totalCount > 0
        ? detail.doneCount / detail.totalCount
        : 0.0;
    final percent = (progress * 100).round();

    return AppContentContainer(
      maxWidth: AppContentWidth.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          AppFeatureBanner(
            eyebrow: detail.courseName.isEmpty ? '课程作业' : detail.courseName,
            icon: Icons.assignment_turned_in_outlined,
            title: detail.title,
            subtitle: '按顺序完成题目，已完成内容可以随时进入回顾模式。',
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 9,
                          backgroundColor: context.colors.surfaceSubtle,
                          valueColor: AlwaysStoppedAnimation(
                            progress >= 1
                                ? context.colors.success
                                : context.colors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '$percent%',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppStatusBadge(
                      label: '已完成 ${detail.doneCount}',
                      tone: AppStatusTone.success,
                      icon: Icons.check_circle_outline_rounded,
                      compact: true,
                    ),
                    AppStatusBadge(
                      label: '待完成 ${detail.totalCount - detail.doneCount}',
                      tone: AppStatusTone.info,
                      icon: Icons.pending_actions_outlined,
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(
            title: '题目列表',
            subtitle: '共 ${detail.questions.length} 题，状态会在完成后自动更新。',
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              itemCount: detail.questions.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final question = detail.questions[index];
                return _QuestionTile(
                  index: index + 1,
                  number: question.number,
                  questionType: question.questionType,
                  status: question.status,
                  onTap: () => _openQuestion(detail, question),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openQuestion(
    AssignmentDetail detail,
    QuestionSummary question,
  ) async {
    final route = switch (question.questionType) {
      'choice' => AppRoutes.solveChoice,
      'fill' => AppRoutes.solveFill,
      'solution' => AppRoutes.solveMap,
      _ => AppRoutes.solveMap,
    };
    String mode = 'first';
    int? attemptId;
    if (question.status != 'pending') {
      try {
        final attempts = await _questionRepo.getAttempts(question.id);
        if (attempts.isNotEmpty) {
          mode = !attempts.last.isCompleted ? 'resume' : 'review';
          attemptId = attempts.last.id;
        }
      } catch (error) {
        OperationLog.instance.error('homework_detail_page_open', error);
        AuditLogger.instance.error('HomeworkDetailPage.onTap', error);
      }
    }
    final currentIndex = detail.questions.indexWhere(
      (item) => item.id == question.id,
    );
    final nextId = currentIndex >= 0 && currentIndex + 1 < detail.questions.length
        ? detail.questions[currentIndex + 1].id
        : null;
    await RouterUtils.push(
      context,
      '$route?id=${question.id}'
      '${mode != 'first' ? '&mode=$mode' : ''}'
      '${attemptId != null ? '&attemptId=$attemptId' : ''}'
      '${nextId != null ? '&next=$nextId' : ''}',
    );
    _load();
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.index,
    required this.number,
    required this.questionType,
    required this.status,
    required this.onTap,
  });

  final int index;
  final String number;
  final String questionType;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusInfo = statusStyle(status, colors);
    final completed = status == 'completed';

    return AppCard(
      onTap: onTap,
      semanticLabel: number.isNotEmpty ? '第 $number 题' : '第 $index 题',
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: completed
                  ? colors.successContainer
                  : colors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            alignment: Alignment.center,
            child: completed
                ? Icon(AppIcons.success, color: colors.success, size: 21)
                : Text(
                    '$index',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.primary,
                        ),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number.isNotEmpty ? '第 $number 题' : '第 $index 题',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  QuestionTypeLabels.of(questionType),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          AppStatusBadge(
            label: statusInfo.label,
            tone: _tone(status),
            compact: true,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Icon(AppIcons.chevronRight, color: colors.textMuted),
        ],
      ),
    );
  }

  static AppStatusTone _tone(String value) {
    if (value == 'completed') return AppStatusTone.success;
    if (value == 'in_progress' || value == 'inProgress') {
      return AppStatusTone.info;
    }
    return AppStatusTone.neutral;
  }
}
