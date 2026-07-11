"""教师端 API 视图 — 作业/组卷/班级/学生 共 9 端点"""
from datetime import timedelta

from django.db.models import Count, Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.utils import OpenApiResponse, extend_schema
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from accounts.models import Student, UserLoginLog
from accounts.permissions import IsTeacher
from courses.models import (
    Assignment,
    AssignmentQuestion,
    ClassCourse,
    ClassCourseAssignment,
    ClassGroup,
)
from courses.teacher_serializers import (
    CreateAssignmentSerializer,
    PatchAssignmentSerializer,
)
from interactions.models import (
    CustomPaper,
    StepFeedback,
    StudentSubmission,
    SubmissionDetail,
)
from qbank.models import QuestionConceptTag

# ── 响应工具 ──────────────────────────────────────────────────


def _ok(data=None, message='ok'):
    return Response({'code': 0, 'message': message, 'data': data})


def _err(code, message, http_status=status.HTTP_400_BAD_REQUEST):
    return Response(
        {'code': code, 'message': message, 'data': None},
        status=http_status,
    )


# ── 辅助聚合函数 ──────────────────────────────────────────────


def _count_class_students(class_group_id):
    """班级学生总数"""
    return Student.objects.filter(class_group_id=class_group_id).count()


def _class_completed_count(class_group_id, assignment_id):
    """该班级中完成指定作业的学生数"""
    return StudentSubmission.objects.filter(
        assignment_id=assignment_id,
        student__class_group_id=class_group_id,
        details__is_correct__isnull=False,
    ).distinct().count()


def _class_accuracy(class_group_id, assignment_id):
    """该班级指定作业的平均正确率"""
    details = SubmissionDetail.objects.filter(
        submission__assignment_id=assignment_id,
        submission__student__class_group_id=class_group_id,
        is_correct__isnull=False,
    )
    total = details.count()
    if total == 0:
        return '0%'
    correct = details.filter(is_correct=True).count()
    return f'{round(correct / total * 100)}%'


def _calc_class_accuracy(class_group_id):
    """该班级所有学生跨所有作业的平均正确率"""
    details = SubmissionDetail.objects.filter(
        submission__student__class_group_id=class_group_id,
        is_correct__isnull=False,
    )
    total = details.count()
    if total == 0:
        return '0%'
    correct = details.filter(is_correct=True).count()
    return f'{round(correct / total * 100)}%'


def _calc_overall_accuracy():
    """全校平均正确率（所有班级/所有作业）"""
    details = SubmissionDetail.objects.filter(is_correct__isnull=False)
    total = details.count()
    if total == 0:
        return '0%'
    correct = details.filter(is_correct=True).count()
    return f'{round(correct / total * 100)}%'


def _count_student_submissions(student_id):
    """学生总提交题数"""
    return SubmissionDetail.objects.filter(
        submission__student_id=student_id,
    ).count()


def _calc_student_accuracy(student_id):
    """学生个人正确率"""
    details = SubmissionDetail.objects.filter(
        submission__student_id=student_id,
        is_correct__isnull=False,
    )
    total = details.count()
    if total == 0:
        return '0%'
    correct = details.filter(is_correct=True).count()
    return f'{round(correct / total * 100)}%'


def _last_active_date(student_id):
    """最近提交日期"""
    last = SubmissionDetail.objects.filter(
        submission__student_id=student_id,
    ).order_by('-created_at').first()
    if last is None:
        return None
    return last.created_at.strftime('%Y-%m-%d')


# ── 组卷 ──────────────────────────────────────────────────────


@extend_schema(
    responses={200: OpenApiResponse(description='组卷列表')},
)
@api_view(['GET'])
@permission_classes([IsAuthenticated, IsTeacher])
def paper_list(request):
    """组卷列表"""
    papers = CustomPaper.objects.annotate(
        q_count=Count('paper_questions'),
    ).order_by('-created_at')
    data = [{
        'id': p.id, 'title': p.title,
        'questionCount': p.q_count,
        'createdAt': p.created_at,
    } for p in papers]
    return _ok(data=data)


# ── 班级 ──────────────────────────────────────────────────────


@extend_schema(
    responses={200: OpenApiResponse(description='班级概览')},
)
@api_view(['GET'])
@permission_classes([IsAuthenticated, IsTeacher])
def class_list(request):
    """班级概览 — 统计卡片 + 列表"""
    groups = ClassGroup.objects.annotate(s_count=Count('students'))
    items = []
    total_students = 0
    for g in groups:
        total_students += g.s_count
        items.append({
            'id': g.id,
            'name': g.name,
            'studentCount': g.s_count,
            'avgAccuracy': _calc_class_accuracy(g.id),
        })
    return _ok(data={
        'totalClasses': groups.count(),
        'totalStudents': total_students,
        'avgAccuracy': _calc_overall_accuracy(),
        'items': items,
    })


# ── 学生 ──────────────────────────────────────────────────────


