import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/progress_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/assets_database.dart';
import '../../data/database/database_provider.dart';
import '../../domain/progress_repository.dart';
import '../../domain/question_repository.dart';
import '../solve/widgets/solve_result_card.dart';
import 'question_detail_presentation.dart';

class StudentQuestionDetailPage extends StatefulWidget {
  const StudentQuestionDetailPage({super.key, required this.questionId});

  final int questionId;

  @override
  State<StudentQuestionDetailPage> createState() =>
      _StudentQuestionDetailPageState();
}

class _StudentQuestionDetailPageState extends State<StudentQuestionDetailPage> {
  late final QuestionDao _questionDao = QuestionDao(DatabaseProvider());
  late final ProgressDao _progressDao = ProgressDao(DatabaseProvider());
  late final QuestionRepository _repository = QuestionRepository(
    _questionDao,
    _progressDao,
  );
  QuestionDetail? _detail;
  QuestionRow? _question;
  SolveProgressState? _solveState;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.getDetail(widget.questionId),
        _questionDao.getById(widget.questionId),
        ProgressRepository(
          _progressDao,
          _questionDao,
        ).getSolveState(widget.questionId),
      ]);
      if (!mounted) return;
      setState(() {
        _detail = results[0] as QuestionDetail;
        _question = results[1] as QuestionRow?;
        _solveState = results[2] as SolveProgressState;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '题目详情加载失败';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('题目详情')),
      body: _loading
          ? const LoadingIndicator(message: '正在加载题目详情')
          : _error != null
          ? ErrorPlaceholder(message: _error!, onRetry: _load)
          : _buildContent(),
      bottomNavigationBar: _detail == null ? null : _buildAction(),
    );
  }

  Widget _buildContent() {
    final detail = _detail!;
    return AppContentContainer(
      maxWidth: AppContentWidth.reading,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusBadge(
                label: QuestionTypeLabels.of(detail.questionType),
                tone: AppStatusTone.info,
              ),
              if (_question?.calculation != null)
                AppStatusBadge(
                  label: '计算量 ${_question!.calculation!.toStringAsFixed(1)}',
                  tone: AppStatusTone.neutral,
                ),
              if (_question?.defaultScore != null)
                AppStatusBadge(
                  label: '分值 ${_question!.defaultScore!.toStringAsFixed(0)}',
                  tone: AppStatusTone.neutral,
                ),
              AppStatusBadge(
                label: '难度 ${detail.difficulty.toStringAsFixed(1)}',
                tone: AppStatusTone.neutral,
              ),
              for (final tag in detail.conceptTags)
                AppStatusBadge(
                  label: tag,
                  tone: AppStatusTone.neutral,
                  compact: true,
                ),
            ],
          ),
          if (detail.assignName.isNotEmpty || detail.number.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              [
                detail.assignName,
                if (detail.number.isNotEmpty) '第 ${detail.number} 题',
              ].where((value) => value.isNotEmpty).join(' · '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MdLatexBody(detail.stem, fontSize: 16),
                for (final path in detail.images) ...[
                  const SizedBox(height: AppSpacing.md),
                  QuestionImage(relativePath: path),
                ],
                if (detail.options?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.lg),
                  for (final option in detail.options!.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              option.key,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Expanded(
                            child: MdLatexBody(option.value, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            title: const Text('查看答案与解析'),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              0,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            children: [
              SolveAnswerRevealCard(
                answer: detail.answer?.trim().isNotEmpty == true
                    ? detail.answer!
                    : '暂无标准答案',
                explanation: detail.explanation,
              ),
            ],
          ),
          if (_solveState?.subQuestions.any(
                (subQuestion) => subQuestion.solutions.isNotEmpty,
              ) ==
              true)
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
              ),
              title: const Text('完整解法与步骤'),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              children: _buildSolutionDetails(),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  List<Widget> _buildSolutionDetails() {
    final state = _solveState;
    if (state == null) return const [];
    final widgets = <Widget>[];
    for (
      var subQuestionIndex = 0;
      subQuestionIndex < state.subQuestions.length;
      subQuestionIndex++
    ) {
      final subQuestion = state.subQuestions[subQuestionIndex];
      final subQuestionTitle = subQuestionHeading(
        count: state.subQuestions.length,
        index: subQuestionIndex,
      );
      if (subQuestionTitle != null) {
        widgets.add(
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                subQuestionTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
        );
      }
      for (
        var methodIndex = 0;
        methodIndex < subQuestion.solutions.length;
        methodIndex++
      ) {
        final method = subQuestion.solutions[methodIndex];
        final methodTitle = solutionMethodHeading(
          count: subQuestion.solutions.length,
          index: methodIndex,
          name: method.methodName,
        );
        if (methodTitle != null) {
          widgets.add(
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.xs,
                ),
                child: Text(
                  methodTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
          );
        }
        for (var stepIndex = 0; stepIndex < method.steps.length; stepIndex++) {
          final step = method.steps[stepIndex];
          final stepTitle = solutionStepHeading(
            count: method.steps.length,
            index: stepIndex,
            title: step.title,
          );
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (stepTitle != null)
                    Text(
                      stepTitle,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  if (stepTitle != null && step.analysis.trim().isNotEmpty)
                    const SizedBox(height: AppSpacing.xxs),
                  if (step.analysis.trim().isNotEmpty)
                    MdLatexBody(step.analysis, fontSize: 14),
                  if (step.cardTitles.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: step.cardTitles
                          .map(
                            (title) => AppStatusBadge(
                              label: title,
                              tone: AppStatusTone.warning,
                              compact: true,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
      }
    }
    return widgets;
  }

  Widget _buildAction() {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.colors.divider)),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: AppButton(
                label: '练习此题',
                icon: Icons.edit_rounded,
                fullWidth: true,
                onPressed: () => SolveRouteHelper.navigateTo(
                  context,
                  widget.questionId,
                  _detail!.questionType,
                  forceNewAttempt: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
