"""教师 API 测试 — 组卷/班级/学生/作业 共 ~20 场景"""
import pytest
from datetime import date, timedelta
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from accounts.models import Student, Teacher
from courses.models import (
    Assignment,
    AssignmentQuestion,
    ClassCourse,
    ClassCourseAssignment,
    ClassGroup,
    Course,
)
from interactions.models import (
    StudentSubmission,
    SubmissionDetail,
)
from qbank.models import BaseQuestion


# ── Fixtures ──────────────────────────────────────────────────


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def teacher_user(db):
    user = User.objects.create_user('teacher1', password='test123')
    Teacher.objects.create(user=user)
    return user


@pytest.fixture
def auth_client(api_client, teacher_user):
    refresh = RefreshToken.for_user(teacher_user)
    api_client.credentials(HTTP_AUTHORIZATION='Bearer ' + str(refresh.access_token))
    return api_client


@pytest.fixture
def sample_class_group(db):
    return ClassGroup.objects.create(name='高三(1)班')


@pytest.fixture
def sample_students(sample_class_group, db):
    students = []
    for i in range(3):
        u = User.objects.create_user(f'student{i}', password='test123')
        s = Student.objects.create(user=u, class_group=sample_class_group)
        students.append(s)
    return students


@pytest.fixture
def sample_question(db):
    q = BaseQuestion.objects.create(
        stem='测试题干',
        question_type='choice',
        difficulty=5.0,
        calculation=5.0,
        year=2026,
    )
    return q


# ── 班级 ──


class TestClassList:
    def test_empty(self, auth_client):
        resp = auth_client.get('/api/v1/teacher/classes/')
        assert resp.status_code == 200
        d = resp.data['data']
        assert d['totalClasses'] == 0
        assert d['items'] == []

    def test_with_class(self, auth_client, sample_class_group):
        resp = auth_client.get('/api/v1/teacher/classes/')
        assert resp.status_code == 200
        d = resp.data['data']
        assert d['totalClasses'] == 1
        assert d['totalQuestions'] == 0
        assert d['avgAccuracy'] == 0.0
        assert d['items'][0]['id'] == sample_class_group.id
        assert d['items'][0]['name'] == '高三(1)班'
        assert d['items'][0]['studentCount'] == 0
        assert d['items'][0]['avgAccuracy'] == 0.0


# ── Students ──────────────────────────────────────────────────


class TestStudentList:
    def test_all(self, auth_client, sample_students):
        resp = auth_client.get('/api/v1/teacher/students/')
        assert resp.status_code == 200
        data = resp.data['data']
        assert len(data) == 3

    def test_returns_new_fields(self, auth_client, sample_students):
        """验证 correctCount 和 streakDays 字段"""
        resp = auth_client.get('/api/v1/teacher/students/')
        assert resp.status_code == 200
        s = resp.data['data'][0]
        assert 'correctCount' in s
        assert 'streakDays' in s
        assert s['correctCount'] == 0
        assert s['streakDays'] == 0

    def test_search_by_name(self, auth_client, sample_students):
        # student0's user.first_name is '' (default), search by username
        resp = auth_client.get('/api/v1/teacher/students/?search=student0')
        assert resp.status_code == 200
        assert len(resp.data['data']) == 1
        assert resp.data['data'][0]['name'] == 'student0'

    def test_filter_by_class(self, auth_client, sample_class_group, sample_students):
        resp = auth_client.get(f'/api/v1/teacher/students/?class_id={sample_class_group.id}')
        assert resp.status_code == 200
        assert len(resp.data['data']) == 3


