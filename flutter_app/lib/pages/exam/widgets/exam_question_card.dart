import 'package:flutter/material.dart';
import '../../../widgets/md_latex_body.dart';
import '../../../domain/question_repository.dart';

/// 预览页题目卡片 — 统一 quicklook/quicklook_other 的重复代码
class ExamQuestionCard extends StatelessWidget {
  final int questionId;
  final String title;
  final String questionType;

  const ExamQuestionCard({
    super.key,
    required this.questionId,
    required this.title,
    this.questionType = 'choice',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          onTap: () => SolveRouteHelper.navigateTo(context, questionId, questionType),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: MdLatexBody(title, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
