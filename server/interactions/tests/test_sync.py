"""同步推送 API 测试"""

import pytest
from django.contrib.auth.models import User
from django.urls import reverse
from rest_framework.test import APIClient

from accounts.models import Student
from interactions.models import (
    CardFeedback,
    CustomPaper,
    PaperFolder,
    PaperLike,
    QuestionRating,
    StepFeedback,
    StudentSubmission,
    SubmissionDetail,
)
from qbank.models import BaseQuestion
from system.models import PointsTransaction, SystemConfig


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def student_user(db):
    user = User.objects.create_user('syncstudent', password='test123')
    Student.objects.create(user=user, gaokao_year=2026)
    return user


@pytest.fixture
def auth_client(api_client, student_user):
    from rest_framework_simplejwt.tokens import RefreshToken
    refresh = RefreshToken.for_user(student_user)
    token = str(refresh.access_token)
    api_client.credentials(HTTP_AUTHORIZATION='Bearer ' + token)
    return api_client


@pytest.fixture
def sample_question(db):
    from qbank.models import ConceptTag
    tag = ConceptTag.objects.create(name='测试标签')
    q = BaseQuestion.objects.create(
        question_type='choice', stem='测试题目',
        difficulty=5.0, calculation=3.0,
    )
    q.concept_tags.add(tag)
    return q


@pytest.fixture
def another_question(db):
    return BaseQuestion.objects.create(
        question_type='fill', stem='填空题',
        difficulty=3.0, calculation=2.0,
    )


# ── 认证测试 ──


class TestSyncAuth:

    def test_unauthenticated_push(self, api_client):
        resp = api_client.post(reverse('sync-push'), {
            'batch': [{'entity_type': 'submission', 'local_id': 1, 'data': {}}]
        }, format='json')
        assert resp.status_code == 401

    def test_invalid_format(self, auth_client):
        resp = auth_client.post(reverse('sync-push'), {
            'batch': 'not-a-list'
        }, format='json')
        assert resp.status_code == 400
        assert resp.data['code'] == 40301


class TestPaperFolderSync:

    def test_create_and_update_full_snapshot(
        self, auth_client, student_user, sample_question, another_question
    ):
        created = auth_client.post(reverse('sync-push'), {
            'batch': [{
                'entity_type': 'paper_folder',
                'local_id': 501,
                'data': {
                    'client_id': 'folder-501-created-at',
                    'base_revision': 0,
                    'name': '函数试题篮',
                    'updated_at': '2026-07-29T10:00:00+08:00',
                    'questions': [
                        {'question_id': sample_question.pk, 'sort_order': 0},
                    ],
                },
            }],
        }, format='json')
        assert created.status_code == 200
        server_id = created.data['data']['server_ids'][501]
        revision = created.data['data']['entity_meta'][501]['revision']

        updated = auth_client.post(reverse('sync-push'), {
            'batch': [{
                'entity_type': 'paper_folder',
                'local_id': 501,
                'data': {
                    'server_id': server_id,
                    'client_id': 'folder-501-created-at',
                    'base_revision': revision,
                    'name': '函数与数列',
                    'updated_at': '2026-07-29T11:00:00+08:00',
                    'questions': [
                        {'question_id': another_question.pk, 'sort_order': 0},
                        {'question_id': sample_question.pk, 'sort_order': 1},
                    ],
                },
            }],
        }, format='json')
        assert updated.status_code == 200

        folder = PaperFolder.objects.get(pk=server_id)
        assert folder.student == student_user.student
        assert folder.name == '函数与数列'
        assert list(folder.folder_questions.values_list(
            'question_id', flat=True
        )) == [another_question.pk, sample_question.pk]

    def test_delete_is_scoped_to_current_student(
        self, auth_client, student_user
    ):
        from django.utils import timezone
        folder = PaperFolder.objects.create(
            student=student_user.student,
            name='待删除',
            client_updated_at=timezone.now(),
        )

        response = auth_client.post(reverse('sync-push'), {
            'batch': [{
                'entity_type': 'paper_folder',
                'local_id': 502,
                'data': {
                    'server_id': folder.pk,
                    'deleted': True,
                    'updated_at': '2026-07-29T12:00:00+08:00',
                },
            }],
        }, format='json')

        assert response.status_code == 200
        assert not PaperFolder.objects.filter(pk=folder.pk).exists()


# ── 提交 ──


