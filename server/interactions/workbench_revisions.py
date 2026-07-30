import difflib
import json

from qbank.models import WorkbenchRevision

from .review_services import question_payload


CATEGORY_TYPES = {
    'questions': ('题库', ('question',)),
    'tags': ('概念标签', ('tag',)),
    'cards': ('知识卡片', ('card',)),
    'lectures': ('讲义', ('course', 'document')),
}


def _without_internal_ids(value):
    if isinstance(value, dict):
        return {
            key: _without_internal_ids(item)
            for key, item in value.items()
            if key != 'id'
        }
    if isinstance(value, list):
        return [_without_internal_ids(item) for item in value]
    return value


def snapshot_for(content_type, instance):
    if content_type == 'question':
        snapshot = question_payload(instance)
        snapshot.pop('base_updated_at', None)
        snapshot['knowledge_cards'] = list(
            instance.knowledge_cards.order_by('category', 'title')
            .values_list('title', flat=True)
        )
        return _without_internal_ids(snapshot)
    if content_type == 'tag':
        return {
            'name': instance.name,
            'parent': instance.parent.name if instance.parent_id else None,
        }
    if content_type == 'card':
        return {
            'title': instance.title,
            'category': instance.category,
            'content': instance.content,
        }
    if content_type == 'course':
        return {'name': instance.name, 'description': instance.description}
    if content_type == 'document':
        return {
            'course': instance.course.name,
            'chapter': instance.chapter,
            'title': instance.title,
            'md_content': instance.md_content,
        }
    raise ValueError(f'未知内容类型：{content_type}')


def record_revision(content_type, instance, actor, action, note):
    label = instance.stem if content_type == 'question' else str(instance)
    return WorkbenchRevision.objects.create(
        content_type=content_type,
        object_id=instance.pk,
        object_label=label[:255],
        actor=actor,
        action=action,
        note=note.strip(),
        snapshot=snapshot_for(content_type, instance),
    )


def previous_revision(revision):
    return WorkbenchRevision.objects.filter(
        content_type=revision.content_type,
        object_id=revision.object_id,
        pk__lt=revision.pk,
    ).order_by('-pk').first()


def diff_lines(previous, current):
    before = json.dumps(
        previous.snapshot if previous else {}, ensure_ascii=False,
        indent=2, sort_keys=True,
    ).splitlines()
    after = json.dumps(
        current.snapshot, ensure_ascii=False, indent=2, sort_keys=True,
    ).splitlines()
    lines = []
    for line in difflib.unified_diff(
        before, after, fromfile='上一版', tofile='当前版', lineterm='', n=3,
    ):
        kind = 'context'
        if line.startswith('+++') or line.startswith('---'):
            kind = 'file'
        elif line.startswith('@@'):
            kind = 'hunk'
        elif line.startswith('+'):
            kind = 'add'
        elif line.startswith('-'):
            kind = 'remove'
        lines.append({'kind': kind, 'text': line})
    return lines
