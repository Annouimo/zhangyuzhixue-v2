import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/widgets/md_latex_body.dart';
import 'cooling_timer.dart';
import 'done_banner.dart';

/// 选填解题流程的阶段
enum SolveStage { cooling, submitting, result, done }

/// 选填共用流程 Widget — 纯受控组件
///
/// 状态由父级通过 props 控制，无内部持久状态：
/// - [showResult]: 是否显示结果条（父级在提交成功后设为 true）
/// - [isRevisit]: 是否为回顾模式（父级读取已完成的尝试时设为 true）
class SolveFlowWidget extends StatefulWidget {
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
  final bool submitLoading;

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
    this.submitLoading = false,
  });

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

  Future<void> _submit() async {
    await widget.onSubmit?.call();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.isRevisit || (widget.showResult && !widget.submitLoading);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.child,
        const SizedBox(height: 20),
        if (!done)
          CoolingTimer(
            key: _timerKey,
            seconds: widget.cooldownSeconds,
            child: FractionallySizedBox(
              widthFactor: 1,
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: widget.submitLoading ? null : _submit,
                  child: widget.submitLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,
                          ),
                        )
                      : const Text('提交答案'),
                ),
              ),
            ),
          ),
        if (widget.showResult || widget.isRevisit) ...[
          const SizedBox(height: 16),
          _ResultBanner(
            isCorrect: widget.isCorrect,
            correctAnswer: widget.correctAnswer,
            explanation: widget.explanation,
          ),
        ],
        if (done) ...[
          const SizedBox(height: 16),
          DoneBanner(
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
