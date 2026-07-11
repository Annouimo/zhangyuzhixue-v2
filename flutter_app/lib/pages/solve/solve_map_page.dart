import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/progress_repository.dart' as progress;

/// 解答题地图页 — 步骤概览
class SolveMapPage extends StatefulWidget {
  final int questionId;
  const SolveMapPage({super.key, required this.questionId});
  @override
  State<SolveMapPage> createState() => _SolveMapPageState();
}

class _SolveMapPageState extends State<SolveMapPage> {
  progress.SolveProgressState? _state;
  Set<int> _completedSteps = {};
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
      // 读取完成状态
      final attempts = await repo.getAttempts(widget.questionId);
      Set<int> doneSteps = {};
      if (attempts.isNotEmpty) {
        final lastAttempt = attempts.last;
        final prevState = await repo.getAttemptState(
          widget.questionId, lastAttempt.attemptNumber,
        );
        if (prevState != null) {
          doneSteps = prevState.subQRecords
              .expand((sq) => sq.methods)
              .expand((m) => m.steps)
              .where((s) => s.feedbackGiven)
              .map((s) => s.stepOrder)
              .toSet();
        }
      }
      setState(() { _state = s; _completedSteps = doneSteps; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('解答题')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _state == null || _state!.subQuestions.isEmpty
              ? const Center(child: Text('暂无步骤数据'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _state!.subQuestions.map((sq) => _SubQuestionSection(
                    block: sq,
                    completedSteps: _completedSteps,
                    onStepTap: (mi, si) => context.push(
                      '/solve/step?id=${widget.questionId}&method=$mi&step=$si',
                    ),
                  )).toList(),
                ),
    );
  }
}

class _SubQuestionSection extends StatelessWidget {
  final progress.SubQuestionBlock block;
  final Set<int> completedSteps;
  final void Function(int m, int s) onStepTap;
  const _SubQuestionSection({required this.block, required this.completedSteps, required this.onStepTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(block.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        ...block.solutions.expand((m) =>
          m.steps.asMap().entries.map((e) => _StepIndicator(
            stepNumber: e.value.stepNumber,
            title: e.value.title,
            isCompleted: completedSteps.contains(e.value.stepNumber),
            onTap: () => onStepTap(block.solutions.indexOf(m), e.key),
          )),
        ),
      ]),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int stepNumber;
  final String title;
  final bool isCompleted;
  final VoidCallback onTap;
  const _StepIndicator({required this.stepNumber, required this.title, required this.isCompleted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Row(children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.success : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: isCompleted
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('$stepNumber', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: TextStyle(fontSize: 13, color: isCompleted ? AppColors.success : AppColors.textPrimary))),
          if (!isCompleted) const Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}