class TestStudentDetail:
    def test_normal(self, auth_client, sample_students):
        s = sample_students[0]
        resp = auth_client.get(f'/api/v1/teacher/students/{s.id}/')
        assert resp.status_code == 200
        d = resp.data['data']
        assert d['id'] == s.id
        assert d['school'] is not None
        assert d['registeredAt'] is not None
        assert d['overview']['totalQuestions'] == 0
        assert d['accuracyTrend'] == []
        assert d['weakTags'] == []

    def test_with_submissions(self, auth_client, sample_students, sample_question):
        s = sample_students[0]
        sub = StudentSubmission.objects.create(student=s)
        SubmissionDetail.objects.create(
            submission=sub, question=sample_question,
            is_correct=True, status='completed',
        )
        SubmissionDetail.objects.create(
            submission=sub, question=sample_question,
            is_correct=False, status='completed',
        )
        resp = auth_client.get(f'/api/v1/teacher/students/{s.id}/')
        assert resp.status_code == 200
        d = resp.data['data']
        assert d['overview']['totalQuestions'] == 2
        assert d['overview']['avgAccuracy'] == 50.0
        assert d['overview']['streakDays'] == 0
        assert 'questionTypeBreakdown' in d
        assert isinstance(d['questionTypeBreakdown'], list)

    def test_student_detail_streak_days(self, auth_client, sample_students):
        """验证连续签到天数计算"""
        from accounts.models import UserLoginLog
        s = sample_students[0]
        from datetime import date, timedelta
        today = date.today()
        # 创建连续3天签到 + 1天前
        UserLoginLog.objects.create(student=s, login_date=today)
        UserLoginLog.objects.create(student=s, login_date=today - timedelta(days=1))
        UserLoginLog.objects.create(student=s, login_date=today - timedelta(days=2))
        # 中断一天
        UserLoginLog.objects.create(student=s, login_date=today - timedelta(days=5))

        resp = auth_client.get(f'/api/v1/teacher/students/{s.id}/')
        assert resp.status_code == 200
        d = resp.data['data']
        # 连续从今天往前3天
        assert d['overview']['streakDays'] == 3, f"Expected 3, got {d['overview']['streakDays']}"

    def test_student_detail_question_type_breakdown(
            self, auth_client, sample_students, sample_question):
        """验证题型分布数据"""
        from qbank.models import BaseQuestion
        # 创建不同类型题目
        q2 = BaseQuestion.objects.create(
            stem='填标题', question_type='fill',
            difficulty=3.0, calculation=3.0, year=2026,
        )
        s = sample_students[0]
        sub = StudentSubmission.objects.create(student=s)
        SubmissionDetail.objects.create(
            submission=sub, question=sample_question, is_correct=True, status='completed',
        )
        SubmissionDetail.objects.create(
            submission=sub, question=q2, is_correct=False, status='completed',
        )
        resp = auth_client.get(f'/api/v1/teacher/students/{s.id}/')
        assert resp.status_code == 200
        d = resp.data['data']
        breakdown = d['questionTypeBreakdown']
        # 应该有2个题型
        assert len(breakdown) >= 2
        types = {item['type'] for item in breakdown}
        assert '选择题' in types
        assert '填空题' in types
        for item in breakdown:
            assert 'count' in item
            assert 'accuracy' in item
            assert isinstance(item['accuracy'], float)

    def test_not_found(self, auth_client):
        resp = auth_client.get('/api/v1/teacher/students/99999/')
        assert resp.status_code == 404


# ── Assignments ───────────────────────────────────────────────


class TestAssignmentList:
    def test_empty(self, auth_client):
        resp = auth_client.get('/api/v1/teacher/assignments/')
        assert resp.status_code == 200
        d = resp.data['data']
        assert d['totalAssignments'] == 0
        assert d['items'] == []

    def test_with_data(self, auth_client, sample_class_group, sample_question):
        # create an assignment
        course = Course.objects.create(name='数学')
        cc = ClassCourse.objects.create(class_group=sample_class_group, course=course)
        assignment = Assignment.objects.create(title='测试作业')
        AssignmentQuestion.objects.create(
            assignment=assignment, question=sample_question, sort_order=0,
        )
        ClassCourseAssignment.objects.create(
            class_course=cc, assignment=assignment,
            deadline=date.today() + timedelta(days=7), is_active=True,
        )
        resp = auth_client.get('/api/v1/teacher/assignments/')
        assert resp.status_code == 200
        d = resp.data['data']
        assert d['totalAssignments'] == 1
        assert d['activeAssignments'] >= 1
        assert d['avgCompletionRate'] is not None
        assert d['avgAccuracy'] is not None
        assert d['items'][0]['title'] == '测试作业'
        assert d['items'][0]['totalStudents'] == 0

    def test_inactive_excluded(self, auth_client, sample_class_group, sample_question):
        course = Course.objects.create(name='数学')
        cc = ClassCourse.objects.create(class_group=sample_class_group, course=course)
        assignment = Assignment.objects.create(title='已撤销作业')
        AssignmentQuestion.objects.create(
            assignment=assignment, question=sample_question, sort_order=0,
        )
        ClassCourseAssignment.objects.create(
            class_course=cc, assignment=assignment,
            deadline=date.today(), is_active=False,
        )
        resp = auth_client.get('/api/v1/teacher/assignments/')
        assert resp.status_code == 200
        assert resp.data['data']['totalAssignments'] == 0


