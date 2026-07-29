import json

import pytest
from django.contrib.auth.models import Group, User
from django.urls import reverse

from accounts.models import Student
from accounts.roles import CONTENT_REVIEWER_GROUP
from interactions.models import (
    ContentContribution, ContributionReview, ContributionRevision,
    ContributionTagSelection,
)
from qbank.models import BaseQuestion, ConceptTag, SolutionMethod


def payload(stem='函数 $f(x)=x^2$ 的最小值为'):
    return {
        'schema_version': 1,
        'question_type': 'choice',
        'stem': stem,
        'options': [
            {'key': 'A', 'content': '$-1$'},
            {'key': 'B', 'content': '$0$'},
        ],
        'sub_questions': [
            {'stem': '', 'answer': 'B', 'explanation': '$x^2\\geq 0$'},
        ],
        'source': {'source_type': 'self_created', 'year': None},
        'suggested_tags': ['函数最值'],
        'difficulty': 'easy',
        'calculation': 'very_low',
        'uncertainties': [],
    }


@pytest.fixture
def reviewer(db):
    user = User.objects.create_user('reviewer', password='review-pass-123')
    user.groups.add(Group.objects.get(name=CONTENT_REVIEWER_GROUP))
    return user


@pytest.fixture
def contribution(db):
    user = User.objects.create_user('student-author', password='student-pass-123')
    student = Student.objects.create(user=user)
    item = ContentContribution.objects.create(
        student=student,
        contribution_type=ContentContribution.ContributionType.NEW_QUESTION,
    )
    ContributionRevision.objects.create(
        contribution=item, revision_number=1, normalized_payload=payload()
    )
    ContributionReview.objects.create(
        contribution=item, actor=user, action=ContributionReview.Action.SUBMITTED
    )
    return item


@pytest.mark.django_db
def test_reviewer_login_is_separate_from_student_and_admin(client, reviewer, contribution):
    response = client.post(reverse('review_workbench:login'), {
        'username': reviewer.username, 'password': 'review-pass-123',
    })
    assert response.status_code == 302
    assert response.url == reverse('review_workbench:queue')
    assert reviewer.is_staff is False
    assert client.get(reverse('review_workbench:queue')).status_code == 200


@pytest.mark.django_db
def test_student_cannot_open_review_workbench(client, contribution):
    client.force_login(contribution.student.user)
    response = client.get(reverse('review_workbench:queue'))
    assert response.status_code == 403


@pytest.mark.django_db
def test_reviewer_can_publish_new_question(client, reviewer, contribution):
    tag = ConceptTag.objects.create(name='函数最值')
    ContributionTagSelection.objects.create(
        contribution=contribution, concept_tag=tag
    )
    client.force_login(reviewer)
    response = client.post(
        reverse('review_workbench:detail', args=[contribution.pk]),
        {
            'content_json': json.dumps(payload(stem='审核后的题干')),
            'tags': [str(tag.pk)],
            'note': '内容和答案已核验。',
            'version': contribution.updated_at.isoformat(),
            'action': 'publish',
        },
    )
    assert response.status_code == 302
    contribution.refresh_from_db()
    assert contribution.status == ContentContribution.Status.COMPLETED
    assert contribution.reviewed_by == reviewer
    assert contribution.completed_question.stem == '审核后的题干'
    assert contribution.completed_question.choice_ext.options['B'] == '$0$'
    assert contribution.completed_question.sub_questions.get().answer == 'B'
    assert list(contribution.completed_question.concept_tags.all()) == [tag]


@pytest.mark.django_db
def test_review_update_rejects_stale_version(client, reviewer, contribution):
    client.force_login(reviewer)
    stale_version = contribution.updated_at.isoformat()
    contribution.review_note = '其他审核员已更新'
    contribution.save()
    response = client.post(
        reverse('review_workbench:detail', args=[contribution.pk]),
        {
            'content_json': json.dumps(payload()),
            'note': '准备处理',
            'version': stale_version,
            'action': 'processing',
        },
    )
    assert response.status_code == 200
    assert '已被其他人更新' in response.content.decode()
    contribution.refresh_from_db()
    assert contribution.status == ContentContribution.Status.PENDING


@pytest.mark.django_db
def test_reviewer_can_apply_correction(client, reviewer, contribution):
    question = BaseQuestion.objects.create(question_type='fill', stem='错误题干')
    sub_question = question.sub_questions.create(
        answer='0', explanation='', sort_order=1
    )
    method = SolutionMethod.objects.create(
        sub_question=sub_question, method_name=None, sort_order=1
    )
    tag = ConceptTag.objects.create(name='集合')
    contribution.contribution_type = ContentContribution.ContributionType.QUESTION_CORRECTION
    contribution.question = question
    contribution.save()
    client.force_login(reviewer)
    corrected = payload(stem='修正后的题干')
    response = client.post(
        reverse('review_workbench:detail', args=[contribution.pk]),
        {
            'content_json': json.dumps(corrected),
            'tags': [str(tag.pk)],
            'note': '纠错成立。',
            'version': contribution.updated_at.isoformat(),
            'action': 'publish',
        },
    )
    assert response.status_code == 302
    question.refresh_from_db()
    assert question.stem == '修正后的题干'
    assert question.question_type == 'choice'
    assert SolutionMethod.objects.filter(pk=method.pk).exists()
