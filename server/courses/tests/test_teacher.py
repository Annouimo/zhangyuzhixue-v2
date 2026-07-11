"""教师 API 测试 — 组卷/班级/学生/作业 共 ~20 场景"""
import pytest
from datetime import date, timedelta
from django.contrib.auth.models import User
from django.utils import timezone
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
    CustomPaper,
    CustomPaperQuestion,
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


@pytest.fixture
def sample_paper(teacher_user, sample_question, db):
    paper = CustomPaper.objects.create(
        student=Student.objects.create(
            user=User.objects.create_user('paper_owner', password='test123'),
        ),
        title='导数基础练习',
    )
    CustomPaperQuestion.objects.create(
        paper=paper, question=sample_question, sort_order=0,
    )
    return paper


# ── Papers ────────────────────────────────────────────────────


class TestPaperList:
    def test_empty(self, auth_client):
        resp = auth_client.get('/api/v1/teacher/papers/')
        assert resp.status_code == 200
        assert resp.data['code'] == 0
        assert resp.data['data'] == []

    def test_with_data(self, auth_client, sample_paper):
        resp = auth_client.get('/api/v1/teacher/papers/')
        assert resp.status_code == 200
        data = resp.data['data']
        assert len(data) == 1
        assert data[0]['title'] == '导数基础练习'
        assert data[0]['questionCount'] == 1


# ── Classes ───────────────────────────────────────────────────


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
        assert d['avgAccuracy'] == '0%'
        assert d['items'][0]['id'] == sample_class_group.id
        assert d['items'][0]['name'] == '高三(1)班'
        assert d['items'][0]['studentCount'] == 0
        assert d['items'][0]['avgAccuracy'] == '0%'


# ── Students ──────────────────────────────────────────────────


class TestStudentList:
    def test_all(self, auth_client, sample_students):
        resp = auth_client.get('/api/v1/teacher/students/')
        assert resp.status_code == 200
        data = resp.data['data']
        assert len(data) == 3

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
        assert d['overview']['avgAccuracy'] == '50%'

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

    def test_with_data(self, auth_client, sample_class_group, sample_paper, sample_question):
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
    def test_normal(self, auth_client, sample_class_group, sample_paper):
        # Create a ClassCourse for the class group
        course = Course.objects.create(name='数学')
        ClassCourse.objects.create(class_group=sample_class_group, course=course)
        resp = auth_client.post('/api/v1/teacher/assignments/', {
            'paper_id': sample_paper.id,
            'title': '新作业',
            'deadline': '2026-07-20',
            'description': '请认真完成',
            'class_ids': [sample_class_group.id],
        }, format='json')
        assert resp.status_code == 200
        assert resp.data['data']['id'] is not None
        # verify assignment created
        assert Assignment.objects.count() == 1
        a = Assignment.objects.first()
        assert a.title == '新作业'
        assert a.description == '请认真完成'
        assert AssignmentQuestion.objects.count() == 1
        assert ClassCourseAssignment.objects.count() == 1

    def test_missing_params(self, auth_client):
        resp = auth_client.post('/api/v1/teacher/assignments/', {
            'paper_id': 1,
        }, format='json')
        assert resp.status_code == 400
        assert resp.data['code'] != 0

    def test_nonexistent_paper(self, auth_client):
        resp = auth_client.post('/api/v1/teacher/assignments/', {
            'paper_id': 99999,
            'deadline': '2026-07-20',
            'class_ids': [1],
        }, format='json')
        assert resp.status_code == 404


class TestAssignmentDetail:
    def test_normal(self, auth_client, sample_class_group, sample_students,
                    sample_paper, sample_question):
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
        # Convert stored datetime to local date for comparison
        stored_date = timezone.localtime(cca.deadline).strftime('%Y-%m-%d')
        assert stored_date == new_date

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
        resp = api_client.get('/api/v1/teacher/papers/')
        assert resp.status_code == 401

    def test_student_cannot_access(self, api_client, db):
        user = User.objects.create_user('student_only', password='test123')
        Student.objects.create(user=user)
        refresh = RefreshToken.for_user(user)
        api_client.credentials(HTTP_AUTHORIZATION='Bearer ' + str(refresh.access_token))
        resp = api_client.get('/api/v1/teacher/papers/')
        assert resp.status_code == 403
