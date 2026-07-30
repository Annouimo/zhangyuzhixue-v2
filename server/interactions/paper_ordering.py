from qbank.models import BaseQuestion


PAPER_QUESTION_TYPE_ORDER = ('choice', 'fill', 'solution')
_TYPE_RANK = {
    question_type: index
    for index, question_type in enumerate(PAPER_QUESTION_TYPE_ORDER)
}


def canonicalize_questions(questions):
    """Group by paper type while preserving order inside each type."""
    return sorted(
        list(questions),
        key=lambda question: _TYPE_RANK.get(
            question.question_type, len(_TYPE_RANK)
        ),
    )


def canonicalize_question_ids(question_ids):
    unique_ids = list(dict.fromkeys(question_ids))
    type_by_id = dict(BaseQuestion.objects.filter(
        pk__in=unique_ids,
    ).values_list('pk', 'question_type'))
    return sorted(
        unique_ids,
        key=lambda question_id: _TYPE_RANK.get(
            type_by_id.get(question_id), len(_TYPE_RANK)
        ),
    )
