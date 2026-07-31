import difflib
import json

from qbank.models import WorkbenchRevision

from .review_services import question_payload


CATEGORY_TYPES = {
    'questions': ('题库', ('question',)),
    'tags': ('概念标签', ('tag',)),
    'cards': ('知识卡片', ('card',)),
    'lectures': ('讲义', ('course', 'document')),
    'videos': ('视频', ('video',)),
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
    if content_type == 'video':
        return {
            'category': instance.category.name,
            'title': instance.title,
            'description': instance.description,
            'cover_url': instance.cover_url,
            'platform_name': instance.platform_name,
            'video_url': instance.video_url,
            'published_at': (
                instance.published_at.isoformat()
                if instance.published_at else None
            ),
            'sort_order': instance.sort_order,
            'is_published': instance.is_published,
            'documents': [
                {
                    'document': str(link.document),
                    'relation_label': link.relation_label,
                    'sort_order': link.sort_order,
                }
                for link in instance.videodocumentlink_set.select_related(
                    'document', 'document__course',
                ).order_by('sort_order', 'id')
            ],
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


def ensure_baseline_revision(content_type, instance):
    """为尚无历史的既有对象保存编辑前基线。"""
    exists = WorkbenchRevision.objects.filter(
        content_type=content_type, object_id=instance.pk,
    ).exists()
    if exists:
        return None
    return record_revision(
        content_type, instance, None, 'baseline',
        '版本历史功能启用时生成的初始基线',
    )


def previous_revision(revision):
    return WorkbenchRevision.objects.filter(
        content_type=revision.content_type,
        object_id=revision.object_id,
        pk__lt=revision.pk,
    ).order_by('-pk').first()


FIELD_SPECS = {
    'question': [
        ('question_type', '题型'), ('stem', '题干'), ('options', '选项'),
        ('sub_questions', '子题、答案、解析与解法'),
        ('source.source_type', '来源类型'), ('source.year', '年份'),
        ('source.region', '地区'), ('source.source_name', '来源名称'),
        ('source.question_number', '题号'), ('content_origin', '内容来源性质'),
        ('contributor_username', '投稿人'), ('images', '配图'),
        ('default_score', '参考分值'), ('tags', '概念标签'),
        ('knowledge_cards', '知识卡片'), ('difficulty', '难度'),
        ('calculation', '计算量'), ('uncertainties', '待确认项'),
    ],
    'tag': [('name', '标签名称'), ('parent', '上级标签')],
    'card': [('title', '标题'), ('category', '分类'), ('content', '正文')],
    'course': [('name', '讲义系列名称'), ('description', '系列说明')],
    'document': [
        ('course', '所属讲义系列'), ('chapter', '讲次'),
        ('title', '标题'), ('md_content', '正文'),
    ],
    'video': [
        ('category', '分类'), ('title', '标题'), ('description', '简介'),
        ('cover_url', '封面地址'), ('platform_name', '发布平台'),
        ('video_url', '视频地址'), ('published_at', '发布日期'),
        ('sort_order', '排序'), ('is_published', '上架状态'),
        ('documents', '配套讲义'),
    ],
}


_MISSING = object()


def _value_at(snapshot, path):
    value = snapshot
    for part in path.split('.'):
        if not isinstance(value, dict) or part not in value:
            return _MISSING
        value = value[part]
    return value


def _display_lines(value):
    if value is _MISSING:
        return []
    if isinstance(value, str):
        return value.splitlines() or ['（空）']
    if value is None:
        return ['（未填写）']
    if isinstance(value, bool):
        return ['是' if value else '否']
    if isinstance(value, (dict, list)):
        if not value:
            return ['（空）']
        return json.dumps(
            value, ensure_ascii=False, indent=2, sort_keys=True,
        ).splitlines()
    return [str(value)]


def _side_by_side_rows(before_lines, after_lines):
    rows = []
    matcher = difflib.SequenceMatcher(None, before_lines, after_lines)
    for operation, old_start, old_end, new_start, new_end in matcher.get_opcodes():
        old_block = before_lines[old_start:old_end]
        new_block = after_lines[new_start:new_end]
        size = max(len(old_block), len(new_block))
        for offset in range(size):
            old_exists = offset < len(old_block)
            new_exists = offset < len(new_block)
            rows.append({
                'old_text': old_block[offset] if old_exists else '',
                'new_text': new_block[offset] if new_exists else '',
                'old_no': old_start + offset + 1 if old_exists else '',
                'new_no': new_start + offset + 1 if new_exists else '',
                'old_kind': (
                    'context' if operation == 'equal' else
                    'remove' if old_exists else 'empty'
                ),
                'new_kind': (
                    'context' if operation == 'equal' else
                    'add' if new_exists else 'empty'
                ),
            })
    return rows


def field_diffs(previous, current):
    before = previous.snapshot if previous else {}
    after = current.snapshot
    fields = []
    for path, label in FIELD_SPECS[current.content_type]:
        old_value = _value_at(before, path)
        new_value = _value_at(after, path)
        if old_value == new_value:
            continue
        old_lines = _display_lines(old_value)
        new_lines = _display_lines(new_value)
        fields.append({
            'path': path,
            'label': label,
            'rows': _side_by_side_rows(old_lines, new_lines),
        })
    return fields
