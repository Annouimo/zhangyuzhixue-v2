"""教师端 API 视图 — 作业/组卷/班级/学生 共 9 端点"""
from datetime import timedelta

from django.db.models import Count, Q
from django.db.models.functions import TruncDate
from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.utils import OpenApiResponse, extend_schema
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from collections import OrderedDict

from accounts.models import Student, UserLoginLog
from accounts.permissions import IsTeacher
from courses.models import (
    Assignment,
    AssignmentQuestion,
    ClassCourse,
    ClassCourseAssignment,
    ClassGroup,
    Course,
)
from courses.teacher_serializers import (
    CreateAssignmentSerializer,
    PatchAssignmentSerializer,
)
from interactions.models import (
    StepFeedback,
    StudentSubmission,
    SubmissionDetail,
)
from qbank.models import BaseQuestion, QuestionConceptTag

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
    """该班级指定作业的平均正确率（返回 0-100 数值）"""
    details = SubmissionDetail.objects.filter(
        submission__assignment_id=assignment_id,
        submission__student__class_group_id=class_group_id,
        is_correct__isnull=False,
    )
    total = details.count()
    if total == 0:
        return 0.0
    correct = details.filter(is_correct=True).count()
    return round(correct / total * 100, 1)


def _calc_class_accuracy(class_group_id):
    """该班级所有学生跨所有作业的平均正确率（返回 0-100 数值）"""
    details = SubmissionDetail.objects.filter(
        submission__student__class_group_id=class_group_id,
        is_correct__isnull=False,
    )
    total = details.count()
    if total == 0:
        return 0.0
    correct = details.filter(is_correct=True).count()
    return round(correct / total * 100, 1)


def _calc_overall_accuracy():
    """全校平均正确率（所有班级/所有作业，返回 0-100 数值）"""
    details = SubmissionDetail.objects.filter(is_correct__isnull=False)
    total = details.count()
    if total == 0:
        return 0.0
    correct = details.filter(is_correct=True).count()
    return round(correct / total * 100, 1)


def _count_student_submissions(student_id):
    """学生总提交题数"""
    return SubmissionDetail.objects.filter(
        submission__student_id=student_id,
    ).count()


def _count_student_correct(student_id):
    """学生正确题数"""
    return SubmissionDetail.objects.filter(
        submission__student_id=student_id,
        is_correct=True,
    ).count()


def _calc_student_accuracy(student_id):
    """学生个人正确率（返回 0-100 数值）"""
    details = SubmissionDetail.objects.filter(
        submission__student_id=student_id,
        is_correct__isnull=False,
    )
    total = details.count()
    if total == 0:
        return 0.0
    correct = details.filter(is_correct=True).count()
    return round(correct / total * 100, 1)


def _last_active_date(student_id):
    """最近提交日期"""
    last = SubmissionDetail.objects.filter(
        submission__student_id=student_id,
    ).order_by('-created_at').first()
    if last is None:
        return None
    return last.created_at.strftime('%Y-%m-%d')


def _calc_streak_days(student):
    """计算连续签到天数（从最近登录日向前数连续天数）"""
    logs = list(UserLoginLog.objects.filter(
        student=student,
    ).order_by('-login_date').values_list('login_date', flat=True))
    if not logs:
        return 0

    from datetime import date, timedelta
    today = date.today()
    streak = 0
    expected = today

    for log_date in logs:
        if log_date == expected:
            streak += 1
            expected -= timedelta(days=1)
        elif log_date < expected:
            # 中断了（缺了某一天），不再继续
            break

    return streak


# ── 班级 ──────────────────────────────────────────────────────


