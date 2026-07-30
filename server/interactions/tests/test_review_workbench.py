import json
from pathlib import Path

import pytest
from django.contrib.auth.models import Group, User
from django.urls import reverse

from accounts.models import Student
from accounts.roles import CONTENT_REVIEWER_GROUP
from interactions.models import (
    ContentContribution, ContributionReview, ContributionRevision,
    ContributionTagSelection, ContributionTagSuggestion,
)
from qbank.models import BaseQuestion, ConceptTag, SolutionMethod, SolutionStep


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


def test_option_preview_uses_separate_label_and_content_columns():
    script = (
        Path(__file__).parents[1]
        / 'static' / 'review_workbench' / 'workbench.js'
    ).read_text(encoding='utf-8')
    assert "make('span', 'option-content'" in script


def test_solution_target_uses_separate_option_content_column():
    template = (
        Path(__file__).parents[1]
        / 'templates' / 'review_workbench' / 'detail.html'
    ).read_text(encoding='utf-8')
    assert '<span class="option-content">{{ value }}</span>' in template


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
        content_origin=ContentContribution.ContentOrigin.ORIGINAL,
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
    assert response.url == reverse('review_workbench:home')
    assert reviewer.is_staff is False
    assert client.get(reverse('review_workbench:queue')).status_code == 200


@pytest.mark.django_db
def test_student_cannot_open_review_workbench(client, contribution):
    client.force_login(contribution.student.user)
    response = client.get(reverse('review_workbench:queue'))
    assert response.status_code == 403


@pytest.mark.django_db
def test_workbench_sidebar_contains_maintenance_and_review_queues(
    client, reviewer, contribution,
):
    client.force_login(reviewer)
    response = client.get(reverse('review_workbench:queue'))
    content = response.content.decode()
    assert 'class="workbench-sidebar"' in content
    assert '题库维护' in content
    assert '概念标签' in content
    assert '知识卡片' in content
    assert '?type=new_question' in content
    assert '?type=new_solution' in content
    assert '?type=content_change' in content
    assert '?type=problem_report' in content
    assert 'queue-tabs' not in content
    assert '>全部 <' not in content
    assert response.context['status_filter'] == 'active'
    assert '<span class="nav-count">1</span>' in content
    assert content.count('<span class="nav-count">0</span>') == 3


@pytest.mark.django_db
def test_sidebar_counts_are_available_outside_queue(
    client, reviewer, contribution,
):
    client.force_login(reviewer)
    response = client.get(reverse('review_workbench:question_list'))
    assert response.status_code == 200
    assert '<span class="nav-count">1</span>' in response.content.decode()


