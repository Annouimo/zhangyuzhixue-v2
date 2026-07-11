import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/exit_rating_popup.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/daos/system_config_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/progress_repository.dart' as progress;
import 'widgets/step_card_widget.dart';
import 'widgets/feedback_buttons.dart';
import '../../data/debug/audit_logger.dart';

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
  final int methodIndex;
  final int stepIndex;
  const SolveStepPage({
    super.key,
    required this.questionId,
    required this.methodIndex,
    required this.stepIndex,
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

  @override
  void initState() { super.initState(); _entryTime = DateTime.now(); _load(); _loadCooldown(); }

  Future<void> _loadCooldown() async {
    try {
      final dao = SystemConfigDao(DatabaseProvider().assetsDb);
      final sec = await dao.getInt('solve_cooldown_step', 5);
      if (!mounted) return;
      setState(() => _coolDownSec = sec);
    } catch (e) {
      AuditLogger.instance.error('SolveStepPage._loadCooldown', e);
      debugPrint('_loadCooldown error: $e');
    }
  }

  Future<void> _load() async {
    _repo = progress.ProgressRepository(
      ProgressDao(DatabaseProvider().appDb),
      QuestionDao(DatabaseProvider().assetsDb),
    );
    try {
      final s = await _repo.getSolveState(widget.questionId);
      setState(() { _state = s; _loading = false; });
      AuditLogger.instance.page('SolveStepPage', {'stepCount': _totalSteps, 'currentStep': widget.stepIndex});
    } catch (e) {
      AuditLogger.instance.error('SolveStepPage._load', e);
      debugPrint('_load error: $e');
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  int get _totalSteps {
    if (_state == null) return 0;
    return _state!.subQuestions
        .expand((sq) => sq.solutions)
        .expand((m) => m.steps)
        .length;
  }

  bool get _isLastStep => widget.stepIndex >= _totalSteps - 1;

  void _goNextStep() {
    if (_isLastStep) return;
    context.pushReplacement(
      '/solve/step?id=${widget.questionId}&method=${widget.methodIndex}&step=${widget.stepIndex + 1}',
    );
  }

  Future<void> _onFeedback(FeedbackType type) async {
    await _repo.submitStepFeedback(
      questionId: widget.questionId,
      attemptNumber: 1,
      stepNumber: widget.stepIndex + 1,
      status: _feedbackToStatus(type),
    );
    // 不是最后一步 → 自动导航到下一步
    if (!_isLastStep) {
      _goNextStep();
    }
  }

  progress.Step? _currentStep() {
    try {
      return _state!.subQuestions[0].solutions[widget.methodIndex].steps[widget.stepIndex];
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _currentStep();
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _entryTime == null) return;
        final shown = await showExitRatingIfNeeded(context, 'solve_step', _entryTime!);
        if (shown && context.mounted) context.pop();
      },
      child: Scaffold(
      appBar: AppBar(title: Text('步骤 ${widget.stepIndex + 1}')),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('加载失败', style: TextStyle(color: Color(0xFF6B7280))),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () { setState(() { _error = null; _loading = true; }); _load(); }, child: const Text('重试')),
                ]))
              : step == null
              ? const Center(child: Text('步骤数据不存在'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: StepCardWidget(
                    cooldownSeconds: _coolDownSec,
                    step: step,
                    stepIndex: widget.stepIndex,
                    totalSteps: _totalSteps,
                    onFeedback: _onFeedback,
                  ),
                ),
    ));
  }
}