class TestAssignmentCreate:
    def test_normal(self, auth_client, sample_class_group, sample_question):
        # Create a ClassCourse for the class group
        course = Course.objects.create(name='数学')
        ClassCourse.objects.create(class_group=sample_class_group, course=course)
        resp = auth_client.post('/api/v1/teacher/assignments/', {
            'question_ids': [sample_question.id],
            'title': '新作业',
            'deadline': '2026-07-20',
            'description': '请认真完成',
            'class_ids': [sample_class_group.id],
        }, format='json')
        assert resp.status_code == 200
        assert resp.data['data']['id'] is not None
        assert Assignment.objects.count() == 1
        a = Assignment.objects.first()
        assert a.title == '新作业'
        assert a.description == '请认真完成'
        assert AssignmentQuestion.objects.count() == 1
        assert ClassCourseAssignment.objects.count() == 1

    def test_missing_params(self, auth_client):
        resp = auth_client.post('/api/v1/teacher/assignments/', {
            'deadline': '2026-07-20',
        }, format='json')
        assert resp.status_code == 400
        assert resp.data['code'] != 0

    def test_empty_qids(self, auth_client):
        resp = auth_client.post('/api/v1/teacher/assignments/', {
            'question_ids': [],
            'deadline': '2026-07-20',
            'class_ids': [1],
        }, format='json')
        assert resp.status_code == 400


class TestAssignmentDetail:
    def test_normal(self, auth_client, sample_class_group, sample_students,
                    sample_question):
        # create assignment
        course = Course.objects.create(name='数学')
        cc = ClassCourse.objects.create(class_group=sample_class_group, course=course)
        assignment = Assignment.objects.create(title='测试作业')
        AssignmentQuestion.objects.create(
            assignment=assignment, question=sample_question, sort_order=0,
        )
        cca = ClassCourseAssignment.objects.create(
            class_course=cc, assignment=assignment,
            deadline=date.today(), is_active=True,
        )
        # create a submission with multiple details for duration calc
        s0 = sample_students[0]
        sub = StudentSubmission.objects.create(student=s0, assignment=assignment)
        SubmissionDetail.objects.create(
            submission=sub, question=sample_question,
            is_correct=True, status='completed',
        )
        SubmissionDetail.objects.create(
            submission=sub, question=sample_question,
            is_correct=False, status='completed',
        )
        resp = auth_client.get(f'/api/v1/teacher/assignments/{cca.id}/')
        assert resp.status_code == 200
        d = resp.data['data']
        assert d['title'] == '测试作业'
        assert d['totalStudents'] == 3
        assert len(d['students']) == 3
        # verify completed student has duration
        completed = [s for s in d['students'] if s['status'] == 'completed']
        assert len(completed) == 1
        assert completed[0]['duration'] is not None
        assert '分钟' in completed[0]['duration']
        # verify others are pending
        assert all(s['status'] == 'pending' for s in d['students'] if s['status'] != 'completed')

    def test_not_found(self, auth_client):
        resp = auth_client.get('/api/v1/teacher/assignments/99999/')
        assert resp.status_code == 404


class TestAssignmentGroupedDetail:
    """分组详情（按班级分组）"""

    def test_single_class(self, auth_client, sample_class_group, sample_students,
                          sample_question):
        """单班级作业返回 grouped 结构"""
        course = Course.objects.create(name='数学')
        cc = ClassCourse.objects.create(class_group=sample_class_group, course=course)
        assignment = Assignment.objects.create(title='测试分组作业')
        AssignmentQuestion.objects.create(
            assignment=assignment, question=sample_question, sort_order=0,
        )
        ClassCourseAssignment.objects.create(
            class_course=cc, assignment=assignment,
            deadline=date.today(), is_active=True,
        )
        resp = auth_client.get(
            f'/api/v1/teacher/assignments/grouped/{assignment.id}/')
        assert resp.status_code == 200
        d = resp.data['data']
        assert d['title'] == '测试分组作业'
        assert 'classes' in d
        assert len(d['classes']) == 1
        assert d['classes'][0]['class_name'] == '高三(1)班'
        assert d['classes'][0]['total'] == 3
        assert 'students' in d['classes'][0]

    def test_multi_class(self, auth_client, sample_class_group, sample_students,
                         sample_question, db):
        """多班级作业返回多个分组"""
        from courses.models import Course, ClassCourse, Assignment, AssignmentQuestion, ClassCourseAssignment

        # Create second class group
        cg2 = ClassGroup.objects.create(
            name='高三(2)班')

        course = Course.objects.create(name='数学')
        cc1 = ClassCourse.objects.create(class_group=sample_class_group, course=course)
        cc2 = ClassCourse.objects.create(class_group=cg2, course=course)

        assignment = Assignment.objects.create(title='跨班作业')
        AssignmentQuestion.objects.create(
            assignment=assignment, question=sample_question, sort_order=0,
        )
        ClassCourseAssignment.objects.create(
            class_course=cc1, assignment=assignment,
            deadline=date.today(), is_active=True,
        )
        ClassCourseAssignment.objects.create(
            class_course=cc2, assignment=assignment,
            deadline=date.today(), is_active=True,
        )
        resp = auth_client.get(
            f'/api/v1/teacher/assignments/grouped/{assignment.id}/')
        assert resp.status_code == 200
        d = resp.data['data']
        assert len(d['classes']) == 2
        class_names = [c['class_name'] for c in d['classes']]
        assert '高三(1)班' in class_names
        assert '高三(2)班' in class_names

    def test_not_found(self, auth_client):
        resp = auth_client.get('/api/v1/teacher/assignments/grouped/99999/')
        assert resp.status_code == 400
        assert resp.data['code'] != 0


