"""PDF 视图 — 请求签名 Token + 渲染试卷 HTML"""
import hashlib
import hmac
import json
import time

from django.conf import settings
from django.http import HttpResponse, HttpResponseForbidden, HttpResponseNotFound
from django.shortcuts import get_object_or_404, render
from drf_spectacular.utils import OpenApiResponse, extend_schema
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from interactions.models import CustomPaper, CustomPaperQuestion
from courses.models import Assignment, AssignmentQuestion
from qbank.models import ChoiceExt


def _ok(data=None, message='ok'):
    return Response({'code': 0, 'message': message, 'data': data})


def _err(code, message, http_status=400):
    return Response(
        {'code': code, 'message': message, 'data': None},
        status=http_status,
    )


# ── 签名工具（O(1) 验证） ──────────────────────────────────────


PDF_KEY = settings.PDF_SECRET_KEY or ''


def _make_sig(source_id, source_type, student_id, expire):
    """生成 HMAC-SHA256 签名，编码 student_id + expire"""
    msg = '{0}:{1}:{2}:{3}'.format(source_id, source_type, student_id, expire)
    return hmac.new(
        PDF_KEY.encode(), msg.encode(), hashlib.sha256
    ).hexdigest()


def _check_sig(sig, source_id, source_type, student_id, expire):
    """O(1) 签名校验 — 直接对比 HMAC，不遍历"""
    expected = _make_sig(source_id, source_type, student_id, expire)
    return hmac.compare_digest(sig, expected)


# ── Request Token（POST /api/v1/interactions/pdf/request-token/）


@extend_schema(
    request=None,
    responses={200: OpenApiResponse(description='换取 PDF 访问签名')},
)
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def pdf_request_token(request):
    """换取 PDF 访问签名"""
    source_id = request.data.get('source_id')
    source_type = request.data.get('source_type', 'paper')

    if not source_id:
        return _err(40201, '缺少 source_id')

    if not PDF_KEY:
        return _err(50001, 'PDF 功能未配置')

    student = getattr(request.user, 'student', None)
    if not student:
        return _err(40301, '仅学生可使用 PDF')

    if source_type == 'paper':
        paper = get_object_or_404(CustomPaper, id=source_id)
        if paper.student_id != student.pk and not paper.is_public:
            return _err(40301, '无权访问该试卷')
    elif source_type == 'assignment':
        assignment = get_object_or_404(Assignment, id=source_id)
        if not student.class_group_id:
            return _err(40301, '无权访问该作业')
        has_access = assignment.class_course_assignments.filter(
            class_course__class_group_id=student.class_group_id,
            is_active=True,
        ).exists()
        if not has_access:
            return _err(40301, '无权访问该作业')
    else:
        return _err(40201, '无效的 source_type')

    expire = int(time.time()) + 300
    sig = _make_sig(source_id, source_type, student.pk, expire)

    return _ok(data={
        'sig': sig,
        'expire_in': 300,
        'url': '/pdf/view/?pid={0}&type={1}&sid={2}&exp={3}&sig={4}'.format(
            source_id, source_type, student.pk, expire, sig),
    })


# ── PDF View（GET /pdf/view）───────────────────────────────────


def _build_sections(qs):
    """组装试卷 sections，同时处理选项 dict→list 转换"""
    sections = []
    type_labels = {'choice': '选择题', 'fill': '填空题', 'solution': '解答题'}
    seen_types = set()

    # 批量查询 ChoiceExt（N+1 -> 1）
    qs_list = list(qs)
    q_ids = [pq.question_id for pq in qs_list]
    ce_map = {}
    for ce in ChoiceExt.objects.filter(question_id__in=q_ids):
        ce_map[ce.question_id] = ce

    for pq in qs_list:
        q = pq.question
        qt = q.question_type
        if qt not in seen_types:
            seen_types.add(qt)
            sections.append({
                'type': qt,
                'label': type_labels.get(qt, qt),
                'questions': [],
            })

        # 选项：JSON dict -> 渲染用 list
        opts = []
        ce = ce_map.get(q.pk)
        if ce:
            raw = json.loads(ce.options) if isinstance(ce.options, str) else ce.options
            if isinstance(raw, dict):
                opts = ['<strong>({0})</strong> {1}'.format(k, v) for k, v in raw.items()]
            elif isinstance(raw, list):
                opts = raw

        # 图片
        imgs = q.images if isinstance(q.images, list) else []

        sections[-1]['questions'].append({
            'stem': q.stem,
            'options': opts,
            'images': imgs,
        })

    return sections


def pdf_view(request):
    """渲染试卷 HTML（浏览器打印 → PDF）"""
    source_id = request.GET.get('pid')
    source_type = request.GET.get('type', 'paper')
    sig = request.GET.get('sig')
    sid = request.GET.get('sid')
    exp = request.GET.get('exp')

    if not all([source_id, sig, sid, exp]):
        return HttpResponseForbidden('缺少参数')

    if not PDF_KEY:
        return HttpResponse('PDF 功能未配置', status=503)

    # O(1) 签名校验
    try:
        source_id = int(source_id)
        student_id = int(sid)
        expire = int(exp)
    except (ValueError, TypeError):
        return HttpResponseForbidden('参数格式错误')

    if expire < int(time.time()):
        return HttpResponseForbidden('链接已过期，请重新下载')

    if not _check_sig(sig, source_id, source_type, student_id, expire):
        return HttpResponseForbidden('签名无效')

    # 查学生
    from accounts.models import Student as StudentModel
    try:
        student = StudentModel.objects.select_related('user').get(pk=student_id)
    except StudentModel.DoesNotExist:
        return HttpResponseForbidden('用户不存在')

    # 查题目
    if source_type == 'assignment':
        try:
            assignment = Assignment.objects.get(id=source_id)
        except Assignment.DoesNotExist:
            return HttpResponseNotFound('作业不存在')
        title = assignment.title
        qs = AssignmentQuestion.objects.filter(
            assignment_id=source_id
        ).order_by('sort_order').select_related('question')
    else:
        try:
            paper = CustomPaper.objects.get(id=source_id)
        except CustomPaper.DoesNotExist:
            return HttpResponseNotFound('试卷不存在')
        title = paper.title
        qs = CustomPaperQuestion.objects.filter(
            paper=paper
        ).order_by('sort_order').select_related('question')

    sections = _build_sections(qs)

    context = {
        'title': title,
        'sections': sections,
        'student_nickname': student.user.get_full_name() or student.user.username,
        'student_id_code': student.student_id,
    }

    return render(request, 'pdf/paper_view.html', context)
