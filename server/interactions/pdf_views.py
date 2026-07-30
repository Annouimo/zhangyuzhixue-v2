"""PDF 视图 — 请求签名 Token + 渲染试卷 HTML"""
import hashlib
import hmac
import json
import re
import time
from collections import defaultdict
from urllib.parse import urlencode

from django.conf import settings
from django.http import HttpResponse, HttpResponseForbidden, HttpResponseNotFound
from django.shortcuts import get_object_or_404, render
from django.db.models import IntegerField
from django.db.models.functions import Cast
from drf_spectacular.utils import OpenApiResponse, extend_schema
from rest_framework.decorators import api_view, permission_classes, throttle_classes
from accounts.permissions import IsStudent
from rest_framework.response import Response

from interactions.models import CustomPaper, CustomPaperQuestion
from qbank.models import (
    BaseQuestion, ChoiceExt, SolutionMethod, SolutionStep, SubQuestion,
)
from accounts.throttles import PdfTokenRateThrottle


def _ok(data=None, message='ok'):
    return Response({'code': 0, 'message': message, 'data': data})


def _err(code, message, http_status=400):
    return Response(
        {'code': code, 'message': message, 'data': None},
        status=http_status,
    )


# ── 签名工具（O(1) 验证） ──────────────────────────────────────


PDF_KEY = settings.PDF_SECRET_KEY or ''
PDF_LINK_TTL_SECONDS = 30 * 60


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


def _virtual_paper_source(data):
    if not isinstance(data, dict):
        raise ValueError('缺少套卷来源')
    try:
        year = int(data.get('year'))
    except (TypeError, ValueError):
        raise ValueError('套卷年份无效')
    exam_type = data.get('exam_type')
    region = data.get('region')
    if not isinstance(exam_type, str) or not exam_type.strip():
        raise ValueError('套卷考试类型无效')
    if not isinstance(region, str) or not region.strip():
        raise ValueError('套卷地区无效')
    if len(exam_type) > 32 or len(region) > 32:
        raise ValueError('套卷来源参数过长')
    return {
        'year': year,
        'exam_type': exam_type.strip(),
        'region': region.strip(),
    }


def _canonical_source(source):
    return json.dumps(
        source, ensure_ascii=False, sort_keys=True, separators=(',', ':'),
    )


def _virtual_paper_questions(source):
    return list(
        BaseQuestion.objects.filter(
            year=source['year'],
            exam_type=source['exam_type'],
            region=source['region'],
        ).annotate(
            numeric_number=Cast('number', IntegerField()),
        ).order_by('numeric_number', 'number', 'pk')
    )


# ── Request Token（POST /api/v1/interactions/pdf/request-token/）


@extend_schema(
    request=None,
    responses={200: OpenApiResponse(description='换取 PDF 访问签名')},
)
@api_view(['POST'])
@permission_classes([IsStudent])
@throttle_classes([PdfTokenRateThrottle])
def pdf_request_token(request):
    """换取 PDF 访问签名"""
    source_id = request.data.get('source_id')
    source_type = request.data.get('source_type', 'paper')

    if not PDF_KEY:
        return _err(50001, 'PDF 功能未配置')

    student = getattr(request.user, 'student', None)
    if not student:
        return _err(40301, '仅学生可使用 PDF')

    if source_type == 'paper':
        if not source_id:
            return _err(40201, '缺少 source_id')
        paper = get_object_or_404(CustomPaper, id=source_id)
        if paper.student_id != student.pk and not paper.is_public:
            return _err(40301, '无权访问该试卷')
        signed_source = str(source_id)
    elif source_type == 'virtual_paper':
        try:
            source = _virtual_paper_source(request.data.get('source'))
        except ValueError as error:
            return _err(40201, str(error))
        if not _virtual_paper_questions(source):
            return _err(40401, '套卷不存在', http_status=404)
        signed_source = _canonical_source(source)
    else:
        return _err(40201, '无效的 source_type')

    expire = int(time.time()) + PDF_LINK_TTL_SECONDS
    sig = _make_sig(signed_source, source_type, student.pk, expire)

    query = {
        'pid': signed_source,
        'type': source_type,
        'sid': student.pk,
        'exp': expire,
        'sig': sig,
    }

    return _ok(data={
        'sig': sig,
        'expire_in': PDF_LINK_TTL_SECONDS,
        'url': '/pdf/view/?' + urlencode(query),
    })


# ── PDF View（GET /pdf/view）───────────────────────────────────


NUM_CN = ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十']


