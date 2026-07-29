from django.db import transaction
from rest_framework import status
from rest_framework.views import APIView

from accounts.permissions import IsStudent

from qbank.models import BaseQuestion, ConceptTag
from system.models import SystemConfig

from .models import (
    ContentContribution,
    ContributionReview,
    ContributionRevision,
    ContributionTagSelection,
    ContributionTagSuggestion,
)
from .serializers import ContributionWriteSerializer
from .review_services import question_payload
from .throttles import ContributionWriteThrottle
from .views import _err, _ok


DEFAULT_AI_PROMPT = '''请把图片中的高中数学题转写为严格 JSON。不要解题、改写或补充原图不存在的条件。
输出只能包含一个 JSON 对象，不要使用代码围栏。JSON 必须符合 schema_version=1，字段包括
question_type、stem、options、sub_questions、source、suggested_tags、difficulty、
calculation、uncertainties。行内公式使用 $...$，独立公式使用 $$...$$。JSON 字符串内
所有 LaTeX 反斜杠必须写成双反斜杠，例如 \\\\frac、\\\\sqrt。无法确认的字符不要猜测，
写入 uncertainties。source 内使用 source_type、year、region、source_name 和
question_number；source_name 表示试卷或资料名称，question_number 表示原题题号。'''


def _student(request):
    return getattr(request.user, 'student', None)


def _question_snapshot(question):
    try:
        options = question.choice_ext.options
    except BaseQuestion.choice_ext.RelatedObjectDoesNotExist:
        options = {}
    return {
        'id': question.pk,
        'year': question.year,
        'exam_type': question.exam_type,
        'region': question.region,
        'source_name': question.source_name,
        'number': question.number,
        'question_type': question.question_type,
        'stem': question.stem,
        'options': options,
        'sub_questions': [
            {
                'stem': item.stem or '',
                'answer': item.answer,
                'explanation': item.explanation,
                'sort_order': item.sort_order,
            }
            for item in question.sub_questions.all()
        ],
        'tags': list(question.concept_tags.values_list('name', flat=True)),
        'tag_ids': list(question.concept_tags.values_list('pk', flat=True)),
    }


def _serialize(contribution, include_detail=False):
    latest = contribution.revisions.order_by('-revision_number').first()
    data = {
        'id': contribution.pk,
        'contribution_type': contribution.contribution_type,
        'status': contribution.status,
        'question_id': contribution.question_id,
        'completed_question_id': contribution.completed_question_id,
        'published_qbank_version': contribution.published_qbank_version,
        'review_note': contribution.review_note,
        'revision_number': latest.revision_number if latest else 0,
        'created_at': contribution.created_at.isoformat(),
        'updated_at': contribution.updated_at.isoformat(),
    }
    if latest:
        payload = latest.normalized_payload
        data['summary'] = (
            payload.get('stem', '')[:100]
            if contribution.contribution_type == 'new_question'
            else payload.get('description', '')[:100]
        )
    if include_detail:
        data.update({
            'raw_json': latest.raw_json if latest else '',
            'payload': latest.normalized_payload if latest else {},
            'question_snapshot': latest.question_snapshot if latest else {},
            'tag_ids': list(
                contribution.tag_selections.values_list('concept_tag_id', flat=True)
            ),
            'selected_tags': [
                {'id': item.concept_tag_id, 'name': item.concept_tag.name}
                for item in contribution.tag_selections.select_related('concept_tag')
            ],
            'tag_suggestions': [
                {
                    'id': item.pk,
                    'name': item.suggested_name,
                    'parent_id': item.suggested_parent_id,
                    'reason': item.reason,
                    'status': item.status,
                    'resolved_tag_id': item.resolved_tag_id,
                }
                for item in contribution.tag_suggestions.all()
            ],
            'history': [
                {
                    'action': item.action,
                    'note': item.note,
                    'created_at': item.created_at.isoformat(),
                    'actor_role': (
                        'student'
                        if item.actor_id == contribution.student.user_id
                        else 'reviewer' if item.actor_id else 'system'
                    ),
                }
                for item in contribution.reviews.all()
            ],
        })
        if contribution.completed_question_id:
            data['official_payload'] = question_payload(
                contribution.completed_question
            )
            data['official_tags'] = [
                {'id': tag.pk, 'name': tag.name}
                for tag in contribution.completed_question.concept_tags.all()
            ]
    return data


def _replace_tags(contribution, tag_ids, suggestions):
    contribution.tag_selections.all().delete()
    ContributionTagSelection.objects.bulk_create([
        ContributionTagSelection(contribution=contribution, concept_tag_id=tag_id)
        for tag_id in dict.fromkeys(tag_ids)
    ])
    contribution.tag_suggestions.all().delete()
    ContributionTagSuggestion.objects.bulk_create([
        ContributionTagSuggestion(
            contribution=contribution,
            suggested_name=item['name'].strip(),
            suggested_parent_id=item.get('parent_id'),
            reason=item.get('reason', '').strip(),
        )
        for item in suggestions
    ])


class ContributionConfigView(APIView):
    permission_classes = [IsStudent]

    def get(self, request):
        tags = ConceptTag.objects.order_by('parent_id', 'name')
        prompt = SystemConfig.objects.filter(key='contribution_ai_prompt').first()
        return _ok({
            'schema_version': 1,
            'ai_prompt': prompt.value if prompt and prompt.value else DEFAULT_AI_PROMPT,
            'latex_editor_url': 'https://www.latexlive.com/',
            'tags': [
                {'id': tag.pk, 'name': tag.name, 'parent_id': tag.parent_id}
                for tag in tags
            ],
        })


