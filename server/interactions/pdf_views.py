"""PDF 视图 — 请求签名 Token + 渲染试卷 HTML"""
import hashlib
import hmac
import json
import time

from django.conf import settings
from django.http import HttpResponse, HttpResponseForbidden
from django.shortcuts import get_object_or_404, render
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from interactions.models import CustomPaper, CustomPaperQuestion
from courses.models import Assignment, AssignmentQuestion


def _ok(data=None, message='ok'):
    return Response({'code': 0, 'message': message, 'data': data})


def _err(code, message, http_status=400):
    return Response(
        {'code': code, 'message': message, 'data': None},
        status=http_status,
    )


# ── 签名工具 ──────────────────────────────────────────────────


PDF_KEY = settings.PDF_SECRET_KEY or ''


def _make_sig(source_id, source_type, student_id, expire):
    msg = '{0}:{1}:{2}:{3}'.format(source_id, source_type, student_id, expire)
    return hmac.new(
        PDF_KEY.encode(), msg.encode(), hashlib.sha256
    ).hexdigest()


def _validate_sig(sig, source_id, source_type):
    """验证签名，成功返回 (student_id, expire)"""
    from accounts.models import Student
    now = int(time.time())
    for expire in (now + 300, now + 299, now + 298, now - 1, now):
        for student in Student.objects.all().iterator():
            expected = _make_sig(source_id, source_type, student.pk, expire)
            if hmac.compare_digest(sig, expected):
                if expire < now:
                    return None, None
                return student.pk, expire
    return None, None


# ── Request Token（POST /api/v1/pdf/request-token/）───────────


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def pdf_request_token(request):
    """换取 PDF 访问签名"""
    source_id = request.data.get('source_id')
    source_type = request.data.get('source_type', 'paper')

    if not source_id:
        return _err(40001, '缺少 source_id')

    if not PDF_KEY:
        return _err(50000, 'PDF 功能未配置')

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
        return _err(40001, '无效的 source_type')

    expire = int(time.time()) + 300
    sig = _make_sig(source_id, source_type, student.pk, expire)

    return _ok(data={
        'sig': sig,
        'expire_in': 300,
        'url': '/pdf/view?pid={0}&type={1}&sig={2}'.format(
            source_id, source_type, sig),
    })


# ── PDF View（GET /pdf/view）───────────────────────────────────


def pdf_view(request):
    """渲染试卷 HTML（浏览器打印 → PDF）"""
    source_id = request.GET.get('pid')
    source_type = request.GET.get('type', 'paper')
    sig = request.GET.get('sig')

    if not all([source_id, sig]):
        return HttpResponseForbidden('缺少参数')

    if not PDF_KEY:
        return HttpResponse('PDF 功能未配置', status=503)

    student_id, expire = _validate_sig(sig, source_id, source_type)
    if not student_id:
        return HttpResponseForbidden('链接无效或已过期')
    if expire and expire < int(time.time()):
        return HttpResponseForbidden('链接已过期，请重新下载')

    from accounts.models import Student as StudentModel
    try:
        student = StudentModel.objects.select_related('user').get(pk=student_id)
    except StudentModel.DoesNotExist:
        return HttpResponseForbidden('用户不存在')

    if source_type == 'assignment':
        assignment = get_object_or_404(Assignment, id=source_id)
        title = assignment.title
        qs = AssignmentQuestion.objects.filter(
            assignment_id=source_id
        ).order_by('sort_order').select_related('question')
    else:
        paper = get_object_or_404(CustomPaper, id=source_id)
        title = paper.title
        qs = CustomPaperQuestion.objects.filter(
            paper=paper
        ).order_by('sort_order').select_related('question')

    # 组装 sections
    sections = []
    type_labels = {'choice': '选择题', 'fill': '填空题', 'solution': '解答题'}
    seen_types = set()

    for pq in qs:
        q = pq.question
        qt = q.question_type
        if qt not in seen_types:
            seen_types.add(qt)
            sections.append({
                'type': qt,
                'label': type_labels.get(qt, qt),
                'questions': [],
            })

        # 查选项
        from qbank.models import ChoiceExt
        try:
            ce = ChoiceExt.objects.get(question_id=q.pk)
            opts = json.loads(ce.options) if isinstance(ce.options, str) else ce.options
        except (ChoiceExt.DoesNotExist, json.JSONDecodeError, TypeError):
            opts = []

        # 查图片
        imgs = q.images if isinstance(q.images, list) else []

        sections[-1]['questions'].append({
            'stem': q.stem,
            'options': opts,
            'images': imgs,
        })

    context = {
        'title': title,
        'sections': sections,
        'student_nickname': student.user.get_full_name() or student.user.username,
        'student_id_code': student.student_id,
    }

    return render(request, 'pdf/paper_view.html', context)
