import 'package:flutter/material.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/progress_repository.dart' as progress;
import 'widgets/step_card_widget.dart';

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

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final repo = progress.ProgressRepository(
      ProgressDao(DatabaseProvider().appDb),
      QuestionDao(DatabaseProvider().assetsDb),
    );
    try {
      final s = await repo.getSolveState(widget.questionId);
      setState(() { _state = s; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
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
    return Scaffold(
      appBar: AppBar(title: Text('步骤 ${widget.stepIndex + 1}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : step == null
              ? const Center(child: Text('步骤数据不存在'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: StepCardWidget(
                    step: step,
                    stepIndex: widget.stepIndex,
                    totalSteps: _state!.subQuestions
                        .expand((sq) => sq.solutions)
                        .expand((m) => m.steps)
                        .length,
                    onFeedback: (type) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('已记录反馈: $type'),
                        behavior: SnackBarBehavior.floating,
                      ));
                    },
                  ),
                ),
    );
  }
}
