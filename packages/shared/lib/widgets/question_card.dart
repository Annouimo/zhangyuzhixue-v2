import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/widgets/md_latex_body.dart';
import 'package:shared/widgets/status_style.dart';

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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：标签行 + 尾部
              Row(
                children: [
                  _buildTypeTag(),
                  if (difficulty != null) ...[
                    const SizedBox(width: 6),
                    _buildDiffTag(),
                  ],
                  if (subtitle != null && difficulty == null) ...[
                    // 无难度标签时，subtitle 前加分隔点
                    const SizedBox(width: 6),
                    Text(subtitle!, style: const TextStyle(height: 1.2, fontSize: 11, color: AppColors.textSecondary)),
                  ],
                  const Spacer(),
                  if (status != null) ...[
                    _buildStatusTag(),
                    const SizedBox(width: 4),
                  ],
                  _buildTrailing(context),
                ],
              ),
              const SizedBox(height: 8),
              // 第二行：题干
              MdLatexBody(title, fontSize: 14),
              // 第三行（可选）：副信息（在难度和题型同一行时有 subtitle）
              if (subtitle != null && difficulty != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(subtitle!,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              // 第四行（可选）：推荐原因
              if (reason != null && reason!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text('推荐原因：$reason',
                      style: const TextStyle(fontSize: 12, color: AppColors.warning),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTag() {
    return _Tag(
      QuestionTypeLabels.of(questionType),
      bg: AppColors.primaryContainer,
      fg: AppColors.primary,
    );
  }

  Widget _buildDiffTag() {
    return _Tag(
      DifficultySegments.diffNameFor(difficulty!),
      bg: AppColors.tagDifficultyBg,
      fg: AppColors.tagDifficultyFg,
    );
  }

  Widget _buildStatusTag() {
    final style = _statusStyle(status!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        style.label,
        style: TextStyle(fontSize: 11, color: style.color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    if (trailing != null) return trailing!;
    if (selectable) {
      return Icon(
        selected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: selected ? AppColors.primary : AppColors.textSecondary,
        size: 24,
      );
    }
    return const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary);
  }
}

// ─── 辅助组件 ─────────────────────────────────────────

/// 圆角标签
class _Tag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _Tag(this.text, {required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500, height: 1.3),
      ),
    );
  }
}

/// 状态标签样式
({String label, Color color, Color bg}) _statusStyle(String status) {
  return statusStyle(status);
}
