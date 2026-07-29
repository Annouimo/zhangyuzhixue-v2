from io import StringIO
from pathlib import Path

import pytest
from auditlog.models import LogEntry
from django.conf import settings
from django.contrib.auth.models import User
from django.core.management import CommandError, call_command

from internal_portal.models import HandbookSection, HandbookUpdate


pytestmark = pytest.mark.django_db


UPDATE_FILE = (
    Path(settings.BASE_DIR)
    / 'internal_portal'
    / 'content_updates'
    / '2026-07-communication.toml'
)


def test_check_previews_without_persisting_changes():
    rules = HandbookSection.objects.get(page__slug='overview', slug='rules')
    original_title = rules.title
    output = StringIO()

    call_command('update_handbook', file=str(UPDATE_FILE), check=True, stdout=output)

    rules.refresh_from_db()
    assert rules.title == original_title
    assert not HandbookSection.objects.filter(
        page__slug='overview', slug='reading-requirements',
    ).exists()
    assert not HandbookUpdate.objects.filter(
        title='补充项目沟通与阅读规范',
    ).exists()
    assert 'CHECK:' in output.getvalue()


def test_apply_requires_an_audit_actor():
    with pytest.raises(CommandError, match='--actor is required'):
        call_command('update_handbook', file=str(UPDATE_FILE), apply=True)


def test_apply_updates_content_and_records_actor():
    actor = User.objects.create_user(username='handbook-editor')
    output = StringIO()

    call_command(
        'update_handbook', file=str(UPDATE_FILE), apply=True,
        actor=actor.username, stdout=output,
    )

    rules = HandbookSection.objects.get(page__slug='overview', slug='rules')
    reading = HandbookSection.objects.get(
        page__slug='overview', slug='reading-requirements',
    )
    assert rules.title == '沟通规范'
    assert '优先在相关群内公开交流' in rules.body
    assert reading.display_type == HandbookSection.DisplayType.TEXT
    assert HandbookUpdate.objects.filter(
        title='补充项目沟通与阅读规范',
    ).exists()
    assert LogEntry.objects.filter(
        actor=actor,
        content_type__app_label='internal_portal',
    ).exists()
    assert 'APPLY:' in output.getvalue()


def test_reapplying_the_same_file_is_unchanged():
    actor = User.objects.create_user(username='repeat-editor')
    call_command(
        'update_handbook', file=str(UPDATE_FILE), apply=True,
        actor=actor.username, stdout=StringIO(),
    )
    output = StringIO()

    call_command(
        'update_handbook', file=str(UPDATE_FILE), apply=True,
        actor=actor.username, stdout=output,
    )

    assert '0 create, 0 update, 0 delete, 4 unchanged' in output.getvalue()


def test_check_supports_dependent_records_in_one_file(tmp_path):
    update_file = tmp_path / 'dependent.toml'
    update_file.write_text(
        '''
[[sections]]
area = "overview"
key = "temporary-section"
title = "临时章节"
display_type = "entries"

[[entries]]
area = "overview"
key = "temporary-entry"
section = "temporary-section"
name = "临时条目"
entry_type = "service"
''',
        encoding='utf-8',
    )

    call_command(
        'update_handbook', file=str(update_file), check=True,
        stdout=StringIO(),
    )

    assert not HandbookSection.objects.filter(slug='temporary-section').exists()


def test_unknown_fields_are_rejected(tmp_path):
    update_file = tmp_path / 'invalid.toml'
    update_file.write_text(
        '''
[[sections]]
area = "overview"
key = "rules"
titel = "拼错的字段"
''',
        encoding='utf-8',
    )

    with pytest.raises(CommandError, match='Unknown item fields'):
        call_command(
            'update_handbook', file=str(update_file), check=True,
            stdout=StringIO(),
        )
