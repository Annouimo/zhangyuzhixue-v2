from django.db import transaction

from qbank.models import (
    BaseQuestion, ChoiceExt, ConceptTag, QuestionConceptTag, SolutionMethod,
    SolutionStep, SubQuestion,
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
    tag_names = list(question.concept_tags.values_list('name', flat=True))
    return {
        'schema_version': 2,
        'base_updated_at': question.updated_at.isoformat(),
        'question_type': question.question_type,
        'stem': question.stem,
        'options': options,
        'sub_questions': [
            {
                'id': item.pk,
                'stem': item.stem or '',
                'answer': item.answer,
                'explanation': item.explanation,
                'solution_methods': [
                    {
                        'id': method.pk,
                        'method_name': method.method_name or '',
                        'source': method.source,
                        'content_origin': method.content_origin,
                        'contributor_username': (
                            method.contributed_by.user.username
                            if method.contributed_by_id else None
                        ),
                        'steps': [
                            {
                                'id': step.pk,
                                'title': step.title,
                                'content': step.content,
                                'card_titles': step.card_titles,
                            }
                            for step in method.solution_steps.order_by('step_number')
                        ],
                    }
                    for method in item.solution_methods.order_by('sort_order')
                ],
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
        'content_origin': question.content_origin,
        'contributor_username': (
            question.contributed_by.user.username
            if question.contributed_by_id else None
        ),
        'images': question.images,
        'default_score': question.default_score,
        'suggested_tags': tag_names,
        'tags': tag_names,
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
def save_official_question(
    payload, tags, question=None, content_origin='external', contributor=None,
    replace_methods=False,
):
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
        'images': payload.get('images', []),
        'default_score': payload.get('default_score'),
        'content_origin': content_origin,
    }
    existing_sub_questions = []
    if question is None:
        question = BaseQuestion.objects.create(**values, contributed_by=contributor)
    else:
        existing_sub_questions = list(
            question.sub_questions.order_by('sort_order', 'pk')
        )
        for field, value in values.items():
            setattr(question, field, value)
        question.save()

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
        submitted_id = item.get('id')
        matching = next(
            (sub for sub in existing_sub_questions if sub.pk == submitted_id),
            None,
        ) if submitted_id else None
        if matching is not None:
            sub_question = matching
        elif question.pk and index <= len(existing_sub_questions) and not submitted_id:
            sub_question = existing_sub_questions[index - 1]
        else:
            sub_question = None
        if sub_question is not None:
            for field, value in values.items():
                setattr(sub_question, field, value)
            sub_question.save(update_fields=list(values))
        else:
            sub_question = SubQuestion.objects.create(question=question, **values)
        submitted_methods = item.get('solution_methods', [])
        if submitted_methods or replace_methods:
            _replace_solution_methods(
                sub_question, submitted_methods, contributor=contributor,
                default_origin=content_origin,
            )
    submitted_sub_ids = {item.get('id') for item in submitted_sub_questions}
    if replace_methods:
        for stale_sub_question in existing_sub_questions:
            if stale_sub_question.pk not in submitted_sub_ids:
                stale_sub_question.delete()
    QuestionConceptTag.objects.filter(question=question).delete()
    QuestionConceptTag.objects.bulk_create([
        QuestionConceptTag(question=question, concept_tag=tag) for tag in tags
    ])
    return question


@transaction.atomic
def save_solution_method(
    sub_question, payload, sort_order=None, content_origin='external',
    contributor=None,
):
    if sort_order is None:
        last = sub_question.solution_methods.order_by('-sort_order').first()
        sort_order = (last.sort_order if last else 0) + 1
    method = SolutionMethod.objects.create(
        sub_question=sub_question,
        method_name=payload.get('method_name', '').strip() or None,
        source=payload.get('source', '').strip(),
        content_origin=content_origin,
        contributed_by=contributor,
        sort_order=sort_order,
    )
    SolutionStep.objects.bulk_create([
        SolutionStep(
            method=method,
            step_number=index,
            title=step['title'].strip(),
            content=step['content'].strip(),
            card_titles=step.get('card_titles', []),
        )
        for index, step in enumerate(payload['steps'], start=1)
    ])
    return method


def _replace_solution_methods(
    sub_question, submitted_methods, contributor=None, default_origin='external',
):
    existing = {item.pk: item for item in sub_question.solution_methods.all()}
    retained = set()
    for index, payload in enumerate(submitted_methods, start=1):
        method_id = payload.get('id')
        method = existing.get(method_id)
        origin = payload.get('content_origin', default_origin)
        if method is None:
            method = save_solution_method(
                sub_question, payload, index, content_origin=origin,
                contributor=contributor,
            )
        else:
            retained.add(method.pk)
            method.method_name = payload.get('method_name', '').strip() or None
            method.source = payload.get('source', '').strip()
            method.content_origin = origin
            method.sort_order = index
            method.save(update_fields=[
                'method_name', 'source', 'content_origin', 'sort_order',
            ])
            method.solution_steps.all().delete()
            SolutionStep.objects.bulk_create([
                SolutionStep(
                    method=method,
                    step_number=step_index,
                    title=step['title'].strip(),
                    content=step['content'].strip(),
                    card_titles=step.get('card_titles', []),
                )
                for step_index, step in enumerate(payload['steps'], start=1)
            ])
    for method_id, method in existing.items():
        if method_id not in retained:
            method.delete()
