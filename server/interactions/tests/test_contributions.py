import pytest
from django.contrib.auth.models import User
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from accounts.models import Student
from interactions.models import ContentContribution, ContributionRevision
from qbank.models import BaseQuestion, ConceptTag


@pytest.fixture
def auth_client(db):
    user = User.objects.create_user('contributor', password='test123')
    Student.objects.create(user=user, gaokao_year=2026)
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
    }


@pytest.mark.django_db
def test_create_new_question_contribution(auth_client, concept_tag):
    response = auth_client.post(reverse('contribution-list-create'), {
        'contribution_type': 'new_question',
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
def test_config_includes_latex_live(auth_client, concept_tag):
    response = auth_client.get(reverse('contribution-config'))
    assert response.status_code == 200
    assert response.data['data']['latex_editor_url'] == 'https://www.latexlive.com/'
    assert response.data['data']['tags'][0]['name'] == concept_tag.name


@pytest.mark.django_db
def test_legacy_source_fields_are_normalized(auth_client, concept_tag):
    body = {
        'contribution_type': 'new_question',
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
