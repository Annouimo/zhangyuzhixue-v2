import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../widgets/md_latex_body.dart';

/// 推荐卡片
///
/// 显示题目标题（截断）、题型标签、难度段标签、推荐理由。
/// 在推荐页和偏好推荐页复用。
class RecommendCard extends StatelessWidget {
  final String title;
  final String questionType;
  final double difficulty;
  final String reason;
  final String? status;
  final VoidCallback onTap;

  const RecommendCard({
    super.key,
    required this.title,
    required this.questionType,
    required this.difficulty,
    required this.reason,
    this.status,
    required this.onTap,
  });

  String get _diffLabel => DifficultySegments.diffNameFor(difficulty);

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
              MdLatexBody(title, fontSize: 14),
              const SizedBox(height: 8),
              Row(
                children: [
                  _tag(QuestionTypeLabels.of(questionType), AppColors.primaryLight, AppColors.primary),
                  const SizedBox(width: 6),
                  _tag(_diffLabel, Colors.orange[50]!, Colors.orange[700]!),
                  const Spacer(),
                  if (status != null)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == '进行中' ? Colors.orange[50] : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status!,
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w500,
                          color: status == '进行中' ? Colors.orange[700] : AppColors.primary,
                        ),
                      ),
                    ),
                  Text(reason, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
    );
  }
}
