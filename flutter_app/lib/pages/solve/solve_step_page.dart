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
import '../../data/daos/system_config_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/progress_repository.dart' as progress;
import '../../domain/question_repository.dart';
import 'widgets/step_card_widget.dart';
import 'widgets/feedback_buttons.dart';
import 'widgets/solve_question_surface.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import '../../widgets/pop_back_guard.dart';

String _feedbackToStatus(FeedbackType type) {
  switch (type) {
    case FeedbackType.fullCorrect:
      return 'full_correct';
    case FeedbackType.partialCorrect:
      return 'partial_correct';
    case FeedbackType.wrong:
      return 'wrong';
  }
}

/// 解答题步骤详情页
class SolveStepPage extends StatefulWidget {
  final int questionId;
  final int subQuestionIndex;
  final int methodIndex;
  final int stepIndex;
  final int? attemptId;

  const SolveStepPage({
    super.key,
    required this.questionId,
    required this.subQuestionIndex,
    required this.methodIndex,
    required this.stepIndex,
    this.attemptId,
  });
  @override
  State<SolveStepPage> createState() => _SolveStepPageState();
}

class _SolveStepPageState extends State<SolveStepPage> {
  progress.SolveProgressState? _state;
  bool _loading = true;
  int _coolDownSec = 5;
  String? _error;
  late final progress.ProgressRepository _repo;
  final PopBackGuard _popGuard = PopBackGuard();

  // 题目信息
  QuestionDetail? _detail;

  // 当前存档信息
  int? _currentAttemptNumber;
  int? _currentSubmissionDetailId;
  bool _isRevisit = false;
  progress.StepSolveRecord? _existingRecord;

  @override
  void initState() {
    super.initState();
    _load();
    _loadCooldown();
  }

  Future<void> _loadCooldown() async {
    try {
      final dao = SystemConfigDao(DatabaseProvider());
      final sec = await dao.getInt('solve_cooldown_step', 5);
      if (!mounted) return;
      setState(() => _coolDownSec = sec);
    } catch (e) {
      OperationLog.instance.error('solve_step_page_load', e);
      AuditLogger.instance.error('SolveStepPage._loadCooldown', e);
    }
  }

