import json

from auditlog.context import set_actor
from django.contrib import messages
from django.core.paginator import Paginator
from django.db import transaction
from django.db.models import Count, Q
from django.shortcuts import get_object_or_404, redirect, render

from qbank.models import (
    BaseQuestion, ConceptTag, ContentChangeLog, KnowledgeCard,
    QuestionKnowledgeCard,
)

from .review_forms import (
    ConceptTagWorkbenchForm, KnowledgeCardWorkbenchForm,
    QuestionWorkbenchForm,
)
from .review_services import question_payload, save_official_question
from .review_views import reviewer_required
from .workbench_revisions import record_revision


def _question_initial(question=None):
    if question is not None:
        return question_payload(question)
    return {
        'schema_version': 2,
        'question_type': 'choice',
        'stem': '',
        'options': [
            {'key': key, 'content': ''} for key in ('A', 'B', 'C', 'D')
        ],
        'sub_questions': [{
            'stem': '', 'answer': '', 'explanation': '',
            'solution_methods': [],
        }],
        'source': {
            'source_type': 'other', 'year': None, 'region': '',
            'source_name': '', 'question_number': '',
        },
        'content_origin': 'external',
        'images': [],
        'default_score': None,
        'suggested_tags': [],
        'difficulty': 'medium',
        'calculation': 'low',
        'uncertainties': [],
    }


@reviewer_required
def question_list(request):
    query = request.GET.get('q', '').strip()[:100]
    question_type = request.GET.get('type', '')
    year = request.GET.get('year', '')
    queryset = BaseQuestion.objects.all().order_by('-updated_at', '-pk')
    if query:
        if query.isdigit():
            queryset = queryset.filter(Q(pk=int(query)) | Q(stem__icontains=query))
        else:
            queryset = queryset.filter(
                Q(stem__icontains=query) | Q(source_name__icontains=query)
                | Q(region__icontains=query)
            )
    if question_type in dict(BaseQuestion.QUESTION_TYPE_CHOICES):
        queryset = queryset.filter(question_type=question_type)
    else:
        question_type = ''
    if year:
        try:
            queryset = queryset.filter(year=int(year))
        except ValueError:
            year = ''
    paginator = Paginator(queryset, 30)
    page = paginator.get_page(request.GET.get('page'))
    years = BaseQuestion.objects.exclude(year=None).values_list(
        'year', flat=True
    ).distinct().order_by('-year')
    return render(request, 'review_workbench/question_list.html', {
        'questions': page.object_list,
        'page': page,
        'total_count': paginator.count,
        'query': query,
        'question_type': question_type,
        'year': year,
        'years': years,
        'type_choices': BaseQuestion.QUESTION_TYPE_CHOICES,
    })


@reviewer_required
def question_create(request):
    return _question_editor(request)


@reviewer_required
def question_edit(request, question_id):
    question = get_object_or_404(
        BaseQuestion.objects.prefetch_related(
            'concept_tags', 'knowledge_cards',
            'sub_questions__solution_methods__solution_steps',
        ),
        pk=question_id,
    )
    return _question_editor(request, question)


def _question_editor(request, question=None):
    initial = {
        'content_json': json.dumps(
            _question_initial(question), ensure_ascii=False, indent=2
        ),
        'tags': question.concept_tags.all() if question else [],
        'knowledge_cards': question.knowledge_cards.all() if question else [],
        'version': question.updated_at.isoformat() if question else 'new',
    }
    form = QuestionWorkbenchForm(request.POST or None, initial=initial)
    if request.method == 'POST' and form.is_valid():
        with transaction.atomic(), set_actor(request.user):
            locked = None
            if question is not None:
                locked = BaseQuestion.objects.select_for_update().get(pk=question.pk)
                if form.cleaned_data['version'] != locked.updated_at.isoformat():
                    form.add_error(None, '该题目已被其他人更新，请刷新后再修改。')
            if not form.errors:
                payload = form.cleaned_data['content_json']
                content_origin = payload.get(
                    'content_origin', locked.content_origin if locked else 'external'
                )
                saved = save_official_question(
                    payload, form.cleaned_data['tags'], question=locked,
                    content_origin=content_origin, replace_methods=True,
                )
                QuestionKnowledgeCard.objects.filter(question=saved).delete()
                QuestionKnowledgeCard.objects.bulk_create([
                    QuestionKnowledgeCard(question=saved, knowledge_card=card)
                    for card in form.cleaned_data['knowledge_cards']
                ])
                ContentChangeLog.objects.create(
                    actor=request.user, question=saved, object_type='question',
                    object_id=saved.pk, object_label=saved.stem[:255],
                    action='create' if question is None else 'update',
                    note=form.cleaned_data['note'].strip(),
                )
                record_revision(
                    'question', saved, request.user,
                    'create' if question is None else 'update',
                    form.cleaned_data['note'],
                )
                messages.success(
                    request,
                    f'正式题目 #{saved.pk} 已保存，将进入下一版题库。',
                )
                return redirect('review_workbench:question_edit', question_id=saved.pk)
    history = question.workbench_changes.select_related('actor')[:20] if question else []
    return render(request, 'review_workbench/question_editor.html', {
        'form': form,
        'question': question,
        'history': history,
    })


@reviewer_required
def tag_list(request):
    query = request.GET.get('q', '').strip()[:100]
    queryset = ConceptTag.objects.select_related('parent').annotate(
        question_count=Count('questions', distinct=True)
    ).order_by('parent_id', 'name')
    if query:
        queryset = queryset.filter(name__icontains=query)
    return render(request, 'review_workbench/tag_list.html', {
        'tags': queryset, 'query': query,
    })


@reviewer_required
def tag_create(request):
    return _content_editor(request, ConceptTagWorkbenchForm, 'tag')


@reviewer_required
def tag_edit(request, object_id):
    return _content_editor(
        request, ConceptTagWorkbenchForm, 'tag',
        get_object_or_404(ConceptTag, pk=object_id),
    )


@reviewer_required
def card_list(request):
    query = request.GET.get('q', '').strip()[:100]
    queryset = KnowledgeCard.objects.annotate(
        question_count=Count('questions', distinct=True)
    ).order_by('category', 'title')
    if query:
        queryset = queryset.filter(
            Q(title__icontains=query) | Q(content__icontains=query)
        )
    return render(request, 'review_workbench/card_list.html', {
        'cards': queryset, 'query': query,
    })


@reviewer_required
def card_create(request):
    return _content_editor(request, KnowledgeCardWorkbenchForm, 'card')


@reviewer_required
def card_edit(request, object_id):
    return _content_editor(
        request, KnowledgeCardWorkbenchForm, 'card',
        get_object_or_404(KnowledgeCard, pk=object_id),
    )


def _content_editor(request, form_class, kind, instance=None):
    form = form_class(request.POST or None, instance=instance)
    if request.method == 'POST' and form.is_valid():
        with transaction.atomic(), set_actor(request.user):
            saved = form.save()
            ContentChangeLog.objects.create(
                actor=request.user, object_type=kind, object_id=saved.pk,
                object_label=str(saved)[:255],
                action='create' if instance is None else 'update',
                note=form.cleaned_data['note'].strip(),
            )
            record_revision(
                kind, saved, request.user,
                'create' if instance is None else 'update',
                form.cleaned_data['note'],
            )
        messages.success(request, '内容已保存。')
        route = 'tag_edit' if kind == 'tag' else 'card_edit'
        return redirect(f'review_workbench:{route}', object_id=saved.pk)
    return render(request, 'review_workbench/content_editor.html', {
        'form': form, 'kind': kind, 'object': instance,
    })
