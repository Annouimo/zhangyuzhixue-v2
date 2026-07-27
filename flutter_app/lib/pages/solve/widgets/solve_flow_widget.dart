import 'package:flutter/material.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_button.dart';

import 'cooling_timer.dart';
import 'done_banner.dart';
import 'solve_result_card.dart';

/// 选填解题流程的阶段
// ignore: unused_element
enum SolveStage { cooling, submitting, result, done }

/// 选择题共用流程 Widget — 纯受控组件。
class SolveFlowWidget extends StatefulWidget {
  const SolveFlowWidget({
    super.key,
    required this.child,
    this.cooldownSeconds = 10,
    this.isRevisit = false,
    this.isRated = false,
    this.isCorrect = false,
    this.showResult = false,
    this.correctAnswer,
    this.explanation,
    this.onSubmit,
    this.onNext,
    this.onRate,
    this.onFinish,
    this.submitLoading = false,
    this.nextLabel = '下一题',
  });

  final Widget child;
  final int cooldownSeconds;
  final bool isRevisit;
  final bool isRated;
  final bool isCorrect;
  final bool showResult;
  final String? correctAnswer;
  final String? explanation;
  final Future<void> Function()? onSubmit;
  final VoidCallback? onNext;
  final VoidCallback? onRate;
  final VoidCallback? onFinish;
  final bool submitLoading;
  final String nextLabel;

  @override
  State<SolveFlowWidget> createState() => _SolveFlowWidgetState();
}

class _SolveFlowWidgetState extends State<SolveFlowWidget> {
  final _timerKey = GlobalKey<CoolingTimerState>();

  @override
  void initState() {
    super.initState();
    if (!widget.isRevisit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _timerKey.currentState?.start();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final done =
        widget.isRevisit || (widget.showResult && !widget.submitLoading);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.child,
        if (!done) ...[
          const SizedBox(height: AppSpacing.lg),
          CoolingTimer(
            key: _timerKey,
            seconds: widget.cooldownSeconds,
            child: AppButton(
              label: '提交答案',
              icon: Icons.send_rounded,
              fullWidth: true,
              isLoading: widget.submitLoading,
              onPressed: widget.submitLoading || widget.onSubmit == null
                  ? null
                  : () {
                      widget.onSubmit!.call();
                    },
            ),
          ),
        ],
        if (widget.showResult || widget.isRevisit) ...[
          const SizedBox(height: AppSpacing.lg),
          SolveResultCard(
            isCorrect: widget.isCorrect,
            correctAnswer: widget.correctAnswer,
            explanation: widget.explanation,
          ),
        ],
        if (done) ...[
          const SizedBox(height: AppSpacing.md),
          DoneBanner(
            isRated: widget.isRated,
            onNext: widget.onNext,
            onRate: widget.onRate,
            onFinish: widget.onFinish,
            nextLabel: widget.nextLabel,
          ),
        ],
      ],
    );
  }
}
