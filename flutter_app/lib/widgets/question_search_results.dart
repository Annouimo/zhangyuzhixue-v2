import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../domain/exam_repository.dart';

class QuestionSearchResults extends StatelessWidget {
  const QuestionSearchResults({
    super.key,
    required this.questions,
    required this.onOpen,
    this.selectedIds,
    this.onToggle,
  });

  final List<SearchQuestion> questions;
  final ValueChanged<SearchQuestion> onOpen;
  final Set<int>? selectedIds;
  final ValueChanged<SearchQuestion>? onToggle;

  bool get _selectionMode => selectedIds != null && onToggle != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: questions
          .map(
            (question) => QuestionSearchResultCard(
              question: question,
              onOpen: () => onOpen(question),
              selected: selectedIds?.contains(question.id),
              onToggle: _selectionMode ? () => onToggle!(question) : null,
            ),
          )
          .toList(growable: false),
    );
  }
}

class QuestionSearchResultCard extends StatelessWidget {
  const QuestionSearchResultCard({
    super.key,
    required this.question,
    required this.onOpen,
    this.selected,
    this.onToggle,
  });

  final SearchQuestion question;
  final VoidCallback onOpen;
  final bool? selected;
  final VoidCallback? onToggle;

  bool get _selectionMode => selected != null && onToggle != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: QuestionCard(
        questionId: question.id,
        title: question.title,
        questionType: question.questionType,
        subtitle: question.meta,
        difficulty: question.difficulty,
        onTap: onOpen,
        trailing: _selectionMode
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: selected! ? '移出试卷' : '加入试卷',
                    visualDensity: VisualDensity.compact,
                    onPressed: onToggle,
                    icon: Icon(
                      selected! ? Icons.check_circle : Icons.add_circle_outline,
                      color: selected!
                          ? context.colors.primary
                          : context.colors.textSecondary,
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
