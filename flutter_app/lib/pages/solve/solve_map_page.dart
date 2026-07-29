import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/app_button.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_status_badge.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/progress_repository.dart' as progress;
import '../../domain/question_repository.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import '../exam/exam_session_timer.dart';
import 'widgets/question_contribution_actions.dart';

/// 解答题地图页 — 步骤概览（匹配 solve-map.html）
class SolveMapPage extends StatefulWidget {
  final int questionId;
  final String? mode;
  final int? attemptId;
  final List<int> sequence;
  final List<int> quickPracticeSeen;
  final bool embedded;
  final bool forceNewAttempt;
  final VoidCallback? onNext;

  const SolveMapPage({
    super.key,
    required this.questionId,
    this.mode,
    this.attemptId,
    this.sequence = const [],
    this.quickPracticeSeen = const [],
    this.embedded = false,
    this.forceNewAttempt = false,
    this.onNext,
  });

  @override
  State<SolveMapPage> createState() => _SolveMapPageState();
}

class _SolveMapPageState extends State<SolveMapPage> {
  progress.SolveProgressState? _state;
  Set<String> _completedSteps = {};
  bool _loading = true;
  String? _error;
  bool _reviewMode = false;
  bool _newAttemptCreated = false;

  // 存档选择器
  List<progress.AttemptSummary> _attempts = [];
  int? _currentAttemptNumber;
  int? _currentSubmissionDetailId;

  // 题目信息
  QuestionDetail? _detail;

