import 'package:flutter/material.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_button.dart';

import 'cooling_timer.dart';
import 'done_banner.dart';
import 'solve_result_card.dart';

/// 填空题专用揭示流程 Widget — 纯受控组件。
class SolveRevealWidget extends StatefulWidget {
  const SolveRevealWidget({
    super.key,
    this.cooldownSeconds = 10,
    this.answerValue,
    this.explanation,
    this.isRevisit = false,
    this.revealed = false,
    this.onNext,
    this.onRate,
    this.onFinish,
    this.onReveal,
    this.feedbackWidget,
    this.feedbackResult,
    required this.child,
  });

  final int cooldownSeconds;
  final String? answerValue;
  final String? explanation;
  final bool isRevisit;
  final bool revealed;
  final VoidCallback? onNext;
  final VoidCallback? onRate;
  final VoidCallback? onFinish;
  final VoidCallback? onReveal;
  final Widget? feedbackWidget;
  final Widget? feedbackResult;
  final Widget child;

  @override
  State<SolveRevealWidget> createState() => _SolveRevealWidgetState();
}

class _SolveRevealWidgetState extends State<SolveRevealWidget> {
  final _timerKey = GlobalKey<CoolingTimerState>();

  @override
  void initState() {
    super.initState();
    if (!widget.isRevisit && !widget.revealed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _timerKey.currentState?.start();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final answerShown = widget.isRevisit || widget.revealed;
    final done = answerShown && widget.feedbackWidget == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.child,
        if (!answerShown) ...[
          const SizedBox(height: AppSpacing.lg),
          CoolingTimer(
            key: _timerKey,
            seconds: widget.cooldownSeconds,
            label: '可查看答案',
            child: AppButton(
              label: '查看答案',
              icon: Icons.visibility_rounded,
              fullWidth: true,
              onPressed: widget.onReveal,
            ),
          ),
        ],
        if (answerShown) ...[
          const SizedBox(height: AppSpacing.lg),
          SolveAnswerRevealCard(
            answer: widget.answerValue?.trim().isNotEmpty == true
                ? widget.answerValue!
                : '暂无标准答案',
            explanation: widget.explanation,
          ),
          if (widget.revealed && widget.feedbackWidget != null) ...[
            const SizedBox(height: AppSpacing.md),
            widget.feedbackWidget!,
          ],
          if (widget.revealed && widget.feedbackResult != null) ...[
            const SizedBox(height: AppSpacing.md),
            widget.feedbackResult!,
          ],
        ],
        if (done) ...[
          const SizedBox(height: AppSpacing.md),
          DoneBanner(
            onNext: widget.onNext,
            onRate: widget.onRate,
            onFinish: widget.onFinish,
          ),
        ],
      ],
    );
  }
}