def _md_table_to_html(text):
    """Markdown 表格 → HTML <table>，用于 stem 中的纯文本表格"""
    if '|' not in text or '---' not in text:
        return text

    lines = text.split('\n')
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # 检测表格开始：当前行含 | 且下一行含 ---
        if '|' in line and i + 1 < len(lines) and '---' in lines[i + 1]:
            rows = []
            while i < len(lines) and '|' in lines[i]:
                rows.append(lines[i])
                i += 1
            # 跳过分隔行（含 ---），取数据行
            data = [r for r in rows if '---' not in r.strip()]
            if not data:
                result.append(rows[0])
                continue
            # 构建 HTML table
            html = [
                '<table border="0" style="border-collapse:collapse;'
                'width:100%;margin:0.5em 0;text-align:center">',
            ]
            for ri, row in enumerate(data):
                cells = [c.strip() for c in row.strip().strip('|').split('|')]
                tag = 'th' if ri == 0 else 'td'
                html.append('<tr>' + ''.join(
                    '<{0}>{1}</{0}>'.format(tag, c) for c in cells
                ) + '</tr>')
            html.append('</table>')
            result.append(''.join(html))
        else:
            result.append(line)
            i += 1
    return '\n'.join(result)


def _prepare_images(images):
    if not isinstance(images, list):
        return []
    return [
        {
            'path': path,
            'is_option_grid': path.endswith('_options.webp'),
        }
        for path in images
        if isinstance(path, str) and path
    ]


def _answer_to_html(text):
    """保留答案中的 LaTeX 定界符，并将文本换行转为 HTML。"""
    if not text:
        return ''
    return _md_table_to_html(text).replace('\n', '<br>')


def _chunked(items, size):
    return [items[index:index + size] for index in range(0, len(items), size)]


def _content_warnings(text, question_number):
    warnings = []
    if text.count('$') % 2:
        warnings.append('第 {0} 题可能存在未闭合的公式定界符'.format(question_number))
    stripped = re.sub(r'\$[^$]*\$', '', text)
    if re.search(r'\\(?:alpha|beta|gamma|underline|dfrac|sqrt)\b', stripped):
        warnings.append('第 {0} 题可能存在未渲染的 LaTeX'.format(question_number))
    if re.search(r'(?:第|条件|由|则|求|为|当|如果)\s*$', text.strip()):
        warnings.append('第 {0} 题内容可能不完整'.format(question_number))
    return warnings


def _build_sections(qs):
    """组装试卷 sections，同时处理选项 dict→list 转换"""
    sections = []
    type_labels = {'choice': '选择题', 'fill': '填空题', 'solution': '解答题'}

    # 批量查询 ChoiceExt + SubQuestion（N+1 -> 1）
    qs_list = list(qs)
    q_ids = [question.pk for question in qs_list]

    ce_map = {}
    for ce in ChoiceExt.objects.filter(question_id__in=q_ids):
        ce_map[ce.question_id] = ce

    sq_map = defaultdict(list)
    sub_questions = list(SubQuestion.objects.filter(
        question_id__in=q_ids
    ).order_by('sort_order'))
    for sq in sub_questions:
        sq_map[sq.question_id].append(sq)

    sub_ids = [sq.pk for sq in sub_questions]
    method_map = defaultdict(list)
    methods = list(SolutionMethod.objects.filter(
        sub_question_id__in=sub_ids
    ).order_by('sort_order'))
    for method in methods:
        method_map[method.sub_question_id].append(method)

    step_map = defaultdict(list)
    for step in SolutionStep.objects.filter(
        method_id__in=[method.pk for method in methods]
    ).order_by('step_number'):
        step_map[step.method_id].append(step)

    seen_types = []
    question_counter = 0
    for q in qs_list:
        qt = q.question_type
        question_counter += 1

        if qt not in seen_types:
            seen_types.append(qt)
            idx = len(seen_types) - 1
            num_prefix = NUM_CN[idx] if idx < len(NUM_CN) else str(idx + 1)
            sections.append({
                'type': qt,
                'label': type_labels.get(qt, qt),
                'numbered_label': '{0}、{1}'.format(
                    num_prefix, type_labels.get(qt, qt)),
                'questions': [],
            })

        # 选项：JSON dict -> 渲染用 list
        opts = []
        ce = ce_map.get(q.pk)
        if ce:
            try:
                raw = json.loads(ce.options) if isinstance(
                    ce.options, str) else ce.options
            except (json.JSONDecodeError, TypeError):
                raw = None
            if isinstance(raw, dict):
                opts = [{'key': k, 'content': v} for k, v in raw.items()]
            elif isinstance(raw, list):
                opts = [{'key': '', 'content': value} for value in raw]

        # 图片
        imgs = _prepare_images(q.images)

        # 子题（仅解答题需要拼接）
        full_stem = q.stem or ''
        if qt == 'solution':
            sqs = sq_map.get(q.pk, [])
            extra_parts = []
            for sq in sqs:
                if not sq.stem:
                    continue
                # 跳过冗余版本（子题内容本身就是完整题目的重复）
                if len(sq.stem) > 40 and (q.stem or '')[:20] in sq.stem[:40]:
                    continue
                # 如果 stem 中已有此子题内容，跳过
                snippet = sq.stem[:40].strip()
                if snippet and (full_stem or '') and snippet in full_stem:
                    continue
                extra_parts.append((sq, sq.stem))
            if extra_parts:
                full_stem = (full_stem or '') + '<br>' + '<br>'.join(
                    '({0}) {1}'.format(sq.sort_order, sp)
                    for sq, sp in extra_parts
                )

        full_stem = _md_table_to_html(full_stem)
        # stem 中的换行在 HTML <p> 内不可见，转成 <br>
        full_stem = full_stem.replace('\n', '<br>')

        question_subs = sq_map.get(q.pk, [])
        answers = [sq.answer for sq in question_subs if sq.answer]
        sub_details = []
        for sub_index, sq in enumerate(question_subs, start=1):
            method_details = []
            for method_index, method in enumerate(
                method_map.get(sq.pk, []), start=1
            ):
                steps = [{
                    'number': step.step_number,
                    'title': step.title,
                    'content_html': _answer_to_html(step.content),
                } for step in step_map.get(method.pk, []) if step.content]
                if steps:
                    method_details.append({
                        'title': method.method_name or '解法 {0}'.format(
                            method_index),
                        'show_title': bool(method.method_name) or len(
                            method_map.get(sq.pk, [])) > 1,
                        'steps': steps,
                    })
            sub_details.append({
                'number': sub_index,
                'show_number': len(question_subs) > 1,
                'answer_html': _answer_to_html(sq.answer),
                'explanation_html': _answer_to_html(sq.explanation),
                'methods': method_details,
                'has_detail': bool(method_details or sq.explanation),
            })

        question_data = {
            'number': question_counter,
            'stem': full_stem,
            'options': opts,
            'images': imgs,
            'score': q.default_score,
            'sub_questions': sub_details,
            'answers': answers,
            'answer_html': '<br>'.join(
                _answer_to_html(answer) for answer in answers
            ),
        }
        question_data['has_detailed_answer'] = any(
            sub['has_detail'] for sub in sub_details
        )
        warning_text = [q.stem or '']
        for sq in question_subs:
            warning_text.extend([sq.stem or '', sq.answer, sq.explanation])
            for method in method_map.get(sq.pk, []):
                warning_text.extend(
                    step.content for step in step_map.get(method.pk, [])
                )
        question_data['warnings'] = list(dict.fromkeys(_content_warnings(
            '\n'.join(warning_text), question_counter
        )))
        sections[-1]['questions'].append(question_data)

    return sections


