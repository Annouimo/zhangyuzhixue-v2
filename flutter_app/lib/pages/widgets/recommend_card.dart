import 'package:flutter/material.dart';
import '../../../widgets/shared/question_card.dart';

/// 推荐卡片 — 委托给全局共享的 QuestionCard
///
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

  @override
  Widget build(BuildContext context) {
    return QuestionCard(
      questionId: 0,  // recommend 不需要 questionId，导航由 onTap 处理
      title: title,
      questionType: questionType,
      difficulty: difficulty,
      status: status,
      reason: reason,
      onTap: onTap,
    );
  }
}
