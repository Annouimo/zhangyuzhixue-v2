import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'md_latex_body.dart';

/// 题目卡片 — 教师端简化版
///
/// 比学生端更简洁：只显示题干摘要 + 题型标签 + 难度，点击进入详情页。
/// 没有 selectable 模式、没有状态标签、没有推荐原因。
class QuestionCard extends StatelessWidget {
  final int questionId;
  final String title;
  final String questionType;
  final String? subtitle;
  final double? difficulty;
  final Widget? trailing;
  final VoidCallback? onTap;

  const QuestionCard({
    super.key,
    required this.questionId,
    required this.title,
    required this.questionType,
    this.subtitle,
    this.difficulty,
    this.trailing,
    this.onTap,
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
              Row(
                children: [
                  _buildTypeTag(),
                  if (difficulty != null) ...[
                    const SizedBox(width: 6),
                    _buildDiffTag(),
                  ],
                  if (subtitle != null && difficulty == null) ...[
                    const SizedBox(width: 6),
                    Text(subtitle!,
                      style: const TextStyle(height: 1.2, fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                  const Spacer(),
                  trailing ?? const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 8),
              MdLatexBody(title, fontSize: 14),
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
}

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