class TestAssignmentDelete:
    def test_soft_delete(self, auth_client, sample_class_group, sample_question):
        course = Course.objects.create(name='数学')
        cc = ClassCourse.objects.create(class_group=sample_class_group, course=course)
        assignment = Assignment.objects.create(title='待删除')
        AssignmentQuestion.objects.create(
            assignment=assignment, question=sample_question, sort_order=0,
        )
        cca = ClassCourseAssignment.objects.create(
            class_course=cc, assignment=assignment,
            deadline=date.today(), is_active=True,
        )
        resp = auth_client.delete(f'/api/v1/teacher/assignments/{cca.id}/')
        assert resp.status_code == 204
        cca.refresh_from_db()
        assert cca.is_active is False


class TestAssignmentPatch:
    def test_update_deadline(self, auth_client, sample_class_group, sample_question):
        course = Course.objects.create(name='数学')
        cc = ClassCourse.objects.create(class_group=sample_class_group, course=course)
        assignment = Assignment.objects.create(title='可修改')
        AssignmentQuestion.objects.create(
            assignment=assignment, question=sample_question, sort_order=0,
        )
        cca = ClassCourseAssignment.objects.create(
            class_course=cc, assignment=assignment,
            deadline=date.today(), is_active=True,
        )
        new_date = '2026-08-01'
        resp = auth_client.patch(f'/api/v1/teacher/assignments/{cca.id}/', {
            'deadline': new_date,
        }, format='json')
        assert resp.status_code == 200
        cca.refresh_from_db()
        # Convert stored date to string for comparison
        stored_date = cca.deadline.strftime('%Y-%m-%d')
        assert stored_date == new_date

    def test_update_title(self, auth_client, sample_class_group, sample_question):
        """PATCH title 应路由到 Assignment 模型"""
        course = Course.objects.create(name='数学')
        cc = ClassCourse.objects.create(class_group=sample_class_group, course=course)
        assignment = Assignment.objects.create(title='原标题')
        AssignmentQuestion.objects.create(
            assignment=assignment, question=sample_question, sort_order=0,
        )
        cca = ClassCourseAssignment.objects.create(
            class_course=cc, assignment=assignment,
            deadline=date.today(), is_active=True,
        )
        resp = auth_client.patch(f'/api/v1/teacher/assignments/{cca.id}/', {
            'title': '新标题',
        }, format='json')
        assert resp.status_code == 200
        cca.assignment.refresh_from_db()
        assert cca.assignment.title == '新标题'

    def test_update_title_and_description(self, auth_client, sample_class_group, sample_question):
        """PATCH 同时更新 title + description"""
        course = Course.objects.create(name='数学')
        cc = ClassCourse.objects.create(class_group=sample_class_group, course=course)
        assignment = Assignment.objects.create(title='原标题', description='原描述')
        AssignmentQuestion.objects.create(
            assignment=assignment, question=sample_question, sort_order=0,
        )
        cca = ClassCourseAssignment.objects.create(
            class_course=cc, assignment=assignment,
            deadline=date.today(), is_active=True,
        )
        resp = auth_client.patch(f'/api/v1/teacher/assignments/{cca.id}/', {
            'title': '新标题',
            'description': '新描述',
        }, format='json')
        assert resp.status_code == 200
        cca.assignment.refresh_from_db()
        assert cca.assignment.title == '新标题'
        assert cca.assignment.description == '新描述'

    def test_update_description(self, auth_client, sample_class_group, sample_question):
        """PATCH description 应路由到 Assignment 模型"""
        course = Course.objects.create(name='数学')
        cc = ClassCourse.objects.create(class_group=sample_class_group, course=course)
        assignment = Assignment.objects.create(title='可修改描述')
        AssignmentQuestion.objects.create(
            assignment=assignment, question=sample_question, sort_order=0,
        )
        cca = ClassCourseAssignment.objects.create(
            class_course=cc, assignment=assignment,
            deadline=date.today(), is_active=True,
        )
        resp = auth_client.patch(f'/api/v1/teacher/assignments/{cca.id}/', {
            'description': '更新后的描述',
        }, format='json')
        assert resp.status_code == 200
        cca.assignment.refresh_from_db()
        assert cca.assignment.description == '更新后的描述'


