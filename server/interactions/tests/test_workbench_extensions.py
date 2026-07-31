import pytest
from django.contrib.auth.models import Group, Permission, User
from django.urls import reverse

from accounts.roles import CONTENT_REVIEWER_GROUP
from courses.models import Course, Document, Video, VideoCategory, VideoDocumentLink
from interactions.models import ReviewerTrainingProgress
from qbank.models import ContentChangeLog, WorkbenchRevision
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
    document = Document.objects.get(course=course, title='函数')
    assert document.title == '函数'
    assert response.url == reverse(
        'review_workbench:document_edit', args=[document.pk]
    )


@pytest.fixture
def video_content(db):
    course = Course.objects.create(name='视频讲义')
    document = Document.objects.create(
        course=course, chapter='01', title='集合', md_content='# 集合',
    )
    category = VideoCategory.objects.create(name='专题讲解')
    return category, document


@pytest.mark.django_db
def test_video_draft_save_records_actor_and_can_be_previewed(
    client, reviewer, video_content,
):
    category, document = video_content
    client.force_login(reviewer)
    response = client.post(reverse('review_workbench:video_create'), {
        'category': category.pk, 'title': '集合入门',
        'description': '测试简介', 'cover_url': '',
        'platform_name': '', 'video_url': 'https://example.com/video',
        'published_at': '', 'sort_order': 10, 'note': '建立视频草稿',
        'action': 'draft', 'links-TOTAL_FORMS': '1',
        'links-INITIAL_FORMS': '0', 'links-MIN_NUM_FORMS': '0',
        'links-MAX_NUM_FORMS': '1000', 'links-0-document': document.pk,
        'links-0-relation_label': '配套讲解', 'links-0-sort_order': 0,
    })

    video = Video.objects.get(title='集合入门')
    assert response.status_code == 302
    assert video.is_published is False
    revision = WorkbenchRevision.objects.get(
        content_type='video', object_id=video.pk,
    )
    assert revision.actor == reviewer
    assert revision.note == '建立视频草稿'
    assert revision.snapshot['documents'][0]['document'].endswith('集合')
    assert ContentChangeLog.objects.filter(
        object_type='video', object_id=video.pk, actor=reviewer,
    ).exists()

    preview = client.get(reverse(
        'review_workbench:video_preview', args=[video.pk],
    ))
    assert preview.status_code == 200
    assert '内部预览' in preview.content.decode()
    assert 'open_app' not in preview.content.decode()


@pytest.mark.django_db
def test_video_cannot_publish_without_document(client, reviewer, video_content):
    category, _ = video_content
    client.force_login(reviewer)
    response = client.post(reverse('review_workbench:video_create'), {
        'category': category.pk, 'title': '待关联讲义',
        'description': '', 'cover_url': 'https://example.com/cover.jpg',
        'platform_name': '哔哩哔哩',
        'video_url': 'https://example.com/video',
        'published_at': '2026-07-31', 'sort_order': 0,
        'note': '尝试上架', 'action': 'publish',
        'links-TOTAL_FORMS': '1', 'links-INITIAL_FORMS': '0',
        'links-MIN_NUM_FORMS': '0', 'links-MAX_NUM_FORMS': '1000',
        'links-0-document': '', 'links-0-relation_label': '',
        'links-0-sort_order': 0,
    })

    assert response.status_code == 200
    assert '上架前请至少关联一篇讲义' in response.content.decode()
    assert not Video.objects.filter(title='待关联讲义').exists()


@pytest.mark.django_db
def test_video_publish_records_relation_and_history(
    client, reviewer, video_content,
):
    category, document = video_content
    video = Video.objects.create(
        category=category, title='集合专题',
        video_url='https://example.com/video',
    )
    client.force_login(reviewer)
    response = client.post(reverse(
        'review_workbench:video_edit', args=[video.pk],
    ), {
        'category': category.pk, 'title': '集合专题精讲',
        'description': '完整简介',
        'cover_url': 'https://example.com/cover.jpg',
        'platform_name': '哔哩哔哩',
        'video_url': 'https://example.com/video',
        'published_at': '2026-07-31', 'sort_order': 0,
        'note': '资料齐全，正式上架', 'action': 'publish',
        'links-TOTAL_FORMS': '1', 'links-INITIAL_FORMS': '0',
        'links-MIN_NUM_FORMS': '0', 'links-MAX_NUM_FORMS': '1000',
        'links-0-document': document.pk,
        'links-0-relation_label': '配套讲解', 'links-0-sort_order': 0,
    })

    video.refresh_from_db()
    assert response.status_code == 302
    assert video.is_published is True
    assert VideoDocumentLink.objects.filter(
        video=video, document=document,
    ).exists()
    revisions = WorkbenchRevision.objects.filter(
        content_type='video', object_id=video.pk,
    ).order_by('pk')
    assert revisions.count() == 2
    assert revisions[0].action == 'baseline'
    assert revisions[1].action == 'publish'
    history = client.get(reverse(
        'review_workbench:revision_list', args=['videos'],
    ))
    assert history.status_code == 200
    assert '集合专题精讲' in history.content.decode()


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
