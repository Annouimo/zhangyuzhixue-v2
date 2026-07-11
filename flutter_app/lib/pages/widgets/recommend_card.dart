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
  final VoidCallback onTap;

  const RecommendCard({
    super.key,
    required this.title,
    required this.questionType,
    required this.difficulty,
    required this.reason,
    required this.onTap,
  });

  static const _segLabels = ['基础', '中档', '中难', '较难', '压轴'];
  static const _segBreaks = [0.0, 3.0, 5.0, 7.0, 8.5, 10.0];
  static const _typeLabels = {'choice': '选择题', 'fill': '填空题', 'solution': '解答题'};

  String get _diffLabel {
    final idx = _segBreaks.lastIndexWhere((b) => difficulty >= b);
    return _segLabels[idx.clamp(0, _segLabels.length - 1)];
  }

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
                  _tag(_typeLabels[questionType] ?? questionType, AppColors.primaryLight, AppColors.primary),
                  const SizedBox(width: 6),
                  _tag(_diffLabel, Colors.orange[50]!, Colors.orange[700]!),
                  const Spacer(),
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
