import pytest
from django.contrib.auth.models import User
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from interactions.models import ContentContribution, ContributionRevision
from qbank.models import BaseQuestion, ConceptTag, SubQuestion


@pytest.fixture
def auth_client(db):
    user = User.objects.create_user('contributor', password='test123')
    student = user.student
    student.gaokao_year = 2026
    student.save(update_fields=['gaokao_year', 'updated_at'])
    client = APIClient()
    client.credentials(
        HTTP_AUTHORIZATION=f'Bearer {RefreshToken.for_user(user).access_token}'
    )
    return client


@pytest.fixture
def concept_tag(db):
    return ConceptTag.objects.create(name='函数最值')


def new_question_payload():
    return {
        'schema_version': 1,
        'question_type': 'choice',
        'stem': '函数 $f(x)=x^2$ 的最小值为',
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
        'originality_confirmed': True,
    }


@pytest.mark.django_db
def test_create_new_question_contribution(auth_client, concept_tag):
    response = auth_client.post(reverse('contribution-list-create'), {
        'contribution_type': 'new_question',
        'content_origin': 'original',
        'raw_json': '{"schema_version":1}',
        'payload': new_question_payload(),
        'tag_ids': [concept_tag.pk],
        'tag_suggestions': [],
    }, format='json')

    assert response.status_code == 200
    assert response.data['data']['status'] == 'pending'
    contribution = ContentContribution.objects.get()
    assert contribution.tag_selections.get().concept_tag == concept_tag
    assert contribution.revisions.get().revision_number == 1


@pytest.mark.django_db
def test_new_question_requires_tag(auth_client):
    response = auth_client.post(reverse('contribution-list-create'), {
        'contribution_type': 'new_question',
        'content_origin': 'original',
        'payload': new_question_payload(),
    }, format='json')

    assert response.status_code == 400
    assert response.data['code'] == 40201


@pytest.mark.django_db
def test_correction_duplicate_and_resubmit(auth_client, concept_tag):
    question = BaseQuestion.objects.create(
        question_type='fill', stem='原题题干'
    )
    body = {
        'contribution_type': 'question_correction',
        'question_id': question.pk,
        'payload': {
            'categories': ['answer'],
            'description': '标准答案中的符号应当修改为正号',
            'suggestion': '建议答案改为 $1$。',
            'evidence': '代入原式可以验证。',
        },
        'tag_ids': [concept_tag.pk],
    }
    response = auth_client.post(
        reverse('contribution-list-create'), body, format='json'
    )
    assert response.status_code == 200
    contribution = ContentContribution.objects.get()
    assert contribution.revisions.get().question_snapshot['stem'] == '原题题干'

    duplicate = auth_client.post(
        reverse('contribution-list-create'), body, format='json'
    )
    assert duplicate.status_code == 400
    assert duplicate.data['code'] == 40901

    contribution.status = ContentContribution.Status.NEEDS_REVISION
    contribution.review_note = '请补充验算过程'
    contribution.save()
    body['payload']['evidence'] = '完整验算过程已经补充。'
    resubmitted = auth_client.post(
        reverse('contribution-resubmit', args=[contribution.pk]),
        body,
        format='json',
    )
    assert resubmitted.status_code == 200
    contribution.refresh_from_db()
    assert contribution.status == ContentContribution.Status.RESUBMITTED
    assert ContributionRevision.objects.filter(
        contribution=contribution
    ).count() == 2


@pytest.mark.django_db
def test_correction_context_includes_original_tag_ids(auth_client, concept_tag):
    question = BaseQuestion.objects.create(
        question_type='fill', stem='带标签的原题'
    )
    question.concept_tags.add(concept_tag)
    response = auth_client.get(
        reverse('contribution-question-context', args=[question.pk])
    )
    assert response.status_code == 200
    assert response.data['data']['tag_ids'] == [concept_tag.pk]
    assert response.data['data']['tags'] == [concept_tag.name]