# ── Auth guard ────────────────────────────────────────────────


class TestAuthGuard:
    def test_unauthenticated_returns_401(self, api_client):
        resp = api_client.get('/api/v1/teacher/classes/')
        assert resp.status_code == 401

    def test_student_cannot_access(self, api_client, db):
        user = User.objects.create_user('student_only', password='test123')
        Student.objects.create(user=user)
        refresh = RefreshToken.for_user(user)
        api_client.credentials(HTTP_AUTHORIZATION='Bearer ' + str(refresh.access_token))
        resp = api_client.get('/api/v1/teacher/classes/')
        assert resp.status_code == 403


# ── About ─────────────────────────────────────────────────────


class TestAboutInfo:
    def test_returns_structure(self, auth_client):
        resp = auth_client.get('/api/v1/teacher/about/')
        assert resp.status_code == 200
        d = resp.data['data']
        assert 'appVersion' in d
        assert 'announcements' in d
        assert 'changelog' in d
        assert d['appVersion'] == '2.0.0'
        assert d['announcements'] == []
        assert d['changelog'] == []


# ── Remind ────────────────────────────────────────────────────


class TestAssignmentRemind:
    def test_normal(self, auth_client, sample_class_group, sample_question):
        """催交正常调用应返回 200"""
        course = Course.objects.create(name='数学')
        cc = ClassCourse.objects.create(class_group=sample_class_group, course=course)
        assignment = Assignment.objects.create(title='催交测试')
        AssignmentQuestion.objects.create(
            assignment=assignment, question=sample_question, sort_order=0,
        )
        cca = ClassCourseAssignment.objects.create(
            class_course=cc, assignment=assignment,
            deadline=date.today(), is_active=True,
        )
        resp = auth_client.post(f'/api/v1/teacher/assignments/{cca.id}/remind/')
        assert resp.status_code == 200
        assert resp.data['code'] == 0

    def test_not_found(self, auth_client):
        """不存在的作业催交应返回 404"""
        resp = auth_client.post('/api/v1/teacher/assignments/99999/remind/')
        assert resp.status_code == 404


# ── PATCH boundary ───────────────────────────────────────────


class TestAssignmentPatchBoundary:
    def test_invalid_field(self, auth_client, sample_class_group, sample_question):
        """PATCH 传入不存在的字段应忽略而非报错"""
        course = Course.objects.create(name='数学')
        cc = ClassCourse.objects.create(class_group=sample_class_group, course=course)
        assignment = Assignment.objects.create(title='边界测试')
        AssignmentQuestion.objects.create(
            assignment=assignment, question=sample_question, sort_order=0,
        )
        cca = ClassCourseAssignment.objects.create(
            class_course=cc, assignment=assignment,
            deadline=date.today(), is_active=True,
        )
        resp = auth_client.patch(f'/api/v1/teacher/assignments/{cca.id}/', {
            'foo': 'bar',
        }, format='json')
        assert resp.status_code == 200
        cca.refresh_from_db()
        assert cca.assignment.title == '边界测试'


# ── Combined search ──────────────────────────────────────────


class TestStudentListCombined:
    def test_search_and_class_filter(self, auth_client, sample_class_group):
        """search + class_id 组合筛选"""
        from accounts.models import User, Student
        cg2 = ClassGroup.objects.create(name='高三(2)班')
        u1 = User.objects.create_user('student_a', password='test123')
        u1.first_name = '张三'
        u1.save()
        u2 = User.objects.create_user('student_b', password='test123')
        u2.first_name = '李四'
        u2.save()
        Student.objects.create(user=u1, class_group=sample_class_group)
        Student.objects.create(user=u2, class_group=cg2)

        resp = auth_client.get(
            f'/api/v1/teacher/students/?search=张&class_id={sample_class_group.id}'
        )
        assert resp.status_code == 200
        assert len(resp.data['data']) == 1
        assert '张' in resp.data['data'][0]['name']
