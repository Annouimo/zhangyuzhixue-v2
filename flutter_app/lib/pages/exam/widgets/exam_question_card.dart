import 'package:flutter/material.dart';
import '../../../domain/question_repository.dart';
import '../../../widgets/shared/question_card.dart';

/// 预览页题目卡片 — 委托给全局共享的 QuestionCard
///
/// 保持此文件作为向后兼容的 Thin Wrapper。
class ExamQuestionCard extends StatelessWidget {
  final int questionId;
  final String title;
  final String questionType;

  const ExamQuestionCard({
    super.key,
    required this.questionId,
    required this.title,
    required this.questionType,
  });

  @override
  Widget build(BuildContext context) {
    return QuestionCard(
      questionId: questionId,
      title: title,
      questionType: questionType,
      onTap: () => SolveRouteHelper.navigateTo(context, questionId, questionType),
    );
  }
}