@extend_schema(
    responses={200: OpenApiResponse(description='学生列表')},
)
@api_view(['GET'])
@permission_classes([IsAuthenticated, IsTeacher])
def student_list(request):
    """学生列表 — 支持 ?search=&class_id= 筛选"""
    qs = Student.objects.select_related('user', 'class_group')
    search = request.query_params.get('search', '')
    class_id = request.query_params.get('class_id', '')
    if search:
        qs = qs.filter(
            Q(user__first_name__icontains=search) |
            Q(user__username__icontains=search)
        )
    if class_id.isdigit():
        qs = qs.filter(class_group_id=int(class_id))
    data = [{
        'id': s.id,
        'name': s.user.first_name or s.user.username,
        'className': s.class_group.name if s.class_group else '',
        'totalQuestions': _count_student_submissions(s.id),
        'avgAccuracy': _calc_student_accuracy(s.id),
        'lastActive': _last_active_date(s.id),
    } for s in qs]
    return _ok(data=data)


@extend_schema(
    responses={200: OpenApiResponse(description='学生详情')},
)
@api_view(['GET'])
@permission_classes([IsAuthenticated, IsTeacher])
def student_detail(request, id):
    """学生详情 — 个人信息 + 概览卡片 + 趋势 + 薄弱知识点"""
    s = get_object_or_404(
        Student.objects.select_related('user', 'class_group'),
        pk=id,
    )

    # 基本信息
    base = {
        'id': s.id,
        'name': s.user.first_name or s.user.username,
        'className': s.class_group.name if s.class_group else '',
        'studentId': s.student_id,
        'school': s.school,
        'registeredAt': s.created_at.strftime('%Y-%m-%d'),
    }

    # 概览卡片
    total_q = _count_student_submissions(s.id)
    accuracy = _calc_student_accuracy(s.id)
    streak_days = UserLoginLog.objects.filter(
        student=s,
    ).count()
    week_ago = timezone.now() - timedelta(days=7)
    weekly_q = SubmissionDetail.objects.filter(
        submission__student=s,
        created_at__gte=week_ago,
    ).count()

    overview = {
        'totalQuestions': total_q,
        'avgAccuracy': accuracy,
        'streakDays': streak_days,
        'weeklyQuestions': weekly_q,
    }

    # 正确率趋势（近30天）
    thirty_days_ago = timezone.now() - timedelta(days=30)
    table = SubmissionDetail._meta.db_table
    trend_raw = (
        SubmissionDetail.objects
        .filter(submission__student=s, created_at__gte=thirty_days_ago)
        .extra(select={'date': f"date({table}.created_at)"})
        .values('date')
        .annotate(
            total=Count('id'),
            correct=Count('id', filter=Q(is_correct=True)),
        )
        .order_by('date'))
    accuracy_trend = []
    for row in trend_raw:
        t = row['total']
        accuracy_trend.append({
            'date': row['date'],
            'accuracy': round(row['correct'] / t * 100, 1) if t else 0,
        })

    # 薄弱知识点
    wrong_step_qids = (
        StepFeedback.objects
        .filter(
            submission_detail__submission__student=s,
        )
        .exclude(status='full_correct')
        .values_list('question_id', flat=True)
        .distinct()
    )
    tag_records = (
        QuestionConceptTag.objects
        .filter(question_id__in=list(wrong_step_qids))
        .select_related('concept_tag')
    )
    from collections import Counter
    tag_counter = Counter()
    for qt in tag_records:
        tag_counter[qt.concept_tag.name] += 1

    weak_tags = [
        {'name': name, 'count': count}
        for name, count in tag_counter.most_common()
    ]

    return _ok(data={
        **base,
        'overview': overview,
        'accuracyTrend': accuracy_trend,
        'weakTags': weak_tags,
    })


# ── 作业 ──────────────────────────────────────────────────────


@extend_schema(
    request=CreateAssignmentSerializer,
    responses={200: OpenApiResponse(description='作业列表/发布')},
)
@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated, IsTeacher])
def assignment_list_create(request):
    """作业列表（GET）/ 发布作业（POST）"""
    if request.method == 'GET':
        return _list_assignments()

    # POST
    serializer = CreateAssignmentSerializer(data=request.data)
    if not serializer.is_valid():
        first_err = list(serializer.errors.values())[0]
        msg = str(first_err[0]) if isinstance(first_err, list) else str(first_err)
        return _err(40201, msg)

    data = serializer.validated_data
    return _create_assignment(data)


def _list_assignments():
    """组装作业列表 + 统计汇总"""
    ccas = ClassCourseAssignment.objects.filter(is_active=True).select_related(
        'assignment', 'class_course__class_group', 'class_course__course',
    ).order_by('-publish_at')

    items = []
    for cca in ccas:
        cg_id = cca.class_course.class_group_id
        a_id = cca.assignment_id
        total_students = _count_class_students(cg_id)
        completed = _class_completed_count(cg_id, a_id)
        acc = _class_accuracy(cg_id, a_id)

        items.append({
            'id': cca.id,
            'title': cca.assignment.title,
            'className': cca.class_course.class_group.name,
            'deadline': cca.deadline.strftime('%Y-%m-%d') if cca.deadline else '',
            'totalStudents': total_students,
            'completedCount': completed,
            'completionRate': (
                f'{round(completed / total_students * 100)}%'
                if total_students else '0%'),
            'avgAccuracy': acc,
        })

    # 汇总统计
    total = len(items)
    today = timezone.now().date()
    active = sum(
        1 for cca in ClassCourseAssignment.objects.filter(is_active=True)
        if cca.deadline and cca.deadline.date() >= today
    )

    # 聚合完成率
    completed_sum = sum(item['completedCount'] for item in items)
    total_sum = sum(item['totalStudents'] for item in items)
    avg_completion = (
        f'{round(completed_sum / total_sum * 100)}%'
        if total_sum else '0%')

    return _ok(data={
        'totalAssignments': total,
        'activeAssignments': active,
        'avgCompletionRate': avg_completion,
        'avgAccuracy': _calc_overall_accuracy(),
        'items': items,
    })


