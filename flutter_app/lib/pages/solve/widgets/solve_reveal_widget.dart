import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/widgets/md_latex_body.dart';
import 'cooling_timer.dart';
import 'done_banner.dart';

/// 填空题专用揭示流程 Widget
///
/// 交互序列：冷却 → 查看答案 → 显示正确答案 → (自评反馈) → 🎉 已完成
/// 与 SolveFlowWidget（选择题提交→判对错）完全独立。
class SolveRevealWidget extends StatefulWidget {
  /// 冷却秒数
  final int cooldownSeconds;

  /// 正确答案文本
  final String? answerValue;

  /// 解析内容（LaTeX 可选）
  final String? explanation;

  /// 是否为回顾模式（复访时跳过冷却，直接展示结果）
  final bool isRevisit;

  /// 下一题回调
  final VoidCallback? onNext;

  /// 评分回调
  final VoidCallback? onRate;

  /// 揭示回调（用户点击「查看答案」时触发，可在此记录状态）
  final VoidCallback? onReveal;

  /// 自评反馈（揭示答案后、已完成之前展示）
  final Widget? feedbackWidget;

  /// 自评反馈结果（反馈提交后、DoneBanner 出现前展示，与 DoneBanner 同时可见）
  final Widget? feedbackResult;

  /// 展示题库的内容 widget（stem / 选项等）
  final Widget child;

  const SolveRevealWidget({
    super.key,
    this.cooldownSeconds = 10,
    this.answerValue,
    this.explanation,
    this.isRevisit = false,
    this.onNext,
    this.onRate,
    this.onReveal,
    this.feedbackWidget,
    this.feedbackResult,
    required this.child,
  });

  @override
  State<SolveRevealWidget> createState() => _SolveRevealWidgetState();
}

class _SolveRevealWidgetState extends State<SolveRevealWidget> {
  bool _revealed = false;
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

  void _reveal() {
    setState(() => _revealed = true);
    widget.onReveal?.call();
  }

  @override
  Widget build(BuildContext context) {
    // answerShown: 冷却结束或复访，答案/解析已可见
    final answerShown = widget.isRevisit || _revealed;
    // done: 已过自评阶段（feedbackWidget 消失），显示 DoneBanner
    final done = answerShown && widget.feedbackWidget == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.child,
        const SizedBox(height: 20),
        if (!answerShown)
          CoolingTimer(
            key: _timerKey,
            seconds: widget.cooldownSeconds,
            label: '可查看',
            child: FractionallySizedBox(
              widthFactor: 1,
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _reveal,
                  child: const Text('查看答案'),
                ),
              ),
            ),
          ),
        if (answerShown) ...[
          const SizedBox(height: 16),
          // 答案卡
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('正确答案',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary,
                    ),
                  ),
                ),
                if (widget.answerValue != null) ...[
                  const SizedBox(height: 12),
                  MdLatexBody(widget.answerValue!, fontSize: 20),
                ],
              ],
            ),
          ),
          // 解析卡
          if (widget.explanation != null && widget.explanation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: MdLatexBody(widget.explanation!),
            ),
          ],
          // 自评区
          if (_revealed && widget.feedbackWidget != null) ...[
            const SizedBox(height: 12),
            widget.feedbackWidget!,
          ],
          if (_revealed && widget.feedbackResult != null) ...[
            const SizedBox(height: 12),
            widget.feedbackResult!,
          ],
        ],
        if (done) ...[
          const SizedBox(height: 16),
          DoneBanner(
            onNext: widget.onNext,
            onRate: widget.onRate,
          ),
        ],
      ],
    );
  }
}