  Future<void> _load() async {
    _repo = progress.ProgressRepository(
      ProgressDao(DatabaseProvider()),
      QuestionDao(DatabaseProvider()),
    );
    final qRepo = QuestionRepository(
      QuestionDao(DatabaseProvider()),
      ProgressDao(DatabaseProvider()),
    );
    try {
      final s = await _repo.getSolveState(widget.questionId);
      QuestionDetail? detail;
      try {
        detail = await qRepo.getDetail(widget.questionId);
      } catch (_) {}

      // 解析存档信息
      int? attemptNumber;
      int? submissionDetailId;
      bool isRevisit = false;
      progress.StepSolveRecord? existingRecord;

      if (widget.attemptId != null) {
        // 从路由参数解析 attempt
        final dao = ProgressDao(DatabaseProvider());
        final attempts = await dao.getAttempts(widget.questionId);
        final match = attempts.where((a) => a.id == widget.attemptId).toList();
        if (match.isNotEmpty) {
          attemptNumber = match.first.attemptNumber;
          submissionDetailId = match.first.id;
          // 查询历史步骤反馈
          final feedbacks = await dao.getStepFeedbacks(match.first.id);
          final stepFeedback = feedbacks
              .where(
                (f) =>
                    f.stepNumber == widget.stepIndex + 1 &&
                    f.subQuestionIndex == widget.subQuestionIndex &&
                    f.methodId == widget.methodIndex,
              )
              .toList();
          if (stepFeedback.isNotEmpty) {
            isRevisit = true;
            existingRecord = progress.StepSolveRecord(
              stepOrder: widget.stepIndex + 1,
              feedbackGiven: true,
              feedbackType: stepFeedback.last.status,
            );
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _state = s;
        _detail = detail;
        _currentAttemptNumber = attemptNumber;
        _currentSubmissionDetailId = submissionDetailId;
        _isRevisit = isRevisit;
        _existingRecord = existingRecord;
        _loading = false;
      });
      AuditLogger.instance.page('SolveStepPage', {
        'stepCount': _currentMethodStepCount,
        'currentStep': widget.stepIndex,
        'isRevisit': _isRevisit,
      });
    } catch (e) {
      OperationLog.instance.error('solve_step_page_load', e);
      AuditLogger.instance.error('SolveStepPage._load', e);
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  int get _currentMethodStepCount {
    if (_state == null || _state!.subQuestions.isEmpty) return 0;
    try {
      return _state!
          .subQuestions[widget.subQuestionIndex]
          .solutions[widget.methodIndex]
          .steps
          .length;
    } catch (_) {
      return 0;
    }
  }

  bool get _isLastStep => widget.stepIndex + 1 >= _currentMethodStepCount;

  void _goNextStep() {
    if (_isLastStep) return;
    final buf = StringBuffer(
      '/solve/step?id=${widget.questionId}'
      '&subQ=${widget.subQuestionIndex}'
      '&method=${widget.methodIndex}&step=${widget.stepIndex + 1}',
    );
    if (_currentSubmissionDetailId != null) {
      buf.write('&attemptId=$_currentSubmissionDetailId');
    }
    context.pushReplacement(buf.toString());
  }

  Future<void> _onFeedback(FeedbackType type) async {
    await _repo.submitStepFeedback(
      questionId: widget.questionId,
      attemptNumber: _currentAttemptNumber ?? 1,
      subQuestionIndex: widget.subQuestionIndex,
      methodIndex: widget.methodIndex,
      stepNumber: widget.stepIndex + 1,
      status: _feedbackToStatus(type),
    );
    if (!_isLastStep) {
      _goNextStep();
    } else {
      // 最后一步显示完成提示后返回地图
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 该题全部步骤已完成'),
            duration: Duration(milliseconds: 1000),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.pop();
      }
    }
  }

  progress.Step? _currentStep() {
    try {
      return _state!
          .subQuestions[widget.subQuestionIndex]
          .solutions[widget.methodIndex]
          .steps[widget.stepIndex];
    } catch (_) {
      return null;
    }
  }

  // 获取当前步骤所属的小问&方法名
  String _buildContextLabel() {
    if (_state == null || _state!.subQuestions.isEmpty) return '';
    final sq = _state!.subQuestions[widget.subQuestionIndex];
    final buf = StringBuffer(sq.label);
    try {
      final m = sq.solutions[widget.methodIndex];
      if (m.methodName != null && m.methodName!.isNotEmpty) {
        buf.write(' · ${m.methodName}');
      }
    } catch (_) {}
    buf.write(' · 第 ${widget.stepIndex + 1} 步');
    final step = _currentStep();
    if (step != null && step.title.isNotEmpty) {
      buf.write(' · ${step.title}');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final step = _currentStep();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) =>
          _popGuard.handlePop(context, 'solve_step'),
      child: Scaffold(
        appBar: AppBar(title: const Text('逐步解析')),
        body: _loading
            ? const LoadingIndicator(message: '正在加载解题步骤')
            : _error != null
            ? ErrorPlaceholder(
                message: '步骤加载失败，请检查后重试',
                onRetry: () {
                  setState(() {
                    _error = null;
                    _loading = true;
                  });
                  _load();
                },
              )
            : step == null
            ? const ErrorPlaceholder(message: '步骤数据不存在')
            : AppContentContainer(
                maxWidth: AppContentWidth.reading,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            const AppStatusBadge(
                              label: '当前步骤',
                              tone: AppStatusTone.primary,
                              icon: Icons.route_rounded,
                              compact: true,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _buildContextLabel(),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: context.colors.textSecondary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_detail != null &&
                          _detail!.stem.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        SolveQuestionSurface(
                          number: _detail!.number,
                          title: _detail!.title,
                          questionTypeLabel: '解答题',
                          isReviewMode: _isRevisit,
                          conceptTags: _detail!.conceptTags,
                          stem: _detail!.stem,
                          imagePaths: _detail!.images,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      StepCardWidget(
                        cooldownSeconds: _coolDownSec,
                        step: step,
                        stepIndex: widget.stepIndex,
                        totalSteps: _currentMethodStepCount,
                        isRevisit: _isRevisit,
                        existingRecord: _existingRecord,
                        questionId: widget.questionId,
                        submissionDetailId: _currentSubmissionDetailId,
                        onFeedback: _onFeedback,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: '返回解题地图',
                        icon: Icons.map_outlined,
                        variant: AppButtonVariant.secondary,
                        fullWidth: true,
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