class TestSyncSubmission:

    def test_submission_basic(self, auth_client, student_user, sample_question):
        resp = auth_client.post(reverse('sync-push'), {
            'batch': [{
                'entity_type': 'submission',
                'local_id': 100,
                'data': {
                    'details': [{
                        'question_id': sample_question.pk,
                        'attempt_number': 1,
                        'status': 'completed',
                        'answer_text': 'A',
                        'is_correct': True,
                    }],
                },
            }],
        }, format='json')
        assert resp.status_code == 200
        assert resp.data['code'] == 0
        assert 100 in resp.data['data']['server_ids']

        sub = StudentSubmission.objects.get(student=student_user.student)
        assert sub.details.count() == 1
        detail = sub.details.first()
        assert detail.answer_text == 'A'
        assert detail.is_correct is True


# ── 步骤反馈 ──


class TestSyncStepFeedback:

    def test_step_feedback_basic(self, auth_client, student_user, sample_question):
        sub = StudentSubmission.objects.create(student=student_user.student)
        detail = SubmissionDetail.objects.create(
            submission=sub, question=sample_question,
            attempt_number=1, status='completed',
        )
        resp = auth_client.post(reverse('sync-push'), {
            'batch': [{
                'entity_type': 'step_feedback',
                'local_id': 200,
                'data': {
                    'submission_detail_id': detail.pk,
                    'question_id': sample_question.pk,
                    'sub_question_index': 0,
                    'step_number': 1,
                    'status': 'full_correct',
                },
            }],
        }, format='json')
        assert resp.status_code == 200
        assert resp.data['code'] == 0
        sf = StepFeedback.objects.first()
        assert sf.step_number == 1
        assert sf.status == 'full_correct'


# ── 卡片反馈 ──


class TestSyncCardFeedback:

    def test_card_feedback_basic(self, auth_client, student_user, sample_question):
        sub = StudentSubmission.objects.create(student=student_user.student)
        detail = SubmissionDetail.objects.create(
            submission=sub, question=sample_question,
        )
        resp = auth_client.post(reverse('sync-push'), {
            'batch': [{
                'entity_type': 'card_feedback',
                'local_id': 300,
                'data': {
                    'submission_detail_id': detail.pk,
                    'question_id': sample_question.pk,
                    'card_title': '勾股定理',
                    'card_status': 'mastered',
                },
            }],
        }, format='json')
        assert resp.status_code == 200
        assert resp.data['code'] == 0
        cf = CardFeedback.objects.first()
        assert cf.card_title == '勾股定理'
        assert cf.card_status == 'mastered'


# ── 评分 ──


class TestSyncRating:

    def test_rating_create(self, auth_client, student_user, sample_question):
        resp = auth_client.post(reverse('sync-push'), {
            'batch': [{
                'entity_type': 'question_rating',
                'local_id': 400,
                'data': {
                    'question_id': sample_question.pk,
                    'difficulty_score': 7,
                    'calculation_score': 5,
                    'elegance_score': 8,
                },
            }],
        }, format='json')
        assert resp.status_code == 200
        r = QuestionRating.objects.get(student=student_user.student)
        assert r.difficulty_score == 7

    def test_rating_update(self, auth_client, student_user, sample_question):
        QuestionRating.objects.create(
            student=student_user.student, question=sample_question,
            difficulty_score=1, calculation_score=1, elegance_score=1,
        )
        auth_client.post(reverse('sync-push'), {
            'batch': [{
                'entity_type': 'question_rating',
                'local_id': 401,
                'data': {
                    'question_id': sample_question.pk,
                    'difficulty_score': 9,
                    'calculation_score': 8,
                    'elegance_score': 7,
                },
            }],
        }, format='json')
        assert QuestionRating.objects.count() == 1
        r = QuestionRating.objects.first()
        assert r.difficulty_score == 9


# ── 组卷 ──


class TestSyncCustomPaper:

    def test_paper_with_questions(self, auth_client, student_user,
                                  sample_question, another_question):
        resp = auth_client.post(reverse('sync-push'), {
            'batch': [{
                'entity_type': 'custom_paper',
                'local_id': 500,
                'data': {
                    'title': '我的组卷',
                    'description': '周末练习',
                    'is_public': True,
                    'questions': [sample_question.pk, another_question.pk],
                },
            }],
        }, format='json')
        assert resp.status_code == 200
        assert resp.data['code'] == 0
        paper = CustomPaper.objects.first()
        assert paper.title == '我的组卷'
        assert paper.is_public is True
        assert paper.paper_questions.count() == 2