@pytest.mark.django_db
def test_reviewer_can_publish_new_question(client, reviewer, contribution):
    original_tag = ConceptTag.objects.create(name='原投稿标签')
    tag = ConceptTag.objects.create(name='函数最值')
    ContributionTagSelection.objects.create(
        contribution=contribution, concept_tag=original_tag
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
    assert contribution.status == (
        ContentContribution.Status.APPROVED_PENDING_RELEASE
    )
    assert contribution.reviewed_by == reviewer
    assert contribution.completed_question.stem == '审核后的题干'
    assert contribution.completed_question.choice_ext.options['B'] == '$0$'
    assert contribution.completed_question.sub_questions.get().answer == 'B'
    assert contribution.completed_question.content_origin == 'original'
    assert contribution.completed_question.contributed_by == contribution.student
    assert list(contribution.completed_question.concept_tags.all()) == [tag]
    assert list(
        contribution.tag_selections.values_list('concept_tag', flat=True)
    ) == [original_tag.pk]


@pytest.mark.django_db
def test_publish_preserves_source_name_and_question_number(
    client, reviewer, contribution,
):
    tag = ConceptTag.objects.create(name='来源测试')
    ContributionTagSelection.objects.create(
        contribution=contribution, concept_tag=tag
    )
    content = payload()
    content['source'].update({
        'source_name': '高三第一次联考',
        'question_number': '12',
    })
    client.force_login(reviewer)
    response = client.post(
        reverse('review_workbench:detail', args=[contribution.pk]),
        {
            'content_json': json.dumps(content),
            'tags': [str(tag.pk)],
            'note': '来源已核验。',
            'version': contribution.updated_at.isoformat(),
            'action': 'publish',
        },
    )
    assert response.status_code == 302
    contribution.refresh_from_db()
    assert contribution.completed_question.source_name == '高三第一次联考'
    assert contribution.completed_question.number == '12'


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
def test_status_action_does_not_require_valid_question_json(
    client, reviewer, contribution,
):
    client.force_login(reviewer)
    response = client.post(
        reverse('review_workbench:detail', args=[contribution.pk]),
        {
            'content_json': '{',
            'note': '题目信息不足，请补充条件。',
            'version': contribution.updated_at.isoformat(),
            'action': 'needs_revision',
        },
    )
    assert response.status_code == 302
    contribution.refresh_from_db()
    assert contribution.status == ContentContribution.Status.NEEDS_REVISION


@pytest.mark.django_db
def test_terminal_contribution_is_read_only(client, reviewer, contribution):
    contribution.status = ContentContribution.Status.REJECTED
    contribution.save()
    client.force_login(reviewer)
    response = client.get(
        reverse('review_workbench:detail', args=[contribution.pk])
    )
    content = response.content.decode()
    assert '页面已切换为只读' in content
    assert 'data-review-action=' not in content


@pytest.mark.django_db
def test_needs_revision_waits_for_resubmission_and_is_read_only(
    client, reviewer, contribution,
):
    contribution.status = ContentContribution.Status.NEEDS_REVISION
    contribution.review_note = '请补充条件。'
    contribution.save()
    client.force_login(reviewer)
    response = client.get(
        reverse('review_workbench:detail', args=[contribution.pk])
    )
    content = response.content.decode()
    assert '已打回投稿者修改，等待重新提交' in content
    assert 'data-review-action=' not in content

    response = client.post(
        reverse('review_workbench:detail', args=[contribution.pk]),
        {
            'content_json': json.dumps(payload()),
            'note': '重复处理',
            'version': contribution.updated_at.isoformat(),
            'action': 'rejected',
        },
    )
    assert response.status_code == 200
    contribution.refresh_from_db()
    assert contribution.status == ContentContribution.Status.NEEDS_REVISION


@pytest.mark.django_db
def test_approved_pending_release_is_read_only(client, reviewer, contribution):
    contribution.status = ContentContribution.Status.APPROVED_PENDING_RELEASE
    contribution.save()
    client.force_login(reviewer)
    response = client.get(
        reverse('review_workbench:detail', args=[contribution.pk])
    )
    content = response.content.decode()
    assert '等待下一版题库发布' in content
    assert 'data-review-action=' not in content


@pytest.mark.django_db
def test_publish_requires_tag_suggestion_decision(
    client, reviewer, contribution,
):
    tag = ConceptTag.objects.create(name='已有标签')
    ContributionTagSelection.objects.create(
        contribution=contribution, concept_tag=tag
    )
    ContributionTagSuggestion.objects.create(
        contribution=contribution, suggested_name='待处理新标签'
    )
    client.force_login(reviewer)
    response = client.post(
        reverse('review_workbench:detail', args=[contribution.pk]),
        {
            'content_json': json.dumps(payload()),
            'tags': [str(tag.pk)],
            'note': '内容通过。',
            'version': contribution.updated_at.isoformat(),
            'action': 'publish',
        },
    )
    assert response.status_code == 200
    assert '请处理新标签建议' in response.content.decode()
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


@pytest.mark.django_db
def test_reviewer_can_append_solution_without_changing_existing_method(
    client, reviewer, contribution,
):
    question = BaseQuestion.objects.create(question_type='fill', stem='原题')
    sub = question.sub_questions.create(answer='1', explanation='', sort_order=1)
    existing = SolutionMethod.objects.create(
        sub_question=sub, method_name='原解法', sort_order=1,
    )
    contribution.contribution_type = (
        ContentContribution.ContributionType.NEW_SOLUTION
    )
    contribution.content_origin = ContentContribution.ContentOrigin.ORIGINAL
    contribution.question = question
    contribution.target_sub_question = sub
    contribution.save()
    solution = {
        'method_name': '新解法', 'source': 'contributor_original',
        'summary': '另一条思路',
        'steps': [{'title': '化简', 'content': '$x=1$', 'card_titles': []}],
    }
    client.force_login(reviewer)
    detail_response = client.get(
        reverse('review_workbench:detail', args=[contribution.pk])
    )
    detail_content = detail_response.content.decode()
    assert '对应原题' in detail_content
    assert '原题' in detail_content
    assert '参考答案' in detail_content
    response = client.post(
        reverse('review_workbench:detail', args=[contribution.pk]),
        {
            'content_json': json.dumps(solution),
            'note': '解法成立。',
            'version': contribution.updated_at.isoformat(),
            'action': 'publish',
        },
    )
    assert response.status_code == 302
    assert SolutionMethod.objects.filter(pk=existing.pk).exists()
    added = SolutionMethod.objects.get(method_name='新解法')
    assert added.sub_question == sub
    assert added.content_origin == 'original'
    assert added.contributed_by == contribution.student
    contribution.refresh_from_db()
    assert contribution.completed_solution_method == added
    assert SolutionStep.objects.get(method=added).title == '化简'