@extend_schema(
    responses={200: OpenApiResponse(description='班级概览')},
)
@api_view(['GET'])
@permission_classes([IsAuthenticated, IsTeacher])
def class_list(request):
    """班级概览 — 统计卡片 + 列表"""
    groups = ClassGroup.objects.annotate(s_count=Count('students'))

    # 批量预计算班级正确率
    class_ids = [g.id for g in groups]
    # 正确率/班级
    accuracy_raw = (
        SubmissionDetail.objects.filter(
            submission__student__class_group_id__in=class_ids,
            is_correct__isnull=False,
        )
        .values('submission__student__class_group_id')
        .annotate(
            total=Count('id'),
            correct=Count('id', filter=Q(is_correct=True)),
        )
    )
    accuracy_map = {}
    for r in accuracy_raw:
        cid = r['submission__student__class_group_id']
        t = r['total']
        accuracy_map[cid] = round(r['correct'] / t * 100, 1) if t else 0.0

    # 课程数/班级
    course_count_raw = (
        ClassCourse.objects.filter(class_group_id__in=class_ids)
        .values('class_group_id')
        .annotate(cnt=Count('course', distinct=True))
    )
    course_count_map = {r['class_group_id']: r['cnt'] for r in course_count_raw}

    # 总题量/班级
    questions_raw = (
        SubmissionDetail.objects.filter(
            submission__student__class_group_id__in=class_ids,
        )
        .values('submission__student__class_group_id')
        .annotate(cnt=Count('id'))
    )
    questions_map = {r['submission__student__class_group_id']: r['cnt'] for r in questions_raw}

    items = []
    total_students = 0
    for g in groups:
        total_students += g.s_count
        cid = g.id
        items.append({
            'id': cid,
            'name': g.name,
            'studentCount': g.s_count,
            'courseCount': course_count_map.get(cid, 0),
            'totalQuestionsDone': questions_map.get(cid, 0),
            'avgAccuracy': accuracy_map.get(cid, 0.0),
        })
    return _ok(data={
        'totalClasses': groups.count(),
        'totalStudents': total_students,
        'totalQuestions': SubmissionDetail.objects.count(),
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
        'correctCount': _count_student_correct(s.id),
        'avgAccuracy': _calc_student_accuracy(s.id),
        'streakDays': _calc_streak_days(s),
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
    streak_days = _calc_streak_days(s)
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
    trend_raw = (
        SubmissionDetail.objects
        .filter(submission__student=s, created_at__gte=thirty_days_ago)
        .annotate(date=TruncDate('created_at'))
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

    # 薄弱知识点（含正确率）
    all_feedback_qids = set(
        StepFeedback.objects
        .filter(submission_detail__submission__student=s)
        .values_list('question_id', flat=True)
        .distinct()
    )
    wrong_qids = set(
        StepFeedback.objects
        .filter(
            submission_detail__submission__student=s,
        )
        .exclude(status='full_correct')
        .values_list('question_id', flat=True)
        .distinct()
    )
    all_tag_qs = QuestionConceptTag.objects.filter(
        question_id__in=list(all_feedback_qids),
    ).select_related('concept_tag')

    from collections import defaultdict
    tag_stats = defaultdict(lambda: {'total': 0, 'wrong': 0})
    for qt in all_tag_qs:
        tag_stats[qt.concept_tag.name]['total'] += 1
        if qt.question_id in wrong_qids:
            tag_stats[qt.concept_tag.name]['wrong'] += 1

    weak_tags = []
    for name, stats in tag_stats.items():
        correct = stats['total'] - stats['wrong']
        accuracy = round(correct / stats['total'] * 100, 1) if stats['total'] else 0
        weak_tags.append({
            'name': name,
            'accuracy': f'{accuracy}%',
            'count': stats['wrong'],
        })
    weak_tags.sort(key=lambda x: float(x['accuracy'].rstrip('%')))

    # 题型分布
    type_breakdown_raw = SubmissionDetail.objects.filter(
        submission__student=s,
    ).values('question__question_type').annotate(
        total=Count('id'),
        correct=Count('id', filter=Q(is_correct=True)),
    )
    from qbank.models import BaseQuestion
    type_map = dict(BaseQuestion.QUESTION_TYPE_CHOICES)
    question_type_breakdown = []
    for row in type_breakdown_raw:
        t = row['total']
        qt = row['question__question_type']
        question_type_breakdown.append({
            'type': type_map.get(qt, qt),
            'count': t,
            'correctCount': row['correct'],
            'accuracy': round(row['correct'] / t * 100, 1) if t else 0,
        })

    return _ok(data={
        **base,
        'overview': overview,
        'accuracyTrend': accuracy_trend,
        'weakTags': weak_tags,
        'questionTypeBreakdown': question_type_breakdown,
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
    """组装作业列表 + 统计汇总 — 按 assignment 分组（多班级合并）"""
    ccas = list(ClassCourseAssignment.objects.filter(is_active=True).select_related(
        'assignment', 'class_course__class_group', 'class_course__course',
    ).order_by('-publish_at'))

    # 按 assignment_id 分组
    grouped = OrderedDict()
    for cca in ccas:
        aid = cca.assignment_id
        if aid not in grouped:
            grouped[aid] = {
                'assignment': cca.assignment,
                'ccas': [],
            }
        grouped[aid]['ccas'].append(cca)

    items = []
    # ── 批量预计算统计，消除内循环 N+1 ──
    class_group_ids = {cca.class_course.class_group_id for cca in ccas}
    assignment_ids = {cca.assignment_id for cca in ccas}

    # 学生数/班级
    student_count_map = dict(
        Student.objects.filter(class_group_id__in=class_group_ids)
        .values('class_group_id')
        .annotate(cnt=Count('id'))
        .values_list('class_group_id', 'cnt')
    )

    # 完成数/班级+作业
    completed_raw = (
        StudentSubmission.objects.filter(
            assignment_id__in=assignment_ids,
            student__class_group_id__in=class_group_ids,
            details__is_correct__isnull=False,
        )
        .values('student__class_group_id', 'assignment_id')
        .annotate(cnt=Count('id', distinct=True))
    )
    completed_map = {}
    for r in completed_raw:
        completed_map[(r['student__class_group_id'], r['assignment_id'])] = r['cnt']

    # 正确率/班级+作业
    accuracy_raw = (
        SubmissionDetail.objects.filter(
            submission__assignment_id__in=assignment_ids,
            submission__student__class_group_id__in=class_group_ids,
            is_correct__isnull=False,
        )
        .values('submission__student__class_group_id', 'submission__assignment_id')
        .annotate(
            total=Count('id'),
            correct=Count('id', filter=Q(is_correct=True)),
        )
    )
    accuracy_map = {}
    for r in accuracy_raw:
        key = (r['submission__student__class_group_id'], r['submission__assignment_id'])
        t = r['total']
        accuracy_map[key] = round(r['correct'] / t * 100, 1) if t else 0.0

    # 题数/作业
    q_count_map = dict(
        AssignmentQuestion.objects.filter(assignment_id__in=assignment_ids)
        .values('assignment_id')
        .annotate(cnt=Count('id'))
        .values_list('assignment_id', 'cnt')
    )

    today = timezone.now().date()

    for aid, g in grouped.items():
        a = g['assignment']
        class_names = []
        total_students = 0
        completed_count = 0
        all_deadlines = []
        accuracy_weighted_sum = 0.0

        for cca in g['ccas']:
            cg_id = cca.class_course.class_group_id
            class_names.append(cca.class_course.class_group.name)
            ts = student_count_map.get(cg_id, 0)
            total_students += ts
            completed = completed_map.get((cg_id, aid), 0)
            completed_count += completed
            acc = accuracy_map.get((cg_id, aid), 0.0)
            accuracy_weighted_sum += acc * ts
            if cca.deadline:
                all_deadlines.append(cca.deadline)

        latest_deadline = max(all_deadlines).strftime('%Y-%m-%d') if all_deadlines else ''
        deadline_date = max(all_deadlines) if all_deadlines else None
        publish_ats = [cca.publish_at for cca in g['ccas'] if cca.publish_at]
        publish_at_str = max(publish_ats).strftime('%Y-%m-%d') if publish_ats else ''

        items.append({
            'id': aid,
            'title': a.title,
            'className': '、'.join(class_names),
            'courseName': g['ccas'][0].class_course.course.name,
            'deadline': latest_deadline,
            'questionCount': q_count_map.get(aid, 0),
            'publishAt': publish_at_str,
            'totalStudents': total_students,
            'completedCount': completed_count,
            'completionRate': (
                round(completed_count / total_students * 100, 1)
                if total_students else 0.0),
            'avgAccuracy': (
                round(accuracy_weighted_sum / total_students, 1)
                if total_students else 0.0),
            'statusTag': 'in_progress' if deadline_date and deadline_date >= today else 'done',
        })

    # 汇总统计
    total = len(items)
    today = timezone.now().date()
    active = sum(
        1 for g in grouped.values()
        for cca in g['ccas']
        if cca.deadline and cca.deadline >= today
    )

    completed_sum = sum(item['completedCount'] for item in items)
    total_sum = sum(item['totalStudents'] for item in items)
    avg_completion = (
        round(completed_sum / total_sum * 100, 1)
        if total_sum else 0.0)

    return _ok(data={
        'totalAssignments': total,
        'activeAssignments': active,
        'avgCompletionRate': avg_completion,
        'avgAccuracy': _calc_overall_accuracy(),
        'items': items,
    })


def _create_assignment(data):
    """从教师端 JSON 选题创建作业并发布到班级"""
    qids = data['question_ids']
    title = data.get('title', '').strip() or f'作业（{len(qids)}题）'
    course_id = data.get('course_id')
    if course_id is not None:
        get_object_or_404(Course, pk=course_id)
    assignment = Assignment.objects.create(
        title=title,
        description=data.get('description', ''),
        course_id=course_id,
    )
    questions = BaseQuestion.objects.filter(pk__in=qids)
    q_map = {q.id: i for i, q in enumerate(questions)}
    for sort_order, qid in enumerate(qids):
        if qid in q_map:
            AssignmentQuestion.objects.create(
                assignment=assignment,
                question_id=qid,
                sort_order=sort_order,
            )

    # 发布到班级
    class_ids = data.get('class_ids') or []
    if not class_ids and course_id:
        class_ids = list(ClassCourse.objects.filter(
            course_id=course_id
        ).values_list('class_group_id', flat=True).distinct())
    for cid in class_ids:
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
    assignment = cca.assignment
    assign_fields = []
    if 'title' in data:
        assignment.title = data['title']
        assign_fields.append('title')
    if 'description' in data:
        assignment.description = data['description']
        assign_fields.append('description')
    if assign_fields:
        assignment.save(update_fields=assign_fields)
    return _ok(message='修改成功')


@extend_schema(
    responses={200: OpenApiResponse(description='催交记录')},
)
@api_view(['POST'])
@permission_classes([IsAuthenticated, IsTeacher])
def assignment_remind(request, id):
    """作业催交 — 暂无通知推送通道，仅记录催交日志"""
    get_object_or_404(ClassCourseAssignment, pk=id)
    # 记录催交操作（预留日志通道）
    # TODO: 通知推送通道接入后，在此触发推送
    return _ok(message='催交已记录')


def _assignment_detail(cca):
    """按学生维度列出作业详情"""
    cg_id = cca.class_course.class_group_id
    a_id = cca.assignment_id

    students = list(Student.objects.filter(
        class_group_id=cg_id,
    ).select_related('user'))

    # 批量加载该班级该作业的所有提交详情
    all_details = (
        SubmissionDetail.objects.filter(
            submission__assignment_id=a_id,
            submission__student__class_group_id=cg_id,
        )
        .select_related('submission__student')
        .order_by('submission__student_id', 'created_at')
    )

    # 按学生分组
    from collections import defaultdict
    student_details = defaultdict(list)
    for d in all_details:
        student_details[d.submission.student_id].append(d)

    student_items = []
    for s in students:
        details = student_details.get(s.id, [])
        if details:
            first = details[0]
            last = details[-1]
            secs = int((last.created_at - first.created_at).total_seconds())
            if secs < 60:
                duration = '少于1分钟'
            elif secs < 3600:
                duration = f'{secs // 60}分钟'
            else:
                duration = f'{secs // 3600}小时{(secs % 3600) // 60}分钟'

            total = len(details)
            correct = sum(1 for d in details if d.is_correct)
            acc = round(correct / total * 100, 1) if total else 0.0
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


def _assignment_detail_by_assignment(ccas):
    """按作业级别返回多班级分组的学生详情"""
    if not ccas:
        return _err(40201, '作业不存在')

    a = ccas[0].assignment
    class_group_ids = [cca.class_course.class_group_id for cca in ccas]

    # 批量加载全部学生的提交详情
    all_details = (
        SubmissionDetail.objects.filter(
            submission__assignment_id=a.id,
            submission__student__class_group_id__in=class_group_ids,
        )
        .select_related('submission__student')
        .order_by('submission__student_id', 'created_at')
    )

    from collections import defaultdict
    student_details_map = defaultdict(list)
    for d in all_details:
        student_details_map[d.submission.student_id].append(d)

    classes = []
    total_students = 0
    completed_count = 0
    accuracy_weighted_sum = 0.0
    all_deadlines = []

    for cca in ccas:
        cg_id = cca.class_course.class_group_id
        cg_name = cca.class_course.class_group.name

        students = list(Student.objects.filter(
            class_group_id=cg_id,
        ).select_related('user'))

        student_items = []
        for s in students:
            details = student_details_map.get(s.id, [])
            if details:
                first = details[0]
                last = details[-1]
                secs = int((last.created_at - first.created_at).total_seconds())
                if secs < 60:
                    duration = '少于1分钟'
                elif secs < 3600:
                    duration = f'{secs // 60}分钟'
                else:
                    duration = f'{secs // 3600}小时{(secs % 3600) // 60}分钟'

                total = len(details)
                correct = sum(1 for d in details if d.is_correct)
                acc = round(correct / total * 100, 1) if total else 0.0
                student_items.append({
                    'id': s.id,
                    'name': s.user.first_name or s.user.username,
                    'status': 'completed',
                    'accuracy': acc,
                    'duration': duration,
                    'completedAt': last.created_at.strftime('%Y-%m-%d %H:%M'),
                    'correctCount': correct,
                    'totalCount': total,
                })
            else:
                student_items.append({
                    'id': s.id,
                    'name': s.user.first_name or s.user.username,
                    'status': 'pending',
                    'accuracy': None,
                    'duration': None,
                    'completedAt': None,
                    'correctCount': 0,
                    'totalCount': 0,
                })

        ts = _count_class_students(cg_id)
        completed = _class_completed_count(cg_id, a.id)
        acc_val = _class_accuracy(cg_id, a.id)
        total_students += ts
        completed_count += completed
        accuracy_weighted_sum += acc_val * ts
        if cca.deadline:
            all_deadlines.append(cca.deadline)

        classes.append({
            'class_name': cg_name,
            'total': ts,
            'submitted': completed,
            'average_accuracy': acc_val,
            'students': student_items,
        })

    latest_deadline = max(all_deadlines).strftime('%Y-%m-%d') if all_deadlines else ''

    # 题目数量
    question_count = AssignmentQuestion.objects.filter(assignment=a).count()

    return _ok(data={
        'id': a.id,
        'title': a.title,
        'description': a.description,
        'deadline': latest_deadline,
        'questionCount': question_count,
        'totalStudents': total_students,
        'completedCount': completed_count,
        'avgAccuracy': (
            round(accuracy_weighted_sum / total_students, 1)
            if total_students else 0.0),
        'classes': classes,
    })


# ── 分组作业详情 ─────────────────────────────────────────────


@extend_schema(
    responses={200: OpenApiResponse(description='分组作业详情')},
)
@api_view(['GET'])
@permission_classes([IsAuthenticated, IsTeacher])
def assignment_detail_grouped(request, assignment_id):
    """按作业 ID 返回多班级分组的学生详情"""
    ccas = list(ClassCourseAssignment.objects.filter(
        assignment_id=assignment_id, is_active=True,
    ).select_related(
        'assignment', 'class_course__class_group', 'class_course__course',
    ))
    return _assignment_detail_by_assignment(ccas)


# ── 关于页 ──────────────────────────────────────────────────


@extend_schema(
    responses={200: OpenApiResponse(description='关于页数据')},
)
@api_view(['GET'])
@permission_classes([IsAuthenticated, IsTeacher])
def about_info(request):
    """关于页 — 版本/公告/更新日志"""
    import json
    from system.config_reader import get_config
    from system.models import Announcement

    app_version = get_config('teacher_app_version', '2.0.0')

    announcements = Announcement.objects.filter(is_active=True).order_by('-created_at')
    ann_list = [{
        'title': a.title,
        'content': a.content,
        'date': a.created_at.strftime('%Y-%m-%d'),
    } for a in announcements]

    changelog_raw = get_config('teacher_changelog', '[]')
    try:
        changelog = json.loads(changelog_raw)
    except (json.JSONDecodeError, TypeError):
        changelog = []

    return _ok(data={
        'appVersion': app_version,
        'build': '20260710',
        'dataVersion': 3,
        'announcements': ann_list,
        'changelog': changelog,
    })