# ── 点赞 ──


class TestSyncPaperLike:

    def test_like_create(self, auth_client, student_user):
        paper = CustomPaper.objects.create(
            student=student_user.student, title='被赞的组卷',
        )
        resp = auth_client.post(reverse('sync-push'), {
            'batch': [{
                'entity_type': 'paper_like',
                'local_id': 600,
                'data': {'paper_id': paper.pk},
            }],
        }, format='json')
        assert resp.status_code == 200
        assert PaperLike.objects.count() == 1

    def test_like_idempotent(self, auth_client, student_user):
        paper = CustomPaper.objects.create(
            student=student_user.student, title='幂等测试',
        )
        PaperLike.objects.create(student=student_user.student, paper=paper)
        resp = auth_client.post(reverse('sync-push'), {
            'batch': [{
                'entity_type': 'paper_like',
                'local_id': 601,
                'data': {'paper_id': paper.pk},
            }],
        }, format='json')
        assert resp.status_code == 200
        assert PaperLike.objects.count() == 1


# ── 混合 batch ──


class TestSyncMixedBatch:

    def test_mixed_submission_and_feedback(self, auth_client, student_user,
                                           sample_question):
        sub_resp = auth_client.post(reverse('sync-push'), {
            'batch': [{
                'entity_type': 'submission',
                'local_id': 1,
                'data': {
                    'details': [{
                        'question_id': sample_question.pk,
                        'attempt_number': 1,
                        'status': 'completed',
                        'answer_text': 'B',
                        'is_correct': False,
                    }],
                },
            }],
        }, format='json')
        sub_id = sub_resp.data['data']['server_ids'][1]
        detail = SubmissionDetail.objects.get(submission_id=sub_id)
        resp = auth_client.post(reverse('sync-push'), {
            'batch': [
                {
                    'entity_type': 'step_feedback',
                    'local_id': 10,
                    'data': {
                        'submission_detail_id': detail.pk,
                        'question_id': sample_question.pk,
                        'step_number': 1,
                        'status': 'partial_correct',
                    },
                },
                {
                    'entity_type': 'card_feedback',
                    'local_id': 11,
                    'data': {
                        'submission_detail_id': detail.pk,
                        'question_id': sample_question.pk,
                        'card_title': '余弦定理',
                        'card_status': 'not_understood',
                    },
                },
            ],
        }, format='json')
        assert resp.status_code == 200
        assert resp.data['code'] == 0
        assert StepFeedback.objects.count() == 1
        assert CardFeedback.objects.count() == 1

    def test_full_batch_all_types(self, auth_client, student_user, sample_question):
        sub = StudentSubmission.objects.create(student=student_user.student)
        detail = SubmissionDetail.objects.create(
            submission=sub, question=sample_question,
        )
        resp = auth_client.post(reverse('sync-push'), {
            'batch': [
                {
                    'entity_type': 'step_feedback',
                    'local_id': 1,
                    'data': {
                        'submission_detail_id': detail.pk,
                        'question_id': sample_question.pk,
                        'step_number': 1,
                        'status': 'full_correct',
                    },
                },
                {
                    'entity_type': 'card_feedback',
                    'local_id': 2,
                    'data': {
                        'submission_detail_id': detail.pk,
                        'question_id': sample_question.pk,
                        'card_title': '韦达定理',
                        'card_status': 'understood',
                    },
                },
                {
                    'entity_type': 'question_rating',
                    'local_id': 3,
                    'data': {
                        'question_id': sample_question.pk,
                        'difficulty_score': 5,
                        'calculation_score': 4,
                        'elegance_score': 6,
                    },
                },
                {
                    'entity_type': 'custom_paper',
                    'local_id': 4,
                    'data': {
                        'title': '全类型测试',
                        'questions': [sample_question.pk],
                    },
                },
            ],
        }, format='json')
        assert resp.status_code == 200
        assert resp.data['code'] == 0
        assert StepFeedback.objects.count() == 1
        assert CardFeedback.objects.count() == 1
        assert QuestionRating.objects.count() == 1
        assert CustomPaper.objects.count() == 1