def _create_assignment(data):
    """从组卷创建作业并发布到班级"""
    paper = get_object_or_404(CustomPaper, pk=data['paper_id'])

    # 创建作业
    title = data.get('title', '').strip() or paper.title
    description = data.get('description', '')
    assignment = Assignment.objects.create(
        title=title,
        description=description,
    )

    # 复制题目
    for pq in paper.paper_questions.select_related('question').order_by('sort_order'):
        AssignmentQuestion.objects.create(
            assignment=assignment,
            question=pq.question,
            sort_order=pq.sort_order,
        )

    # 发布到班级
    for cid in data['class_ids']:
        cc = ClassCourse.objects.filter(class_group_id=cid).first()
        if cc:
            ClassCourseAssignment.objects.create(
                class_course=cc,
                assignment=assignment,
                deadline=data['deadline'],
                is_active=True,
            )

    return _ok(data={'id': assignment.id})


@extend_schema(
    request=PatchAssignmentSerializer,
    responses={200: OpenApiResponse(description='作业详情/删除/修改')},
)
@api_view(['GET', 'DELETE', 'PATCH'])
@permission_classes([IsAuthenticated, IsTeacher])
def assignment_rud(request, id):
    """作业详情（GET）/ 撤销（DELETE）/ 修改（PATCH）"""
    cca = get_object_or_404(
        ClassCourseAssignment.objects.select_related(
            'assignment', 'class_course__class_group',
        ),
        pk=id,
    )

    if request.method == 'GET':
        return _assignment_detail(cca)

    if request.method == 'DELETE':
        cca.is_active = False
        cca.save(update_fields=['is_active'])
        return Response(status=status.HTTP_204_NO_CONTENT)

    # PATCH
    serializer = PatchAssignmentSerializer(data=request.data, partial=True)
    if not serializer.is_valid():
        first_err = list(serializer.errors.values())[0]
        msg = str(first_err[0]) if isinstance(first_err, list) else str(first_err)
        return _err(40201, msg)

    data = serializer.validated_data
    cca_fields = []
    if 'deadline' in data:
        cca.deadline = data['deadline']
        cca_fields.append('deadline')
    if cca_fields:
        cca.save(update_fields=cca_fields)
    if 'description' in data:
        assignment = cca.assignment
        assignment.description = data['description']
        assignment.save(update_fields=['description'])
    return _ok(message='修改成功')


def _assignment_detail(cca):
    """按学生维度列出作业详情"""
    cg_id = cca.class_course.class_group_id
    a_id = cca.assignment_id

    students = Student.objects.filter(
        class_group_id=cg_id,
    ).select_related('user')

    student_items = []
    for s in students:
        details = SubmissionDetail.objects.filter(
            submission__assignment_id=a_id,
            submission__student=s,
        ).order_by('created_at')

        first = details.first()
        if first:
            # 计算耗时：首条到最后一条的时间差
            last = details.last()
            secs = int((last.created_at - first.created_at).total_seconds())
            if secs < 60:
                duration = '少于1分钟'
            elif secs < 3600:
                duration = f'{secs // 60}分钟'
            else:
                duration = f'{secs // 3600}小时{(secs % 3600) // 60}分钟'

            total = details.count()
            correct = details.filter(is_correct=True).count()
            acc = f'{round(correct / total * 100)}%' if total else '0%'
            student_items.append({
                'id': s.id,
                'name': s.user.first_name or s.user.username,
                'status': 'completed',
                'accuracy': acc,
                'duration': duration,
                'completedAt': last.created_at.strftime('%Y-%m-%d %H:%M'),
            })
        else:
            student_items.append({
                'id': s.id,
                'name': s.user.first_name or s.user.username,
                'status': 'pending',
                'accuracy': None,
                'duration': None,
                'completedAt': None,
            })

    total_students = _count_class_students(cg_id)
    completed = _class_completed_count(cg_id, a_id)
    acc = _class_accuracy(cg_id, a_id)

    return _ok(data={
        'id': cca.id,
        'title': cca.assignment.title,
        'deadline': cca.deadline.strftime('%Y-%m-%d') if cca.deadline else '',
        'className': cca.class_course.class_group.name,
        'totalStudents': total_students,
        'completedCount': completed,
        'avgAccuracy': acc,
        'students': student_items,
    })