def _build_answer_sections(sections):
    by_type = {section['type']: section['questions'] for section in sections}
    choice_questions = by_type.get('choice', [])
    return {
        'choice_rows': _chunked(choice_questions, 5),
        'choice_sheet_rows': _chunked(choice_questions, 10),
        'fill_questions': by_type.get('fill', []),
        'solution_questions': by_type.get('solution', []),
    }


def _build_print_warnings(sections):
    return [warning for section in sections
            for question in section['questions']
            for warning in question['warnings']]


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
        student_id = int(sid)
        expire = int(exp)
    except (ValueError, TypeError):
        return HttpResponseForbidden('参数格式错误')

    if expire < int(time.time()):
        return render(request, 'pdf/link_expired.html', status=403)

    if not _check_sig(sig, source_id, source_type, student_id, expire):
        return HttpResponseForbidden('签名无效')

    # 查学生
    from accounts.models import Student as StudentModel
    try:
        student = StudentModel.objects.select_related('user').get(pk=student_id)
    except StudentModel.DoesNotExist:
        return HttpResponseForbidden('用户不存在')

    if source_type == 'paper':
        try:
            paper = CustomPaper.objects.get(id=int(source_id))
        except (CustomPaper.DoesNotExist, TypeError, ValueError):
            return HttpResponseNotFound('试卷不存在')
        title = paper.title
        links = CustomPaperQuestion.objects.filter(
            paper=paper
        ).order_by('sort_order').select_related('question')
        qs = [link.question for link in links]
    elif source_type == 'virtual_paper':
        try:
            source = _virtual_paper_source(json.loads(source_id))
        except (ValueError, TypeError, json.JSONDecodeError):
            return HttpResponseForbidden('参数格式错误')
        qs = _virtual_paper_questions(source)
        if not qs:
            return HttpResponseNotFound('套卷不存在')
        title = '{year}{region}{exam_type}'.format(**source)
    else:
        return HttpResponseForbidden('无效的来源类型')

    sections = _build_sections(qs)

    context = {
        'title': title,
        'sections': sections,
        'answer_sections': _build_answer_sections(sections),
        'print_warnings': _build_print_warnings(sections),
        'student_nickname': student.user.get_full_name() or student.user.username,
        'student_id_code': student.student_id,
    }

    return render(request, 'pdf/paper_view.html', context)
