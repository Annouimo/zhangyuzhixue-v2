import json

import pytest
from django.contrib.auth.models import Group, User
from django.urls import reverse

from accounts.models import Student
from accounts.roles import CONTENT_REVIEWER_GROUP
from interactions.models import (
    ContentContribution, ContributionRevision,
)
from interactions.review_services import question_payload
from qbank.models import (
    BaseQuestion, ConceptTag, ContentChangeLog, KnowledgeCard,
    SolutionMethod,
)


@pytest.fixture
def reviewer(db):
    user = User.objects.create_user('workbench-reviewer', password='pass-12345')
    user.groups.add(Group.objects.get(name=CONTENT_REVIEWER_GROUP))
    return user


@pytest.fixture
def student(db):
    user = User.objects.create_user('workbench-student')
    return Student.objects.create(user=user)


def valid_payload(stem='已知 $x=1$，求 $x+1$'):
    return {
        'schema_version': 2,
        'question_type': 'fill',
        'stem': stem,
        'options': [],
        'sub_questions': [{
            'stem': '', 'answer': '2', 'explanation': '直接计算。',
            'solution_methods': [],
        }],
        'source': {
            'source_type': 'self_created', 'year': None, 'region': '',
            'source_name': '', 'question_number': '',
        },
        'content_origin': 'original',
        'images': [],
        'default_score': None,
        'suggested_tags': [],
        'difficulty': 'basic',
        'calculation': 'very_low',
        'uncertainties': [],
    }


@pytest.mark.django_db
def test_correction_virtual_queues_are_mutually_exclusive(
    client, reviewer, student,
):
    question = BaseQuestion.objects.create(question_type='fill', stem='原题')
    question.sub_questions.create(answer='1', explanation='', sort_order=1)
    report = ContentContribution.objects.create(
        student=student, contribution_type='question_correction', question=question,
    )
    ContributionRevision.objects.create(
        contribution=report, revision_number=1,
        normalized_payload={'categories': ['answer'], 'description': '这道题的答案可能存在错误。'},
    )
    change = ContentContribution.objects.create(
        student=student, contribution_type='question_correction', question=question,
    )
    ContributionRevision.objects.create(
        contribution=change, revision_number=1,
        normalized_payload={
            'categories': ['answer'], 'description': '这道题的答案应该修改。',
            'proposed_question': valid_payload(),
        },
    )
    client.force_login(reviewer)

    response = client.get(reverse('review_workbench:queue'), {'type': 'problem_report'})
    assert response.status_code == 200
    assert list(response.context['contributions']) == [report]

    response = client.get(reverse('review_workbench:queue'), {'type': 'content_change'})
    assert response.status_code == 200
    assert list(response.context['contributions']) == [change]


@pytest.mark.django_db
def test_reviewer_can_create_question_with_change_log(client, reviewer):
    tag = ConceptTag.objects.create(name='代数计算')
    card = KnowledgeCard.objects.create(
        title='代入求值', category='流程', content='将已知值代入。'
    )
    client.force_login(reviewer)
    response = client.post(reverse('review_workbench:question_create'), {
        'content_json': json.dumps(valid_payload()),
        'tags': [str(tag.pk)],
        'knowledge_cards': [str(card.pk)],
        'note': '审核员直接录入基础题。',
        'version': 'new',
    })
    assert response.status_code == 302
    question = BaseQuestion.objects.get(stem=valid_payload()['stem'])
    assert list(question.concept_tags.all()) == [tag]
    assert list(question.knowledge_cards.all()) == [card]
    log = ContentChangeLog.objects.get(question=question)
    assert log.actor == reviewer
    assert log.action == 'create'


@pytest.mark.django_db
def test_direct_edit_preserves_existing_solution_method(client, reviewer):
    tag = ConceptTag.objects.create(name='保留解法')
    question = BaseQuestion.objects.create(
        question_type='fill', stem='修改前', content_origin='original'
    )
    question.concept_tags.add(tag)
    sub = question.sub_questions.create(answer='1', explanation='', sort_order=1)
    method = SolutionMethod.objects.create(
        sub_question=sub, method_name='原解法', sort_order=1,
        content_origin='original',
    )
    method.solution_steps.create(step_number=1, title='第一步', content='$x=1$')
    content = question_payload(question)
    content['stem'] = '修改后'
    content['sub_questions'][0].pop('id')
    client.force_login(reviewer)
    response = client.post(
        reverse('review_workbench:question_edit', args=[question.pk]),
        {
            'content_json': json.dumps(content),
            'tags': [str(tag.pk)],
            'knowledge_cards': [],
            'note': '修正题干，保留已有解法。',
            'version': question.updated_at.isoformat(),
        },
    )
    assert response.status_code == 302
    question.refresh_from_db()
    assert question.stem == '修改后'
    assert SolutionMethod.objects.filter(pk=method.pk).exists()


@pytest.mark.django_db
def test_content_maintenance_edits_without_delete_routes(client, reviewer):
    tag = ConceptTag.objects.create(name='原标签')
    card = KnowledgeCard.objects.create(title='原卡片', category='定理', content='原内容')
    client.force_login(reviewer)
    response = client.post(
        reverse('review_workbench:tag_edit', args=[tag.pk]),
        {'name': '新标签', 'parent': '', 'note': '修正标签名称。'},
    )
    assert response.status_code == 302
    tag.refresh_from_db()
    assert tag.name == '新标签'

    response = client.post(
        reverse('review_workbench:card_edit', args=[card.pk]),
        {
            'title': '新卡片', 'category': '定理', 'content': '新内容',
            'note': '修正知识卡片。',
        },
    )
    assert response.status_code == 302
    assert client.post(f'/review/content/tags/{tag.pk}/delete/').status_code == 404
    assert client.post(f'/review/content/cards/{card.pk}/delete/').status_code == 404
