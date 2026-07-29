"""同步推送视图 — 接收客户端 batch 数据，按 entity_type 分发处理"""

import json

from django.db import transaction
from drf_spectacular.utils import OpenApiResponse, extend_schema
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from interactions.models import (
    CardFeedback,
    CustomPaper,
    CustomPaperQuestion,
    PageSatisfactionFeedback,
    PaperCollect,
    PaperLike,
    PreferenceFilter,
    QuestionRating,
    StepFeedback,
    StudentSubmission,
    SubmissionDetail,
)
from interactions.serializers import SyncPushSerializer
from django.db.models import F as DbF, Sum
from accounts.permissions import IsStudent

ENTITY_ORDER = [
    'submission',
    'step_feedback',
    'card_feedback',
    'question_rating',
    'custom_paper',
    'paper_like',
    'paper_collect',
    'exitRating',
    'preference',
    'points_transaction',
]

# ── 响应工具 ──────────────────────────────────────────────────


def _ok(data=None):
    return Response({'code': 0, 'message': 'ok', 'data': data})


def _err(code, detail, http_status=status.HTTP_400_BAD_REQUEST):
    return Response(
        {'code': code, 'message': detail, 'data': None},
        status=http_status,
    )


class SyncPushView(APIView):
    """接收同步推送 batch，按 entity_type 分发"""

    @extend_schema(
        request=SyncPushSerializer,
        responses={200: OpenApiResponse(description='同步推送成功，返回 server_ids 映射')},
    )
    def post(self, request):
        serializer = SyncPushSerializer(data=request.data)
        if not serializer.is_valid():
            return _err(40301, '请求格式错误')

        batch = serializer.validated_data['batch']
        student = request.user.student if hasattr(request.user, 'student') else None
        if not student:
            return _err(40301, '仅学生可提交数据')

        try:
            result = self._process_batch(batch, student)
            self._increment_user_version(student)
        except Exception as e:
            return _err(50000, str(e),
                        http_status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        return _ok({'server_ids': result})

    @transaction.atomic
    def _process_batch(self, batch, student):
        """事务内处理全部 batch item，返回 local_id → server_id 映射"""
        server_ids = {}
        detail_cache = {}  # local_submission_id → local_detail_ids[]

        # 按 ENTITY_ORDER 排序，确保 submission 先于 step_feedback/card_feedback
        entity_rank = {name: i for i, name in enumerate(ENTITY_ORDER)}
        batch.sort(key=lambda item: entity_rank.get(item['entity_type'], 999))

        for item in batch:
            entity_type = item['entity_type']
            local_id = item['local_id']
            data = item['data']
            # 注入 local_id 供 handler 使用（避免改 handler 签名）
            data['_local_id'] = local_id

            handler = getattr(self, f'_handle_{entity_type}', None)
            if handler is None:
                continue

            obj = handler(data, student, server_ids, detail_cache)
            server_ids[local_id] = obj.pk

        return server_ids

    def _increment_user_version(self, student):
        """批量推送成功后递增用户 data_version"""
        from accounts.models import Student
        Student.objects.filter(pk=student.pk).update(
            data_version=DbF('data_version') + 1
        )

    # ── 各 entity_type 处理器 ─────────────────────────────────

    def _handle_submission(self, data, student, server_ids, detail_cache):
        # 创建提交头
        submission = StudentSubmission.objects.create(
            student=student,
        )
        detail_cache[submission.pk] = []

        # 创建明细
        details = data.get('details', [])
        for d in details:
            detail = SubmissionDetail.objects.create(
                submission=submission,
                question_id=d['question_id'],
                attempt_number=d.get('attempt_number', 1),
                status=d.get('status', 'completed'),
                answer_text=d.get('answer_text', ''),
                is_correct=d.get('is_correct'),
            )
            detail_cache[submission.pk].append(detail.pk)

        return submission

    def _handle_step_feedback(self, data, student, server_ids, detail_cache):
        detail_id = data.get('submission_detail_id')
        if detail_id is None:
            # 如果 detail_cache 为空（没有前置 submission），自动创建
            if not detail_cache:
                sub = StudentSubmission.objects.create(student=student)
                detail = SubmissionDetail.objects.create(
                    submission=sub,
                    question_id=data['question_id'],
                    attempt_number=data.get('attempt_number', 1),
                )
                detail_cache[sub.pk] = [detail.pk]
            for sub_id in detail_cache:
                if detail_cache[sub_id]:
                    detail_id = detail_cache[sub_id][-1]
                    break
        return StepFeedback.objects.create(
            submission_detail_id=detail_id,
            question_id=data['question_id'],
            sub_question_index=data.get('sub_question_index', 0),
            method_id=data.get('method_id'),
            step_number=data['step_number'],
            status=data['status'],
        )

    def _handle_card_feedback(self, data, student, server_ids, detail_cache):
        detail_id = data.get('submission_detail_id')
        # 如果 submission_detail_id 为 null，从 detail_cache 取最近创建的 detail_id
        if detail_id is None:
            # 如果 detail_cache 为空（没有前置 submission），自动创建
            if not detail_cache:
                sub = StudentSubmission.objects.create(student=student)
                detail = SubmissionDetail.objects.create(
                    submission=sub,
                    question_id=data['question_id'],
                )
                detail_cache[sub.pk] = [detail.pk]
            for sub_id in detail_cache:
                if detail_cache[sub_id]:
                    detail_id = detail_cache[sub_id][-1]
                    break
        return CardFeedback.objects.create(
            submission_detail_id=detail_id,
            question_id=data['question_id'],
            card_title=data['card_title'],
            card_status=data['card_status'],
        )

    def _handle_question_rating(self, data, student, server_ids, detail_cache):
        rating, _ = QuestionRating.objects.update_or_create(
            student=student,
            question_id=data['question_id'],
            defaults={
                'difficulty_score': data.get('difficulty_score', 0),
                'calculation_score': data.get('calculation_score', 0),
                'elegance_score': data.get('elegance_score', 0),
            },
        )
        return rating

    def _handle_custom_paper(self, data, student, server_ids, detail_cache):
        paper = CustomPaper.objects.create(
            student=student,
            title=data['title'],
            description=data.get('description', ''),
            filter_snapshot=data.get('filter_snapshot', {}),
            is_public=data.get('is_public', False),
        )
        questions = data.get('questions', [])
        for idx, qid in enumerate(questions):
            CustomPaperQuestion.objects.create(
                paper=paper,
                question_id=qid,
                sort_order=idx,
            )
        return paper

    def _handle_paper_like(self, data, student, server_ids, detail_cache):
        like, _ = PaperLike.objects.get_or_create(
            student=student,
            paper_id=data['paper_id'],
        )
        return like

    def _handle_paper_collect(self, data, student, server_ids, detail_cache):
        collect, _ = PaperCollect.objects.get_or_create(
            student=student,
            paper_id=data['paper_id'],
        )
        return collect

    def _handle_exitRating(self, data, student, server_ids, detail_cache):
        """处理退出评价反馈"""
        return PageSatisfactionFeedback.objects.create(
            user=student.user,
            page_url=data.get('page_url', ''),
            rating=data.get('score', 5),
            comment=data.get('feedback', ''),
            device_type=data.get('device_type'),
        )

    def _handle_preference(self, data, student, server_ids, detail_cache):
        """处理筛选预设保存（含 json 序列化 + client_id 唯一键）"""
        client_id = data.get('_local_id')

        def _json(v):
            if isinstance(v, (list, tuple)):
                return json.dumps(v, ensure_ascii=False)
            return v or '[]'

        pref, _ = PreferenceFilter.objects.update_or_create(
            student=student,
            client_id=client_id,
            defaults={
                'name': data.get('name', ''),
                'years': _json(data.get('years')),
                'regions': _json(data.get('regions')),
                'concept_tags': _json(data.get('concept_tags')),
                'types': _json(data.get('types')),
                'knowledge_cards': _json(data.get('knowledge_cards')),
                'question_types': _json(data.get('question_types')),
                'diff_min': data.get('diff_min'),
                'diff_max': data.get('diff_max'),
                'calc_min': data.get('calc_min'),
                'calc_max': data.get('calc_max'),
            },
        )
        return pref

    def _handle_points_transaction(self, data, student, server_ids, detail_cache):
        """处理积分流水同步（含 client_id 幂等保护）"""
        from system.models import PointsTransaction
        from django.utils import timezone
        import datetime

        created_at_str = data.get('created_at')
        if created_at_str:
            try:
                created_at = datetime.datetime.fromisoformat(created_at_str)
                if timezone.is_naive(created_at):
                    created_at = timezone.make_aware(created_at)
            except (ValueError, TypeError):
                created_at = timezone.now()
        else:
            created_at = timezone.now()

        local_id = data.get('_local_id')
        source = data.get('source', '')
        source_object_id = data.get('source_object_id')
        amount = data.get('amount', 0)
        if source == 'RATING_REWARD':
            from system.models import SystemConfig

            if source_object_id is None:
                raise ValueError('题目评价奖励缺少题目 ID')
            if not QuestionRating.objects.filter(
                student=student,
                question_id=source_object_id,
            ).exists():
                raise ValueError('尚未提交该题评价')
            existing = PointsTransaction.objects.filter(
                student=student,
                source='RATING_REWARD',
                source_object_id=source_object_id,
            ).first()
            if existing is not None:
                return existing
            config = SystemConfig.objects.filter(
                key='question_rating_reward',
            ).first()
            try:
                amount = float(config.value) if config else 0.3
            except (TypeError, ValueError):
                amount = 0.3
        pt, _ = PointsTransaction.objects.update_or_create(
            student=student,
            client_id=local_id,
            defaults={
                'amount': amount,
                'transaction_type': data.get('transaction_type', 'EARN'),
                'source': source,
                'source_object_id': source_object_id,
                'description': data.get('description', ''),
                'created_at': created_at,
            },
        )
        return pt


# ── 组卷发现/预览 API ──────────────────────────────────────────


class ExamExploreView(APIView):
    """获取全平台公开组卷列表（不含当前用户自己的）"""
    permission_classes = [IsStudent]

    @extend_schema(
        responses={200: OpenApiResponse(description='公开组卷列表')},
    )
    def get(self, request):
        student = getattr(request.user, 'student', None)
        if not student:
            return _err(40302, '仅学生用户可访问')

        # 查所有公开组卷（不含自己的）
        papers = CustomPaper.objects.filter(
            is_public=True
        ).order_by('-created_at').prefetch_related(
            'paper_questions', 'paper_likes', 'paper_collects'
        )

        result = []
        for p in papers:
            like_count = p.paper_likes.count()
            collect_count = p.paper_collects.count()
            author_student = p.student
            author_user = author_student.user
            # 作者等级
            from system.models import LevelConfig
            total_pts = author_student.points_transactions.aggregate(
                total=Sum('amount')
            )['total'] or 0
            level = LevelConfig.get_level(total_pts)
            result.append({
                'id': p.pk,
                'name': p.title,
                'author_name': author_user.username if author_user else '',
                'author_level': level,
                'author_points': total_pts,
                'summary': (
                    f'选择 {p.questions.filter(question_type="choice").count()} 题 · '
                    f'填空 {p.questions.filter(question_type="fill").count()} 题 · '
                    f'解答 {p.questions.filter(question_type="solution").count()} 题 · '
                    f'共 {p.questions.count()} 题'
                ),
                'like_count': like_count,
                'collect_count': collect_count,
                'is_liked': p.paper_likes.filter(student=student).exists(),
                'is_collected': p.paper_collects.filter(student=student).exists(),
                'created_at': p.created_at.isoformat() if p.created_at else '',
            })

        return _ok(data=result)


class ExamPreviewOtherView(APIView):
    """获取他人组卷预览详情"""
    permission_classes = [IsStudent]

    @extend_schema(
        responses={200: OpenApiResponse(description='组卷预览详情')},
    )
    def get(self, request, paper_id):
        student = getattr(request.user, 'student', None)
        if not student:
            return _err(40302, '仅学生用户可访问')

        try:
            paper = CustomPaper.objects.get(pk=paper_id, is_public=True)
        except CustomPaper.DoesNotExist:
            return _err(40401, '组卷不存在或未公开')

        questions = paper.paper_questions.order_by('sort_order').select_related('question')

        q_list = []
        for pq in questions:
            q = pq.question
            q_list.append({
                'question_id': q.pk,
                'title': f'{q.number} {q.exam_type} {q.region}',
                'question_type': q.question_type,
            })

        choice_count = sum(1 for q in q_list if q['question_type'] == 'choice')
        fill_count = sum(1 for q in q_list if q['question_type'] == 'fill')
        solution_count = sum(1 for q in q_list if q['question_type'] == 'solution')

        like_count = paper.paper_likes.count()
        collect_count = paper.paper_collects.count()
        is_liked = paper.paper_likes.filter(student=student).exists()
        is_collected = paper.paper_collects.filter(student=student).exists()

        author_student = paper.student
        author_user = author_student.user
        from system.models import LevelConfig
        total_pts = author_student.points_transactions.aggregate(
            total=Sum('amount')
        )['total'] or 0
        level = LevelConfig.get_level(total_pts)

        return _ok(data={
            'name': paper.title,
            'author_name': author_user.username if author_user else '',
            'author_level': level,
            'author_points': total_pts,
            'choice_count': choice_count,
            'fill_count': fill_count,
            'solution_count': solution_count,
            'total_count': len(q_list),
            'like_count': like_count,
            'collect_count': collect_count,
            'is_liked': is_liked,
            'is_collected': is_collected,
            'created_at': paper.created_at.isoformat() if paper.created_at else '',
            'questions': q_list,
        })


class ExamFavoritesView(APIView):
    """获取收藏组卷的详情列表（按 paper_id 批量查询）"""
    permission_classes = [IsStudent]

    @extend_schema(
        responses={200: OpenApiResponse(description='收藏组卷详情列表')},
    )
    def post(self, request):
        student = getattr(request.user, 'student', None)
        if not student:
            return _err(40302, '仅学生用户可访问')

        paper_ids = request.data.get('paper_ids', [])
        if not paper_ids:
            return _ok(data=[])

        papers = CustomPaper.objects.filter(
            pk__in=paper_ids, is_public=True
        ).prefetch_related('paper_likes', 'paper_collects', 'paper_questions')

        result = []
        for p in papers:
            like_count = p.paper_likes.count()
            collect_count = p.paper_collects.count()
            author_student = p.student
            author_user = author_student.user
            from system.models import LevelConfig
            total_pts = author_student.points_transactions.aggregate(
                total=Sum('amount')
            )['total'] or 0
            level = LevelConfig.get_level(total_pts)

            choice_count = p.questions.filter(question_type='choice').count()
            fill_count = p.questions.filter(question_type='fill').count()
            solution_count = p.questions.filter(question_type='solution').count()

            result.append({
                'id': p.pk,
                'name': p.title,
                'author_name': author_user.username if author_user else '',
                'author_level': level,
                'summary': (
                    f'选择 {choice_count} 题 · 填空 {fill_count} 题 · '
                    f'解答 {solution_count} 题 · 共 {choice_count + fill_count + solution_count} 题'
                ),
                'like_count': like_count,
                'collect_count': collect_count,
                'is_liked': p.paper_likes.filter(student=student).exists(),
                'created_at': p.created_at.isoformat() if p.created_at else '',
            })

        return _ok(data=result)
