import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../md_latex_body.dart';

/// 题目卡片 — 跨页面共享组件
///
/// 在以下 6 个页面复用：
/// - 推荐页（智能/偏好）
/// - 组卷预览页（自己的/他人的）
/// - 做题历史页
/// - 自主选题页
///
/// 两种交互模式：
/// - 导航模式（默认）：点击跳转到解题页，尾部显示 chevron_right
/// - 选择模式（selectable=true）：点击切换选中态，尾部显示 checkbox/radio
class QuestionCard extends StatelessWidget {
  final int questionId;
  final String title;
  final String questionType;

  /// 副信息行文本（如日期、来源），显示在题型/难度标签之后
  final String? subtitle;

  /// 难度值（0~10），提供时显示难度标签
  final double? difficulty;

  /// 做题状态：'pending' / 'in_progress' / 'completed'
  final String? status;

  /// 推荐原因（推荐页专用）
  final String? reason;

  /// 选择模式：true 时尾部显示 checkbox 替代默认的 chevron
  final bool selectable;

  /// 选择模式下的选中态
  final bool selected;

  /// 点击回调，为 null 时卡片不可点击
  final VoidCallback? onTap;

  /// 完全自定义尾部组件，覆盖默认的 chevron/checkbox
  final Widget? trailing;

  const QuestionCard({
    super.key,
    required this.questionId,
    required this.title,
    required this.questionType,
    this.subtitle,
    this.difficulty,
    this.status,
    this.reason,
    this.selectable = false,
    this.selected = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              MdLatexBody(title, fontSize: 14),
              const SizedBox(height: 6),
              // 标签行
              Row(
                children: [
                  _tag(QuestionTypeLabels.of(questionType)),
                  const SizedBox(width: 6),
                  if (difficulty != null) ...[
                    _tag('难度 ${difficulty!.toStringAsFixed(1)}'),
                    const SizedBox(width: 6),
                  ],
                  if (subtitle != null) ...[
                    Text(subtitle!, style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted,
                    )),
                  ],
                ],
              ),
              // 推荐原因
              if (reason != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(reason!, style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary,
                    )),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(
        fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500,
      )),
    );
  }
}

/// 题型中文标签
class QuestionTypeLabels {
  static String of(String type) {
    switch (type) {
      case 'choice': return '选择题';
      case 'fill': return '填空题';
      case 'solution': return '解答题';
      default: return type;
    }
  }
}