class ContributionListCreateView(APIView):
    permission_classes = [IsStudent]

    def get_throttles(self):
        return [ContributionWriteThrottle()] if self.request.method == 'POST' else []

    def get(self, request):
        student = _student(request)
        if not student:
            return _err(40302, '仅学生用户可访问', status.HTTP_403_FORBIDDEN)
        items = ContentContribution.objects.filter(student=student).prefetch_related(
            'revisions'
        )
        return _ok([_serialize(item) for item in items])

    @transaction.atomic
    def post(self, request):
        student = _student(request)
        if not student:
            return _err(40302, '仅学生用户可投稿', status.HTTP_403_FORBIDDEN)
        serializer = ContributionWriteSerializer(data=request.data)
        if not serializer.is_valid():
            return _err(40201, serializer.errors)
        data = serializer.validated_data
        question = None
        if data.get('question_id') is not None:
            question = BaseQuestion.objects.filter(pk=data['question_id']).first()
            if question is None:
                return _err(40401, '题目不存在', status.HTTP_404_NOT_FOUND)
            duplicate = ContentContribution.objects.filter(
                student=student,
                question=question,
                contribution_type='question_correction',
                status__in=[
                    'pending', 'resubmitted', 'needs_revision', 'processing',
                ],
            ).exists()
            if duplicate:
                return _err(40901, '你已经有一条关于此题的待处理纠错')
        contribution = ContentContribution.objects.create(
            student=student,
            contribution_type=data['contribution_type'],
            question=question,
        )
        ContributionRevision.objects.create(
            contribution=contribution,
            revision_number=1,
            raw_json=data.get('raw_json', ''),
            normalized_payload=data['payload'],
            question_snapshot=_question_snapshot(question) if question else {},
        )
        _replace_tags(
            contribution, data.get('tag_ids', []), data.get('tag_suggestions', [])
        )
        ContributionReview.objects.create(
            contribution=contribution, actor=request.user, action='submitted'
        )
        return _ok(_serialize(contribution, include_detail=True))


class ContributionDetailView(APIView):
    permission_classes = [IsStudent]

    def get(self, request, contribution_id):
        student = _student(request)
        contribution = ContentContribution.objects.filter(
            pk=contribution_id, student=student
        ).select_related('student__user', 'completed_question').prefetch_related(
            'revisions', 'reviews', 'tag_selections__concept_tag',
            'tag_suggestions', 'completed_question__concept_tags',
        ).first()
        if contribution is None:
            return _err(40401, '贡献记录不存在', status.HTTP_404_NOT_FOUND)
        return _ok(_serialize(contribution, include_detail=True))


class ContributionResubmitView(APIView):
    permission_classes = [IsStudent]
    throttle_classes = [ContributionWriteThrottle]

    @transaction.atomic
    def post(self, request, contribution_id):
        student = _student(request)
        contribution = ContentContribution.objects.select_for_update().filter(
            pk=contribution_id, student=student,
            status=ContentContribution.Status.NEEDS_REVISION,
        ).first()
        if contribution is None:
            return _err(40901, '当前状态不能重新提交')
        incoming = request.data.copy()
        incoming['contribution_type'] = contribution.contribution_type
        incoming['question_id'] = contribution.question_id
        serializer = ContributionWriteSerializer(data=incoming)
        if not serializer.is_valid():
            return _err(40201, serializer.errors)
        data = serializer.validated_data
        latest = contribution.revisions.order_by('-revision_number').first()
        ContributionRevision.objects.create(
            contribution=contribution,
            revision_number=(latest.revision_number if latest else 0) + 1,
            raw_json=data.get('raw_json', ''),
            normalized_payload=data['payload'],
            question_snapshot=latest.question_snapshot if latest else {},
        )
        _replace_tags(
            contribution, data.get('tag_ids', []), data.get('tag_suggestions', [])
        )
        contribution.status = ContentContribution.Status.RESUBMITTED
        contribution.review_note = ''
        contribution.save(update_fields=['status', 'review_note', 'updated_at'])
        ContributionReview.objects.create(
            contribution=contribution, actor=request.user, action='resubmitted'
        )
        return _ok(_serialize(contribution, include_detail=True))


class ContributionWithdrawView(APIView):
    permission_classes = [IsStudent]

    @transaction.atomic
    def post(self, request, contribution_id):
        student = _student(request)
        contribution = ContentContribution.objects.select_for_update().filter(
            pk=contribution_id, student=student,
            status__in=[
                ContentContribution.Status.PENDING,
                ContentContribution.Status.RESUBMITTED,
            ],
        ).first()
        if contribution is None:
            return _err(40901, '当前状态不能撤回')
        contribution.status = ContentContribution.Status.WITHDRAWN
        contribution.save(update_fields=['status', 'updated_at'])
        ContributionReview.objects.create(
            contribution=contribution, actor=request.user, action='withdrawn'
        )
        return _ok(_serialize(contribution))


class ContributionQuestionContextView(APIView):
    permission_classes = [IsStudent]

    def get(self, request, question_id):
        if not _student(request):
            return _err(40302, '仅学生用户可访问', status.HTTP_403_FORBIDDEN)
        question = BaseQuestion.objects.filter(pk=question_id).prefetch_related(
            'sub_questions', 'concept_tags'
        ).first()
        if question is None:
            return _err(40401, '题目不存在', status.HTTP_404_NOT_FOUND)
        return _ok(_question_snapshot(question))