  // 解法折叠状态: methodIndex->collapsed
  final Set<String> _collapsedMethods = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = progress.ProgressRepository(
      ProgressDao(DatabaseProvider()),
      QuestionDao(DatabaseProvider()),
    );
    final qRepo = QuestionRepository(
      QuestionDao(DatabaseProvider()),
      ProgressDao(DatabaseProvider()),
    );
    try {
      OperationLog.instance.action('solve_map_page_load', 'T1 start');
      final s = await repo.getSolveState(widget.questionId);
      OperationLog.instance.action(
        'solve_map_page_load',
        'T2 after getSolveState (subQCount=${s.subQuestions.length})',
      );
      var attempts = await repo.getAttempts(widget.questionId);
      OperationLog.instance.action(
        'solve_map_page_load',
        'T3 after getAttempts (${attempts.length})',
      );

      // 加载题目元信息
      QuestionDetail? detail;
      try {
        detail = await qRepo.getDetail(widget.questionId);
        OperationLog.instance.action(
          'solve_map_page_load',
          'T4 after getDetail',
        );
      } catch (e) {
        OperationLog.instance.action(
          'solve_map_page_load',
          'T4 getDetail error: $e',
        );
      }

      // 首次访问自动创建存档
      if (attempts.isEmpty &&
          widget.mode != 'review' &&
          !widget.forceNewAttempt) {
        await repo.createAttempt(widget.questionId);
        OperationLog.instance.action(
          'solve_map_page_load',
          'T5 after createAttempt',
        );
        attempts = await repo.getAttempts(widget.questionId);
      }

      // 判断回顾模式: mode=review 或 attempts.last.completed 且不是最新
      final lastStarted = attempts.isNotEmpty ? attempts.last : null;
      final review =
          !widget.forceNewAttempt &&
          (widget.mode == 'review' ||
              (lastStarted != null &&
                  lastStarted.status == 'completed' &&
                  widget.attemptId != null &&
                  widget.attemptId != lastStarted.id));

      // 计算已完成步骤（按当前 attemptId 或最新存档）
      Set<String> doneSteps = {};
      int? currentSubmissionDetailId;
      int? currentAttemptNumber;

      if (attempts.isNotEmpty && !widget.forceNewAttempt) {
        final targetAttemptNumber = widget.attemptId != null
            ? attempts
                  .where((a) => a.id == widget.attemptId)
                  .firstOrNull
                  ?.attemptNumber
            : attempts.last.attemptNumber;
        currentAttemptNumber =
            targetAttemptNumber ?? attempts.last.attemptNumber;
        currentSubmissionDetailId = attempts
            .where((a) => a.attemptNumber == currentAttemptNumber)
            .firstOrNull
            ?.id;

        final prevState = await repo.getAttemptState(
          widget.questionId,
          currentAttemptNumber,
        );
        if (prevState != null) {
          try {
            doneSteps = prevState.subQRecords
                .expand(
                  (sq) => sq.methods.asMap().entries.expand(
                    (mEntry) => mEntry.value.steps
                        .where((s) => s.feedbackGiven)
                        .map((s) => '${sq.index}_${mEntry.key}_${s.stepOrder}'),
                  ),
                )
                .toSet();
          } catch (e1) {
            AuditLogger.instance.error('SolveMapPage._load.doneSteps', e1);
            rethrow;
          }
        }
      }
      OperationLog.instance.action('solve_map_page_load', 'T6 before setState');

      if (!mounted) return;
      setState(() {
        _state = s;
        _attempts = attempts;
        _detail = detail;
        _completedSteps = doneSteps;
        _reviewMode = review;
        _currentAttemptNumber = currentAttemptNumber;
        _currentSubmissionDetailId = currentSubmissionDetailId;
        _loading = false;
      });
      AuditLogger.instance.page('SolveMapPage', {
        'qid': widget.questionId,
        'subQCount': s.subQuestions.length,
      });
      OperationLog.instance.action('solve_map_page_load', 'T7 complete');
    } catch (e) {
      OperationLog.instance.action('solve_map_page_load', 'T8 catch: $e');
      OperationLog.instance.error('solve_map_page_load', e);
      AuditLogger.instance.error('SolveMapPage._load', e);
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  // 入口分流路由构造
  String _buildStepRoute(int subQIndex, int methodIndex, int stepIndex) {
    final buf = StringBuffer(
      '/solve/step?id=${widget.questionId}'
      '&subQ=$subQIndex&method=$methodIndex&step=$stepIndex',
    );
    if (_currentAttemptNumber != null) {
      buf.write('&attemptId=$_currentSubmissionDetailId');
    }
    return buf.toString();
  }

  String _formatCardLabels(List<String> cards) {
    if (cards.isEmpty) return '';
    if (cards.length == 1) return cards.first;
    return '${cards.first} 等 ${cards.length} 个';
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const LoadingIndicator(message: '正在整理解题步骤')
        : _error != null
        ? ErrorPlaceholder(
            message: '解题步骤加载失败，请检查后重试',
            onRetry: () {
              setState(() {
                _error = null;
                _loading = true;
              });
              _load();
            },
          )
        : _buildMapView();
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: const Text('解题步骤'),
        actions: [
          ...questionContributionActions(context, widget.questionId),
          const ExamTimerAction(),
        ],
      ),
      body: body,
    );
  }

  Widget _buildAttemptSelector() {
    final colors = context.colors;
    if (_attempts.isEmpty) return SizedBox.shrink();

    final label = _currentAttemptNumber != null
        ? '第 $_currentAttemptNumber 次作答'
        : '第 ${_attempts.length + 1} 次作答';

    if (_attempts.length <= 1) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.primary),
        ),
      );
    }

    return PopupMenuButton<Object>(
      onSelected: (value) async {
        if (value is progress.AttemptSummary) {
          // 切换到其他存档
          final repo = progress.ProgressRepository(
            ProgressDao(DatabaseProvider()),
            QuestionDao(DatabaseProvider()),
          );
          final prevState = await repo.getAttemptState(
            widget.questionId,
            value.attemptNumber,
          );
          Set<String> doneSteps = {};
          if (prevState != null) {
            doneSteps = prevState.subQRecords
                .expand(
                  (sq) => sq.methods.asMap().entries.expand(
                    (mEntry) => mEntry.value.steps
                        .where((s) => s.feedbackGiven)
                        .map((s) => '${sq.index}_${mEntry.key}_${s.stepOrder}'),
                  ),
                )
                .toSet();
          }
          if (!mounted) return;
          setState(() {
            _currentAttemptNumber = value.attemptNumber;
            _currentSubmissionDetailId = value.id;
            _completedSteps = doneSteps;
            _reviewMode = value.status == 'completed';
          });
        }
      },
      offset: Offset(0, 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) => [
        ..._attempts.map(
          (a) => PopupMenuItem<Object>(
            value: a,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '第 ${a.attemptNumber} 次作答',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: a.attemptNumber == _currentAttemptNumber
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: a.attemptNumber == _currentAttemptNumber
                        ? colors.primary
                        : colors.textPrimary,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  a.status == 'completed' ? '回顾' : '进行中',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: colors.primary)),
            Icon(Icons.expand_more, size: 14, color: colors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    final colors = context.colors;
    if (_state == null || _state!.subQuestions.isEmpty) {
      return const Center(child: Text('暂无步骤数据'));
    }

    return AppContentContainer(
      maxWidth: AppContentWidth.standard,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          if (_detail != null)
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_detail!.number.isNotEmpty)
                    Text(
                      '第 ${_detail!.number} 题',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  const AppStatusBadge(
                    label: '解答题',
                    tone: AppStatusTone.primary,
                    compact: true,
                  ),
                  if (!widget.embedded) _buildAttemptSelector(),
                  if (_detail!.title.isNotEmpty)
                    Text(
                      _detail!.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          if (_reviewMode) ...[
            const SizedBox(height: AppSpacing.md),
            const Align(
              alignment: Alignment.centerLeft,
              child: AppStatusBadge(
                label: '回顾模式 · 当前步骤记录只读',
                tone: AppStatusTone.info,
                icon: Icons.history_rounded,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('选择解题路径', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '按步骤逐层展开解析，并在每一步完成后进行自评。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._state!.subQuestions.asMap().entries.map((sqEntry) {
            final subQIdx = sqEntry.key;
            final sq = sqEntry.value;
            var anyMethodFullyDone = false;
            var hasAnyStepDone = false;

            for (final mEntry in sq.solutions.asMap().entries) {
              final methodIndex = mEntry.key;
              final method = mEntry.value;
              var methodDone = true;
              for (final step in method.steps) {
                final isDone = _completedSteps.contains(
                  '${sq.index}_${methodIndex}_${step.stepNumber}',
                );
                if (isDone) {
                  hasAnyStepDone = true;
                } else {
                  methodDone = false;
                }
              }
              if (methodDone && method.steps.isNotEmpty) {
                anyMethodFullyDone = true;
              }
            }

            final (statusLabel, statusTone) = anyMethodFullyDone
                ? ('已完成', AppStatusTone.success)
                : hasAnyStepDone
                ? ('进行中', AppStatusTone.warning)
                : ('待开始', AppStatusTone.neutral);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sq.label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        AppStatusBadge(
                          label: statusLabel,
                          tone: statusTone,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...sq.solutions.asMap().entries.map((mEntry) {
                      final methodIndex = mEntry.key;
                      final method = mEntry.value;
                      final methodKey = '${sq.index}_$methodIndex';
                      final collapsed = _collapsedMethods.contains(methodKey);
                      final completedCount = method.steps
                          .where(
                            (step) => _completedSteps.contains(
                              '${sq.index}_${methodIndex}_${step.stepNumber}',
                            ),
                          )
                          .length;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(
                              AppRadius.medium,
                            ),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (collapsed) {
                                      _collapsedMethods.remove(methodKey);
                                    } else {
                                      _collapsedMethods.add(methodKey);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(
                                  AppRadius.medium,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.account_tree_outlined,
                                        size: 20,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Expanded(
                                        child: Text(
                                          method.methodName?.isNotEmpty == true
                                              ? method.methodName!
                                              : '标准解法',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                      ),
                                      Text(
                                        '$completedCount/${method.steps.length} 步',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: colors.textSecondary,
                                            ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Icon(
                                        collapsed
                                            ? Icons.expand_more_rounded
                                            : Icons.expand_less_rounded,
                                        color: colors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!collapsed)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.md,
                                    0,
                                    AppSpacing.md,
                                    AppSpacing.md,
                                  ),
                                  child: Column(
                                    children: method.steps.asMap().entries.map((
                                      stepEntry,
                                    ) {
                                      final stepIndex = stepEntry.key;
                                      final step = stepEntry.value;
                                      final stepKey =
                                          '${sq.index}_${methodIndex}_${step.stepNumber}';
                                      final isDone = _completedSteps.contains(
                                        stepKey,
                                      );
                                      final locked =
                                          !isDone &&
                                          stepIndex > 0 &&
                                          method.steps
                                              .take(stepIndex)
                                              .any(
                                                (
                                                  previous,
                                                ) => !_completedSteps.contains(
                                                  '${sq.index}_${methodIndex}_${previous.stepNumber}',
                                                ),
                                              );

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: AppSpacing.xs,
                                        ),
                                        child: _SolveStepTile(
                                          stepNumber: step.stepNumber,
                                          label: '第 ${step.stepNumber} 步',
                                          subtitle:
                                              !locked &&
                                                  step.cardTitles.isNotEmpty
                                              ? _formatCardLabels(
                                                  step.cardTitles,
                                                )
                                              : null,
                                          isDone: isDone,
                                          isLocked: locked,
                                          onTap: locked
                                              ? null
                                              : () async {
                                                  await _ensureNewAttempt();
                                                  if (!mounted) return;
                                                  await context.push(
                                                    _buildStepRoute(
                                                      subQIdx,
                                                      methodIndex,
                                                      stepIndex,
                                                    ),
                                                  );
                                                  _load();
                                                },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.xs),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final actions = [
                if (!widget.embedded)
                  AppButton(
                    label: '返回',
                    icon: Icons.arrow_back_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.pop(),
                  ),
                if (!widget.embedded)
                  AppButton(
                    label: '重新作答',
                    icon: Icons.refresh_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: _onRetry,
                  ),
                AppButton(
                  label: '给题目评分',
                  icon: Icons.star_outline_rounded,
                  onPressed: () =>
                      context.push('/solve/rate?id=${widget.questionId}'),
                ),
                if (widget.onNext != null ||
                    _nextQuestionId != null ||
                    _isQuickPractice)
                  AppButton(
                    label: _isQuickPractice ? '再来一题' : '下一题',
                    icon: Icons.arrow_forward_rounded,
                    onPressed:
                        widget.onNext ??
                        (_isQuickPractice
                            ? _continueQuickPractice
                            : () => SolveRouteHelper.navigateToNext(
                                context,
                                _nextQuestionId!,
                                widget.sequence,
                              )),
                  ),
              ];

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      actions[i],
                      if (i != actions.length - 1)
                        const SizedBox(height: AppSpacing.xs),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    Expanded(child: actions[i]),
                    if (i != actions.length - 1)
                      const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  int? get _nextQuestionId {
    final index = widget.sequence.indexOf(widget.questionId);
    return index >= 0 && index + 1 < widget.sequence.length
        ? widget.sequence[index + 1]
        : null;
  }

  bool get _isQuickPractice => widget.quickPracticeSeen.isNotEmpty;

  Future<void> _continueQuickPractice() async {
    final navigated = await SolveRouteHelper.navigateToNextQuickPractice(
      context,
      widget.quickPracticeSeen,
    );
    if (!navigated && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('本轮题目已全部完成')));
      context.pop();
    }
  }

  Future<void> _onRetry() async {
    final repo = progress.ProgressRepository(
      ProgressDao(DatabaseProvider()),
      QuestionDao(DatabaseProvider()),
    );
    await repo.createAttempt(widget.questionId);
    _load();
  }

  Future<void> _ensureNewAttempt() async {
    if (!widget.forceNewAttempt || _newAttemptCreated) return;
    final repo = progress.ProgressRepository(
      ProgressDao(DatabaseProvider()),
      QuestionDao(DatabaseProvider()),
    );
    await repo.createAttempt(widget.questionId);
    _newAttemptCreated = true;
    final attempts = await repo.getAttempts(widget.questionId);
    if (!mounted || attempts.isEmpty) return;
    final latest = attempts.last;
    setState(() {
      _attempts = attempts;
      _currentAttemptNumber = latest.attemptNumber;
      _currentSubmissionDetailId = latest.id;
    });
  }
}

class _SolveStepTile extends StatelessWidget {
  const _SolveStepTile({
    required this.stepNumber,
    required this.label,
    required this.isDone,
    required this.isLocked,
    this.subtitle,
    this.onTap,
  });

  final int stepNumber;
  final String label;
  final String? subtitle;
  final bool isDone;
  final bool isLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = isDone
        ? colors.success
        : isLocked
        ? colors.disabledForeground
        : colors.textPrimary;

    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label:
          '$label${isLocked
              ? '，未解锁'
              : isDone
              ? '，已完成'
              : ''}',
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDone
                        ? colors.successContainer
                        : isLocked
                        ? colors.disabledBackground
                        : colors.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone
                          ? colors.success
                          : isLocked
                          ? colors.border
                          : colors.primaryBorder,
                    ),
                  ),
                  child: Center(
                    child: isDone
                        ? Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: colors.success,
                          )
                        : isLocked
                        ? Icon(
                            Icons.lock_outline_rounded,
                            size: 16,
                            color: colors.disabledForeground,
                          )
                        : Text(
                            '$stepNumber',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: colors.primary),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(color: foreground),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isLocked)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