@pytest.mark.django_db
def test_correction_with_proposed_question_preserves_diff_base(
    auth_client, concept_tag,
):
    question = BaseQuestion.objects.create(
        question_type='fill', stem='原题题干', source_name='原试卷'
    )
    SubQuestion.objects.create(
        question=question, answer='1', explanation='原解析', sort_order=1,
    )
    question.concept_tags.add(concept_tag)
    context_response = auth_client.get(
        reverse('contribution-question-context', args=[question.pk])
    )
    proposed = context_response.data['data']
    proposed['stem'] = '修正后的题干'
    proposed['sub_questions'][0]['answer'] = '2'

    response = auth_client.post(reverse('contribution-list-create'), {
        'contribution_type': 'question_correction',
        'question_id': question.pk,
        'payload': {
            'categories': ['stem', 'answer'],
            'description': '题干常数和参考答案需要同步修正。',
            'evidence': '代入题目条件可验证修正结果。',
            'proposed_question': proposed,
            'base_updated_at': proposed['base_updated_at'],
        },
        'tag_ids': [concept_tag.pk],
    }, format='json')

    assert response.status_code == 200
    revision = ContentContribution.objects.get().revisions.get()
    assert revision.normalized_payload['proposed_question']['stem'] == '修正后的题干'
    assert revision.normalized_payload['proposed_question']['sub_questions'][0][
        'answer'
    ] == '2'
    assert revision.question_snapshot['stem'] == '原题题干'
    assert revision.normalized_payload['base_updated_at'] == (
        question.updated_at.isoformat()
    )


@pytest.mark.django_db
def test_correction_with_proposed_question_requires_base_version(
    auth_client, concept_tag,
):
    question = BaseQuestion.objects.create(
        question_type='fill', stem='原题题干', source_name='原试卷'
    )
    SubQuestion.objects.create(
        question=question, answer='1', explanation='', sort_order=1,
    )
    context_response = auth_client.get(
        reverse('contribution-question-context', args=[question.pk])
    )
    proposed = context_response.data['data']
    proposed['stem'] = '修正后的题干'

    response = auth_client.post(reverse('contribution-list-create'), {
        'contribution_type': 'question_correction',
        'question_id': question.pk,
        'payload': {
            'categories': ['stem'],
            'description': '这里提供了完整修改方案，但缺少原题版本。',
            'proposed_question': proposed,
        },
        'tag_ids': [concept_tag.pk],
    }, format='json')

    assert response.status_code == 400
    assert response.data['code'] == 40201


@pytest.mark.django_db
def test_config_includes_latex_live(auth_client, concept_tag):
    response = auth_client.get(reverse('contribution-config'))
    assert response.status_code == 200
    assert response.data['data']['latex_editor_url'] == 'https://www.latexlive.com/'
    assert response.data['data']['tags'][0]['name'] == concept_tag.name


@pytest.mark.django_db
def test_legacy_source_fields_are_normalized(auth_client, concept_tag):
    body = {
        'contribution_type': 'new_question',
        'content_origin': 'original',
        'payload': new_question_payload(),
        'tag_ids': [concept_tag.pk],
    }
    body['payload']['source'].update({
        'exam_name': '高三第一次联考',
        'number': '12',
    })
    response = auth_client.post(
        reverse('contribution-list-create'), body, format='json'
    )
    assert response.status_code == 200
    payload = response.data['data']['payload']
    assert payload['source']['source_name'] == '高三第一次联考'
    assert payload['source']['question_number'] == '12'
    assert 'exam_name' not in payload['source']
    assert 'number' not in payload['source']


@pytest.mark.django_db
def test_create_solution_contribution_without_reselecting_tags(
    auth_client, concept_tag,
):
    question = BaseQuestion.objects.create(question_type='fill', stem='求函数值')
    question.concept_tags.add(concept_tag)
    sub = SubQuestion.objects.create(
        question=question, answer='1', explanation='', sort_order=1,
    )
    response = auth_client.post(reverse('contribution-list-create'), {
        'contribution_type': 'new_solution',
        'content_origin': 'original',
        'question_id': question.pk,
        'target_sub_question_id': sub.pk,
        'payload': {
            'method_name': '换元法',
            'source': 'contributor_original',
            'summary': '先换元再化简',
            'originality_confirmed': True,
            'steps': [
                {'title': '换元', 'content': '令 $t=x+1$', 'card_titles': []},
            ],
        },
    }, format='json')
    assert response.status_code == 200
    contribution = ContentContribution.objects.get()
    assert contribution.target_sub_question == sub


@pytest.mark.django_db
def test_solution_target_must_belong_to_question(auth_client):
    question = BaseQuestion.objects.create(question_type='fill', stem='题目一')
    other = BaseQuestion.objects.create(question_type='fill', stem='题目二')
    sub = SubQuestion.objects.create(
        question=other, answer='1', explanation='', sort_order=1,
    )
    response = auth_client.post(reverse('contribution-list-create'), {
        'contribution_type': 'new_solution',
        'content_origin': 'external',
        'question_id': question.pk,
        'target_sub_question_id': sub.pk,
        'payload': {
            'method_name': '方法', 'source': '',
            'steps': [{'title': '步骤', 'content': '内容', 'card_titles': []}],
        },
    }, format='json')
    assert response.status_code == 400
    assert response.data['code'] == 40201
