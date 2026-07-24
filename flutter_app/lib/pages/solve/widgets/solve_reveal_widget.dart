import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/widgets/md_latex_body.dart';
import 'cooling_timer.dart';
import 'done_banner.dart';

/// 填空题专用揭示流程 Widget — 纯受控组件
///
/// 交互序列：冷却 → 查看答案 → 显示正确答案 → (自评反馈) → 🎉 已完成
/// 与 SolveFlowWidget（选择题提交→判对错）完全独立。
///
/// 状态由父级通过 [revealed] prop 控制，无内部持久状态。
class SolveRevealWidget extends StatefulWidget {
  /// 冷却秒数
  final int cooldownSeconds;

  /// 正确答案文本
  final String? answerValue;

  /// 解析内容（LaTeX 可选）
  final String? explanation;

  /// 是否为回顾模式（复访时跳过冷却，直接展示结果）
  final bool isRevisit;

  /// 是否已揭示答案（由父级控制）
  final bool revealed;

  /// 下一题回调
  final VoidCallback? onNext;

  /// 评分回调
  final VoidCallback? onRate;

  /// 揭示回调（用户点击「查看答案」时触发，父级在此设 revealed=true）
  final VoidCallback? onReveal;

  /// 自评反馈（揭示答案后、已完成之前展示）
  final Widget? feedbackWidget;

  /// 自评反馈结果（反馈提交后、DoneBanner 出现前展示，与 DoneBanner 同时可见）
  final Widget? feedbackResult;

  /// 展示题库的内容 widget（stem / 选项等）
  final Widget child;

  SolveRevealWidget({
    super.key,
    this.cooldownSeconds = 10,
    this.answerValue,
    this.explanation,
    this.isRevisit = false,
    this.revealed = false,
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
  final _timerKey = GlobalKey<CoolingTimerState>();

  @override
  void initState() {
      final colors = context.colors;
    super.initState();
    if (!widget.isRevisit && !widget.revealed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _timerKey.currentState?.start();
      });
    }
  }

  void _reveal() {
      final colors = context.colors;
    widget.onReveal?.call();
  }

  @override
  Widget build(BuildContext context) {
      final colors = context.colors;
    // answerShown: 回顾模式 || 已揭示
    final answerShown = widget.isRevisit || widget.revealed;
    // done: 已过自评阶段（feedbackWidget 消失），显示 DoneBanner
    final done = answerShown && widget.feedbackWidget == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.child,
        SizedBox(height: 20),
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
                  child: Text('查看答案'),
                ),
              ),
            ),
          ),
        if (answerShown) ...[
          SizedBox(height: 16),
          // 答案卡
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('正确答案',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: colors.primary,
                    ),
                  ),
                ),
                if (widget.answerValue != null) ...[
                  SizedBox(height: 12),
                  MdLatexBody(widget.answerValue!, fontSize: 20),
                ],
              ],
            ),
          ),
          // 解析卡
          if (widget.explanation != null && widget.explanation!.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: MdLatexBody(widget.explanation!),
            ),
          ],
          // 自评区
          if (widget.revealed && widget.feedbackWidget != null) ...[
            SizedBox(height: 12),
            widget.feedbackWidget!,
          ],
          if (widget.revealed && widget.feedbackResult != null) ...[
            SizedBox(height: 12),
            widget.feedbackResult!,
          ],
        ],
        if (done) ...[
          SizedBox(height: 16),
          DoneBanner(
            onNext: widget.onNext,
            onRate: widget.onRate,
          ),
        ],
      ],
    );
  }
}
