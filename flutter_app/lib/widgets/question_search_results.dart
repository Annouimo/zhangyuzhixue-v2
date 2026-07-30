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
    final compactViewport = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: QuestionCard(
        questionId: question.id,
        title: question.title,
        questionType: question.questionType,
        subtitle: question.meta,
        difficulty: question.difficulty,
        onTap: onOpen,
        compact: true,
        trailing: selected == true || _selectionMode
            ? SizedBox(
                width: compactViewport ? 44 : 132,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected == true && !compactViewport)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.successContainer,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '已在试题篮',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.onSuccessContainer,
                          ),
                        ),
                      ),
                    if (_selectionMode || compactViewport)
                      IconButton(
                        tooltip: selected == true
                            ? (_selectionMode ? '移出试题篮' : '已在试题篮')
                            : '加入试题篮',
                        visualDensity: VisualDensity.compact,
                        onPressed: onToggle,
                        icon: Icon(
                          selected == true
                              ? (_selectionMode
                                    ? Icons.close_rounded
                                    : Icons.check_circle_rounded)
                              : Icons.add_circle_outline,
                          color: selected == true
                              ? (_selectionMode
                                    ? context.colors.textMuted
                                    : context.colors.success)
                              : context.colors.primary,
                        ),
                      ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
