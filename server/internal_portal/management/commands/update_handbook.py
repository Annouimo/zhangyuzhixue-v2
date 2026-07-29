from pathlib import Path
import tomllib

from auditlog.context import set_actor
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from internal_portal.models import (
    BusinessArea,
    HandbookSection,
    HandbookUpdate,
    PortalEntry,
)


class Command(BaseCommand):
    help = 'Preview or apply a structured project handbook content update.'

    def add_arguments(self, parser):
        parser.add_argument('--file', required=True)
        mode = parser.add_mutually_exclusive_group()
        mode.add_argument('--check', action='store_true')
        mode.add_argument('--apply', action='store_true')
        parser.add_argument('--actor', help='Existing user recorded by auditlog.')

    def handle(self, *args, **options):
        apply_changes = options['apply']
        actor = self._get_actor(options.get('actor'), apply_changes)
        data = self._load_file(options['file'])

        try:
            with transaction.atomic():
                with set_actor(actor):
                    counts = self._process(data)
                if not apply_changes:
                    transaction.set_rollback(True)
        except (ValidationError, ValueError) as exc:
            raise CommandError(str(exc)) from exc

        mode = 'APPLY' if apply_changes else 'CHECK'
        self.stdout.write(
            f'{mode}: {counts["create"]} create, '
            f'{counts["update"]} update, {counts["delete"]} delete, '
            f'{counts["unchanged"]} unchanged'
        )

    def _get_actor(self, username, apply_changes):
        if not apply_changes:
            return None
        if not username:
            raise CommandError('--actor is required with --apply.')
        try:
            return get_user_model().objects.get(username=username, is_active=True)
        except get_user_model().DoesNotExist as exc:
            raise CommandError('The audit actor does not exist or is inactive.') from exc

    def _load_file(self, input_file):
        path = Path(input_file)
        if not path.is_file():
            raise CommandError(f'Update file does not exist: {path}')
        try:
            with path.open('rb') as handle:
                data = tomllib.load(handle)
        except tomllib.TOMLDecodeError as exc:
            raise CommandError(f'Invalid TOML: {exc}') from exc
        allowed = {'summary', 'areas', 'sections', 'entries', 'updates'}
        unknown = set(data) - allowed
        if unknown:
            raise CommandError(f'Unknown top-level keys: {sorted(unknown)}')
        return data

    def _process(self, data):
        counts = {'create': 0, 'update': 0, 'delete': 0, 'unchanged': 0}
        for item in data.get('areas', []):
            self._upsert_area(item, counts)
        for item in data.get('sections', []):
            self._upsert_section(item, counts)
        for item in data.get('entries', []):
            self._upsert_entry(item, counts)
        for item in data.get('updates', []):
            self._upsert_update(item, counts)
        return counts

    def _upsert_area(self, item, counts):
        self._validate_keys(
            item,
            {
                'slug', 'name', 'summary', 'status', 'is_visible',
                'sort_order', 'action',
            },
        )
        slug = self._required(item, 'slug')
        area = BusinessArea.objects.filter(slug=slug).first()
        self._apply_object(
            area, BusinessArea(slug=slug), item,
            ('name', 'summary', 'status', 'is_visible', 'sort_order'),
            counts, f'area {slug}',
        )

    def _upsert_section(self, item, counts):
        self._validate_keys(
            item,
            {
                'area', 'key', 'title', 'display_type', 'body',
                'is_visible', 'sort_order', 'action',
            },
        )
        area = self._area(item)
        slug = self._required(item, 'key')
        section = HandbookSection.objects.filter(page=area, slug=slug).first()
        new_section = HandbookSection(page=area, slug=slug)
        self._apply_object(
            section, new_section, item,
            ('title', 'display_type', 'body', 'is_visible', 'sort_order'),
            counts, f'section {area.slug}/{slug}',
        )

    def _upsert_entry(self, item, counts):
        self._validate_keys(
            item,
            {
                'area', 'key', 'section', 'name', 'entry_type',
                'description', 'status', 'url', 'link_label', 'is_visible',
                'sort_order', 'action',
            },
        )
        area = self._area(item)
        key = self._required(item, 'key')
        entry = PortalEntry.objects.filter(area=area, key=key).first()
        new_entry = PortalEntry(area=area, key=key)
        section_key = item.get('section')
        if section_key is not None:
            section = HandbookSection.objects.filter(
                page=area, slug=section_key,
            ).first()
            if section is None:
                raise ValueError(
                    f'Unknown section: {area.slug}/{section_key}'
                )
            item = {**item, 'section': section}
        self._apply_object(
            entry, new_entry, item,
            (
                'section', 'name', 'entry_type', 'description', 'status',
                'url', 'link_label', 'is_visible', 'sort_order',
            ),
            counts, f'entry {area.slug}/{key}',
        )

    def _upsert_update(self, item, counts):
        self._validate_keys(
            item,
            {'date', 'title', 'description', 'sort_order', 'action'},
        )
        date = self._required(item, 'date')
        title = self._required(item, 'title')
        update = HandbookUpdate.objects.filter(date=date, title=title).first()
        new_update = HandbookUpdate(date=date, title=title)
        self._apply_object(
            update, new_update, item, ('description', 'sort_order'),
            counts, f'update {date}/{title}',
        )

    def _apply_object(
        self, current, new_object, item, fields, counts, label,
    ):
        action = item.get('action', 'upsert')
        if action not in {'upsert', 'delete'}:
            raise ValueError(f'{label}: action must be upsert or delete.')
        if action == 'delete':
            if current is None:
                counts['unchanged'] += 1
                self.stdout.write(f'UNCHANGED {label} (already absent)')
            else:
                counts['delete'] += 1
                self.stdout.write(f'DELETE {label}')
                current.delete()
            return

        target = current or new_object
        changed = []
        for field in fields:
            if field not in item:
                continue
            value = item[field]
            if getattr(target, field) != value:
                setattr(target, field, value)
                changed.append(field)
        target.full_clean()

        if current is None:
            counts['create'] += 1
            self.stdout.write(f'CREATE {label}')
            target.save()
        elif changed:
            counts['update'] += 1
            self.stdout.write(f'UPDATE {label}: {", ".join(changed)}')
            target.save()
        else:
            counts['unchanged'] += 1
            self.stdout.write(f'UNCHANGED {label}')

    def _area(self, item):
        slug = self._required(item, 'area')
        area = BusinessArea.objects.filter(slug=slug).first()
        if area is None:
            raise ValueError(f'Unknown project area: {slug}')
        return area

    @staticmethod
    def _required(item, key):
        value = item.get(key)
        if value in (None, ''):
            raise ValueError(f'Missing required field: {key}')
        return value

    @staticmethod
    def _validate_keys(item, allowed):
        unknown = set(item) - allowed
        if unknown:
            raise ValueError(f'Unknown item fields: {sorted(unknown)}')
