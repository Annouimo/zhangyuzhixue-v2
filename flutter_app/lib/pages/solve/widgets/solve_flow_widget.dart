import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../widgets/md_latex_body.dart';
import 'cooling_timer.dart';

/// 选填解题流程的阶段
enum SolveStage { cooling, submitting, result, done }

/// 选填共用流程 Widget
class SolveFlowWidget extends StatefulWidget {
  final Widget child;
  final int cooldownSeconds;
  final bool isRevisit;
  final bool isRated;
  final bool isCorrect;
  final String? correctAnswer;
  final String? explanation;
  final VoidCallback? onSubmit;
  final VoidCallback? onNext;
  final VoidCallback? onRate;
  final bool submitLoading;

  const SolveFlowWidget({
    super.key,
    required this.child,
    this.cooldownSeconds = 10,
    this.isRevisit = false,
    this.isRated = false,
    this.isCorrect = false,
    this.correctAnswer,
    this.explanation,
    this.onSubmit,
    this.onNext,
    this.onRate,
    this.submitLoading = false,
  });

  @override
  State<SolveFlowWidget> createState() => _SolveFlowWidgetState();
}

class _SolveFlowWidgetState extends State<SolveFlowWidget> {
  bool _resultShown = false;
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

  void _submit() {
    widget.onSubmit?.call();
    setState(() => _resultShown = true);
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.isRevisit || (_resultShown && !widget.submitLoading);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.child,
        const SizedBox(height: 20),
        if (!done)
          CoolingTimer(
            key: _timerKey,
            seconds: widget.cooldownSeconds,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.submitLoading ? null : _submit,
                child: widget.submitLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,
                        ),
                      )
                    : const Text('提交'),
              ),
            ),
          ),
        if (_resultShown || widget.isRevisit) ...[
          const SizedBox(height: 16),
          _ResultBanner(
            isCorrect: widget.isCorrect,
            correctAnswer: widget.correctAnswer,
            explanation: widget.explanation,
          ),
        ],
        if (done) ...[
          const SizedBox(height: 16),
          _DoneBanner(
            isRated: widget.isRated,
            onNext: widget.onNext,
            onRate: widget.onRate,
          ),
        ],
      ],
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final bool isCorrect;
  final String? correctAnswer;
  final String? explanation;

  const _ResultBanner({
    required this.isCorrect,
    this.correctAnswer,
    this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(isCorrect ? Icons.check_circle : Icons.cancel,
              color: color, size: 20),
            const SizedBox(width: 8),
            Text(isCorrect ? '回答正确' : '回答错误',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: color,
              ),
            ),
          ]),
          if (correctAnswer != null && !isCorrect) ...[
            const SizedBox(height: 8),
            MdLatexBody('正确答案：$correctAnswer'),
          ],
          if (explanation != null && explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            MdLatexBody(explanation!),
          ],
        ],
      ),
    );
  }
}

class _DoneBanner extends StatelessWidget {
  final bool isRated;
  final VoidCallback? onNext;
  final VoidCallback? onRate;

  const _DoneBanner({this.isRated = false, this.onNext, this.onRate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Text('🎉', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(isRated ? '已完成 ⭐ 已评分' : '已完成',
          style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary,
          ),
        ),
        const Spacer(),
        if (onNext != null)
          TextButton.icon(
            onPressed: onNext,
            icon: const Text('下一题'),
            label: const Icon(Icons.arrow_forward, size: 16),
          ),
        if (onRate != null)
          TextButton(
            onPressed: onRate,
            child: const Text('⭐ 评分'),
          ),
      ]),
    );
  }
}