class TestSyncEdgeCases:

    def test_failed_batch_rolls_back_prior_items(
        self, auth_client, student_user, sample_question,
    ):
        initial_version = student_user.student.data_version
        resp = auth_client.post(reverse('sync-push'), {
            'batch': [
                {
                    'entity_type': 'submission',
                    'local_id': 900,
                    'data': {
                        'details': [{
                            'question_id': sample_question.pk,
                            'status': 'completed',
                        }],
                    },
                },
                {
                    'entity_type': 'points_transaction',
                    'local_id': 901,
                    'data': {
                        'source': 'RATING_REWARD',
                        'source_object_id': sample_question.pk,
                    },
                },
            ],
        }, format='json')

        assert resp.status_code == 500
        assert StudentSubmission.objects.count() == 0
        student_user.student.refresh_from_db()
        assert student_user.student.data_version == initial_version

    def test_rating_reward_is_granted_once_with_server_amount(
        self, auth_client, student_user, sample_question,
    ):
        QuestionRating.objects.create(
            student=student_user.student,
            question=sample_question,
            difficulty_score=5,
            calculation_score=5,
            elegance_score=5,
        )
        SystemConfig.objects.update_or_create(
            key='question_rating_reward',
            defaults={'value': '0.3'},
        )
        for local_id in (100, 101):
            resp = auth_client.post(reverse('sync-push'), {
                'batch': [{
                    'entity_type': 'points_transaction',
                    'local_id': local_id,
                    'data': {
                        'amount': 999,
                        'source': 'RATING_REWARD',
                        'source_object_id': sample_question.pk,
                        'transaction_type': 'EARN',
                    },
                }],
            }, format='json')
            assert resp.status_code == 200

        rewards = PointsTransaction.objects.filter(
            student=student_user.student,
            source='RATING_REWARD',
            source_object_id=sample_question.pk,
        )
        assert rewards.count() == 1
        assert rewards.get().amount == pytest.approx(0.3)

    def test_empty_batch(self, auth_client):
        """空 batch：拒绝处理"""
        resp = auth_client.post(reverse('sync-push'), {
            'batch': [],
        }, format='json')
        assert resp.status_code == 400
        assert resp.data['code'] == 40301

    def test_invalid_entity_type(self, auth_client):
        """不支持的 entity_type：返回 400"""
        resp = auth_client.post(reverse('sync-push'), {
            'batch': [{'entity_type': 'unknown_type', 'local_id': 1, 'data': {}}],
        }, format='json')
        assert resp.status_code == 400
        assert resp.data['code'] == 40301


# ── 用户数据拉取 ──


class TestSyncPullUserDB:

    def test_unauthenticated_pull(self, api_client):
        """未认证请求 → 401"""
        resp = api_client.get(reverse('sync-user-pull'))
        assert resp.status_code == 401

    def test_non_student_pull(self, api_client, db):
        """无学生权限的普通用户在权限层被拒绝。"""
        from django.contrib.auth.models import User
        from rest_framework_simplejwt.tokens import RefreshToken
        user = User.objects.create_user('plain_user', password='test123')
        refresh = RefreshToken.for_user(user)
        api_client.credentials(HTTP_AUTHORIZATION='Bearer ' + str(refresh.access_token))
        resp = api_client.get(reverse('sync-user-pull'))
        assert resp.status_code == 403

    def test_pull_success_empty(self, auth_client):
        """学生无数据可拉 — 仍返回有效响应"""
        resp = auth_client.get(reverse('sync-user-pull'))
        assert resp.status_code == 200
        assert resp.data['code'] == 0
        data = resp.data['data']
        assert 'download_url' in data
        assert 'checksum' in data
        assert 'size_bytes' in data
        assert data['data_version'] == 0
        assert data['size_bytes'] > 0  # gzip 压缩后的空数据库也有大小

    def test_pull_success_with_data(self, auth_client, student_user, sample_question):
        """学生有提交/评分记录 — 验证数据拉取成功"""
        from interactions.models import StudentSubmission, SubmissionDetail, QuestionRating
        sub = StudentSubmission.objects.create(student=student_user.student)
        SubmissionDetail.objects.create(
            submission=sub, question=sample_question,
            attempt_number=1, status='completed', answer_text='A', is_correct=True,
        )
        QuestionRating.objects.create(
            student=student_user.student, question=sample_question,
            difficulty_score=7, calculation_score=5, elegance_score=8,
        )
        resp = auth_client.get(reverse('sync-user-pull'))
        assert resp.status_code == 200
        assert resp.data['code'] == 0
        data = resp.data['data']
        assert 'download_url' in data
        assert 'checksum' in data
        assert data['size_bytes'] > 0
        assert data['data_version'] == 0
