import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import 'package:shared/widgets/loading_indicator.dart';
import '../../widgets/exit_rating_popup.dart';
import 'package:shared/widgets/md_latex_body.dart';
import 'package:shared/theme/app_theme.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/daos/system_config_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/progress_repository.dart' as progress;
import '../../domain/question_repository.dart';
import 'widgets/step_card_widget.dart';
import 'widgets/feedback_buttons.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

String _feedbackToStatus(FeedbackType type) {
  switch (type) {
    case FeedbackType.fullCorrect: return 'full_correct';
    case FeedbackType.partialCorrect: return 'partial_correct';
    case FeedbackType.wrong: return 'wrong';
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
  DateTime? _entryTime;

  // 题目信息
  QuestionDetail? _detail;

  // 当前存档信息
  int? _currentAttemptNumber;
  int? _currentSubmissionDetailId;
  bool _isRevisit = false;
  progress.StepSolveRecord? _existingRecord;

  @override
  void initState() { super.initState(); _entryTime = DateTime.now(); _load(); _loadCooldown(); }

  Future<void> _loadCooldown() async {
    try {
      final dao = SystemConfigDao(DatabaseProvider());
      final sec = await dao.getInt('solve_cooldown_step', 5);
      if (!mounted) return;
      setState(() => _coolDownSec = sec);
    } catch (e) { OperationLog.instance.error('solve_step_page_load', e); 
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
      try { detail = await qRepo.getDetail(widget.questionId); } catch (_) {}

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
          final stepFeedback = feedbacks.where((f) =>
              f.stepNumber == widget.stepIndex + 1 &&
              f.subQuestionIndex == widget.subQuestionIndex &&
              f.methodId == widget.methodIndex).toList();
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
        'stepCount': _currentMethodStepCount, 'currentStep': widget.stepIndex,
        'isRevisit': _isRevisit,
      });
    } catch (e) { OperationLog.instance.error('solve_step_page_load', e); 
      AuditLogger.instance.error('SolveStepPage._load', e);
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  int get _currentMethodStepCount {
    if (_state == null || _state!.subQuestions.isEmpty) return 0;
    try {
      return _state!.subQuestions[widget.subQuestionIndex]
          .solutions[widget.methodIndex].steps.length;
    } catch (_) {
      return 0;
    }
  }

  bool get _isLastStep => widget.stepIndex + 1 >= _currentMethodStepCount;

  void _goNextStep() {
    if (_isLastStep) return;
    final buf = StringBuffer('/solve/step?id=${widget.questionId}'
        '&subQ=${widget.subQuestionIndex}'
        '&method=${widget.methodIndex}&step=${widget.stepIndex + 1}');
    if (_currentSubmissionDetailId != null) {
      buf.write('&attemptId=$_currentSubmissionDetailId');
    }
    context.pushReplacement(buf.toString());
  }

  Future<void> _onFeedback(FeedbackType type) async {
      final colors = context.colors;
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
        if (mounted) RouterUtils.goBack(context);
      }
    }
  }

  progress.Step? _currentStep() {
    try {
      return _state!.subQuestions[widget.subQuestionIndex].solutions[widget.methodIndex].steps[widget.stepIndex];
    } catch (_) {
      return null;
    }
  }

  // 获取当前步骤所属的小问&方法名
  String _buildContextLabel() {
      final colors = context.colors;
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
      final colors = context.colors;
    final step = _currentStep();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (_entryTime == null) return;
        await showExitRatingIfNeeded(context, 'solve_step', _entryTime!);
        _entryTime = null;
        if (!context.mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) safePop(context);
        });
      },
      child: Scaffold(
      appBar: AppBar(title: const Text('步骤详情')),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('加载失败', style: TextStyle(color: colors.textSecondary)),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () { setState(() { _error = null; _loading = true; }); _load(); }, child: const Text('重试')),
                ]))
              : step == null
              ? const Center(child: Text('步骤数据不存在'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 上下文位置标识
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_buildContextLabel(),
                          style: TextStyle(fontSize: 13, color: colors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 精简题干
                      if (_detail != null && _detail!.stem.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: MdLatexBody(_detail!.stem, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // 步骤卡片
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
                      const SizedBox(height: 16),
                      // 底部导航栏
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => RouterUtils.goBack(context),
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text('解题地图',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    ));
  }
}

