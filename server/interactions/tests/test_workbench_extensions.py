import pytest
from django.contrib.auth.models import Group, Permission, User
from django.urls import reverse

from accounts.roles import CONTENT_REVIEWER_GROUP
from courses.models import Course, Document
from interactions.models import ReviewerTrainingProgress
from system.models import DbVersion


@pytest.fixture
def reviewer(db):
    user = User.objects.create_user('extended-reviewer', password='pass')
    user.groups.add(Group.objects.get(name=CONTENT_REVIEWER_GROUP))
    return user


@pytest.fixture
def limited_reviewer(db):
    user = User.objects.create_user('limited-reviewer', password='pass')
    user.user_permissions.add(Permission.objects.get(codename='access_review_workbench'))
    return user


@pytest.mark.django_db
def test_root_is_reviewer_home(client, reviewer):
    client.force_login(reviewer)
    response = client.get(reverse('review_workbench:home'))
    assert response.status_code == 200
    assert '工作台首页' in response.content.decode()
    assert reverse('review_workbench:queue') in response.content.decode()


@pytest.mark.django_db
def test_reviewer_can_create_lecture_document(client, reviewer):
    course = Course.objects.create(name='代数讲义')
    client.force_login(reviewer)
    response = client.post(reverse('review_workbench:document_create'), {
        'course': course.pk, 'chapter': '01', 'title': '函数',
        'md_content': '# 函数\n\n$f(x)=x$', 'note': '新增培训讲义',
    })
    assert response.status_code == 302
    document = Document.objects.get()
    assert document.title == '函数'
    assert response.url == reverse(
        'review_workbench:document_edit', args=[document.pk]
    )


@pytest.mark.django_db
def test_reviewer_without_publish_permission_cannot_publish(
    client, limited_reviewer, settings, tmp_path,
):
    settings.MEDIA_ROOT = tmp_path
    client.force_login(limited_reviewer)
    response = client.post(reverse('review_workbench:releases'), {
        'db_type': 'qbank', 'action': 'publish',
    })
    assert response.status_code == 403


@pytest.mark.django_db
def test_candidate_build_does_not_change_version(
    client, reviewer, settings, tmp_path,
):
    version = DbVersion.objects.create(
        db_type='courses', schema_version=1, data_version=7, checksum='official',
    )
    settings.MEDIA_ROOT = tmp_path
    settings.BASE_DIR = tmp_path
    course = Course.objects.create(name='代数讲义')
    Document.objects.create(
        course=course, chapter='01', title='函数', md_content='# 函数',
    )
    client.force_login(reviewer)
    response = client.post(reverse('review_workbench:releases'), {
        'db_type': 'courses', 'action': 'candidate',
    })
    assert response.status_code == 200
    version.refresh_from_db()
    assert version.data_version == 7
    assert version.checksum == 'official'
    assert (tmp_path / '.hermes' / 'content-candidates' / 'courses_candidate.db.gz').is_file()
    assert not (tmp_path / 'db' / 'courses_v8.db.gz').exists()


@pytest.mark.django_db
def test_training_steps_unlock_in_order(client, reviewer):
    client.force_login(reviewer)
    client.post(reverse('review_workbench:training'), {'step': 'claim'})
    progress = ReviewerTrainingProgress.objects.get(reviewer=reviewer)
    assert progress.completed_steps == []
    client.post(reverse('review_workbench:training'), {'step': 'submit'})
    client.post(reverse('review_workbench:training'), {'step': 'claim'})
    progress.refresh_from_db()
    assert progress.completed_steps == ['submit', 'claim']


@pytest.mark.django_db
def test_training_provides_named_json_case(client, reviewer):
    client.force_login(reviewer)
    page = client.get(reverse('review_workbench:training'))
    assert page.status_code == 200
    assert 'T-001' in page.content.decode()
    assert '审核员培训样题 T-001' in page.content.decode()

    response = client.get(reverse('review_workbench:training_json'))
    assert response.status_code == 200
    assert response['Content-Type'].startswith('application/json')
    payload = response.json()
    assert payload['source']['question_number'] == 'T-001'
    assert payload['sub_questions'][0]['answer'] == '1'
