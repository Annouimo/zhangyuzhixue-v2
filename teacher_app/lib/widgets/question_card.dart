import 'package:flutter/material.dart';
import '../../app_theme.dart';
import 'md_latex_body.dart';

/// 题目卡片 — 教师端简化版
///
/// 保留 selectable/selected/trailing 选择模式；去掉状态标签和推荐原因。
class QuestionCard extends StatelessWidget {
  final int questionId;
  final String title;
  final String questionType;

  /// 副信息行文本（如日期、来源），显示在题型/难度标签之后
  final String? subtitle;

  /// 难度值（0~10），提供时显示难度标签
  final double? difficulty;

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
                  _buildTrailing(context),
                ],
              ),
              const SizedBox(height: 8),
              // 第二行：题干
              MdLatexBody(title, fontSize: 14),
              // 第三行（可选）：副信息
              if (subtitle != null && difficulty != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(subtitle!,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTag() {
    return _Tag(
      QuestionTypeLabels.of(questionType),
      bg: AppColors.primaryLight,
      fg: AppColors.primary,
    );
  }

  Widget _buildDiffTag() {
    return _Tag(
      DifficultySegments.diffNameFor(difficulty!),
      bg: Colors.orange[50]!,
      fg: Colors.orange[700]!,
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
