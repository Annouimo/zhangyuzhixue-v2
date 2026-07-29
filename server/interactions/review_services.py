from django.db import transaction

from qbank.models import (
    BaseQuestion, ChoiceExt, ConceptTag, QuestionConceptTag, SubQuestion,
)

from .models import ContributionTagSelection, ContributionTagSuggestion


DIFFICULTY_VALUES = {
    'basic': 1.0, 'easy': 2.0, 'medium': 3.0, 'hard': 4.0, 'very_hard': 5.0,
}
CALCULATION_VALUES = {
    'very_low': 1.0, 'low': 2.0, 'high': 3.0, 'very_high': 4.0,
}
SOURCE_LABELS = {
    'gaokao': '高考', 'mock_exam': '模拟考试', 'school_exam': '校内考试',
    'textbook': '教材', 'self_created': '原创', 'other': '其他',
}


def question_payload(question):
    try:
        options = [
            {'key': key, 'content': value}
            for key, value in question.choice_ext.options.items()
        ]
    except ChoiceExt.DoesNotExist:
        options = []
    source_type = next(
        (key for key, label in SOURCE_LABELS.items() if label == question.exam_type),
        'other',
    )
    return {
        'schema_version': 1,
        'question_type': question.question_type,
        'stem': question.stem,
        'options': options,
        'sub_questions': [
            {
                'stem': item.stem or '',
                'answer': item.answer,
                'explanation': item.explanation,
            }
            for item in question.sub_questions.order_by('sort_order')
        ],
        'source': {
            'source_type': source_type,
            'year': question.year,
            'region': question.region,
            'source_name': question.source_name,
            'question_number': question.number,
        },
        'suggested_tags': list(question.concept_tags.values_list('name', flat=True)),
        'difficulty': min(DIFFICULTY_VALUES, key=lambda key: abs(
            DIFFICULTY_VALUES[key] - (question.difficulty or 3.0)
        )),
        'calculation': min(CALCULATION_VALUES, key=lambda key: abs(
            CALCULATION_VALUES[key] - (question.calculation or 2.0)
        )),
        'uncertainties': [],
    }


def resolve_tags(contribution, selected_tags, approved_suggestion_ids):
    tags = list(selected_tags)
    suggestions = contribution.tag_suggestions.filter(
        pk__in=approved_suggestion_ids,
        status=ContributionTagSuggestion.Status.PENDING,
    )
    for suggestion in suggestions:
        tag, created = ConceptTag.objects.get_or_create(
            name=suggestion.suggested_name.strip(),
            defaults={'parent': suggestion.suggested_parent},
        )
        suggestion.status = (
            ContributionTagSuggestion.Status.CREATED
            if created else ContributionTagSuggestion.Status.MERGED
        )
        suggestion.resolved_tag = tag
        suggestion.save(update_fields=['status', 'resolved_tag'])
        tags.append(tag)
        ContributionTagSelection.objects.get_or_create(
            contribution=contribution, concept_tag=tag
        )
    return list({tag.pk: tag for tag in tags}.values())


@transaction.atomic
def save_official_question(payload, tags, question=None):
    source = payload.get('source', {})
    values = {
        'year': source.get('year'),
        'exam_type': SOURCE_LABELS.get(source.get('source_type'), '其他'),
        'region': str(source.get('region', ''))[:32],
        'source_name': str(source.get(
            'source_name', source.get('exam_name', '')
        ))[:255],
        'number': str(source.get(
            'question_number', source.get('number', '')
        ))[:16],
        'question_type': payload['question_type'],
        'difficulty': DIFFICULTY_VALUES[payload['difficulty']],
        'calculation': CALCULATION_VALUES[payload['calculation']],
        'stem': payload['stem'].strip(),
    }
    existing_sub_questions = []
    if question is None:
        question = BaseQuestion.objects.create(**values)
    else:
        existing_sub_questions = list(
            question.sub_questions.order_by('sort_order', 'pk')
        )
        for field, value in values.items():
            setattr(question, field, value)
        question.save(update_fields=list(values))

    if payload['question_type'] == 'choice':
        ChoiceExt.objects.update_or_create(
            question=question,
            defaults={'options': {
                item['key'].strip().upper(): item['content'].strip()
                for item in payload['options']
            }},
        )
    else:
        ChoiceExt.objects.filter(question=question).delete()

    submitted_sub_questions = payload['sub_questions']
    for index, item in enumerate(submitted_sub_questions, start=1):
        values = {
            'stem': item.get('stem', '').strip() or None,
            'answer': item['answer'].strip(),
            'explanation': item.get('explanation', '').strip(),
            'sort_order': index,
        }
        if index <= len(existing_sub_questions):
            sub_question = existing_sub_questions[index - 1]
            for field, value in values.items():
                setattr(sub_question, field, value)
            sub_question.save(update_fields=list(values))
        else:
            SubQuestion.objects.create(question=question, **values)
    for stale_sub_question in existing_sub_questions[len(submitted_sub_questions):]:
        stale_sub_question.delete()
    QuestionConceptTag.objects.filter(question=question).delete()
    QuestionConceptTag.objects.bulk_create([
        QuestionConceptTag(question=question, concept_tag=tag) for tag in tags
    ])
    return question
