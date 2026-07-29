"""同步推送序列化 — batch 校验 + 各 entity_type 数据校验"""

from rest_framework import serializers

from qbank.models import ConceptTag

from .models import ContentContribution


class BatchItemSerializer(serializers.Serializer):
    """单个 batch 条目"""
    entity_type = serializers.ChoiceField(choices=[
        'submission',
        'step_feedback',
        'card_feedback',
        'question_rating',
        'custom_paper',
        'paper_like',
        'paper_collect',
        'exitRating',
        'preference',
        'points_transaction',
    ])
    local_id = serializers.IntegerField()
    data = serializers.JSONField()


class SyncPushSerializer(serializers.Serializer):
    """同步推送请求 — batch 数组校验"""
    batch = serializers.ListField(
        child=BatchItemSerializer(),
        min_length=1,
        max_length=200,
    )


QUESTION_TYPES = {'choice', 'fill', 'solution'}
SOURCE_TYPES = {
    'gaokao', 'mock_exam', 'school_exam', 'textbook', 'self_created', 'other',
}
DIFFICULTIES = {'basic', 'easy', 'medium', 'hard', 'very_hard'}
CALCULATIONS = {'very_low', 'low', 'high', 'very_high'}
CORRECTION_CATEGORIES = {
    'stem', 'options', 'answer', 'explanation', 'tags', 'source',
    'formatting', 'duplicate', 'other',
}


def validate_question_payload(payload):
    """Validate the stable contribution schema after client-side repair."""
    if not isinstance(payload, dict):
        raise serializers.ValidationError('题目内容必须是 JSON 对象')
    if payload.get('schema_version') != 1:
        raise serializers.ValidationError('不支持的 JSON schema_version')
    question_type = payload.get('question_type')
    if question_type not in QUESTION_TYPES:
        raise serializers.ValidationError('question_type 无效')
    stem = payload.get('stem')
    if not isinstance(stem, str) or not stem.strip():
        raise serializers.ValidationError('题干不能为空')
    if len(stem) > 10000:
        raise serializers.ValidationError('题干过长')

    options = payload.get('options', [])
    if not isinstance(options, list):
        raise serializers.ValidationError('options 必须是数组')
    if question_type == 'choice':
        if len(options) < 2 or len(options) > 8:
            raise serializers.ValidationError('选择题需要 2 至 8 个选项')
        keys = []
        for option in options:
            if not isinstance(option, dict):
                raise serializers.ValidationError('选项格式错误')
            key = str(option.get('key', '')).strip().upper()
            content = option.get('content')
            if not key or not isinstance(content, str) or not content.strip():
                raise serializers.ValidationError('选项标识和内容不能为空')
            keys.append(key)
        if len(keys) != len(set(keys)):
            raise serializers.ValidationError('选项标识不能重复')
    elif options:
        raise serializers.ValidationError('非选择题不能包含 options')

    sub_questions = payload.get('sub_questions', [])
    if not isinstance(sub_questions, list) or not sub_questions:
        raise serializers.ValidationError('至少需要一个小题或答案项')
    if len(sub_questions) > 20:
        raise serializers.ValidationError('小题数量不能超过 20')
    for item in sub_questions:
        if not isinstance(item, dict):
            raise serializers.ValidationError('小题格式错误')
        answer = item.get('answer')
        if not isinstance(answer, str) or not answer.strip():
            raise serializers.ValidationError('每个小题都需要答案')
        for field in ('stem', 'answer', 'explanation'):
            value = item.get(field, '')
            if not isinstance(value, str) or len(value) > 20000:
                raise serializers.ValidationError(f'{field} 格式或长度无效')

    source = payload.get('source', {})
    if not isinstance(source, dict):
        raise serializers.ValidationError('source 必须是对象')
    source_type = source.get('source_type', 'other')
    if source_type not in SOURCE_TYPES:
        raise serializers.ValidationError('source_type 无效')
    year = source.get('year')
    if year is not None and (not isinstance(year, int) or not 1950 <= year <= 2100):
        raise serializers.ValidationError('年份无效')
    source_name = source.get('source_name', source.get('exam_name', ''))
    question_number = source.get('question_number', source.get('number', ''))
    if not isinstance(source_name, str) or len(source_name) > 255:
        raise serializers.ValidationError('试卷或资料名称无效')
    if not isinstance(question_number, str) or len(question_number) > 16:
        raise serializers.ValidationError('原题题号无效')
    source['source_name'] = source_name.strip()
    source['question_number'] = question_number.strip()
    source.pop('exam_name', None)
    source.pop('number', None)
    if payload.get('difficulty') not in DIFFICULTIES:
        raise serializers.ValidationError('difficulty 无效')
    if payload.get('calculation') not in CALCULATIONS:
        raise serializers.ValidationError('calculation 无效')
    uncertainties = payload.get('uncertainties', [])
    if not isinstance(uncertainties, list) or not all(
        isinstance(item, str) for item in uncertainties
    ):
        raise serializers.ValidationError('uncertainties 必须是字符串数组')
    return payload


class TagSuggestionSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=64)
    parent_id = serializers.IntegerField(required=False, allow_null=True)
    reason = serializers.CharField(max_length=500, required=False, allow_blank=True)

    def validate_parent_id(self, value):
        if value is not None and not ConceptTag.objects.filter(pk=value).exists():
            raise serializers.ValidationError('上级标签不存在')
        return value


class ContributionWriteSerializer(serializers.Serializer):
    contribution_type = serializers.ChoiceField(
        choices=ContentContribution.ContributionType.choices,
    )
    question_id = serializers.IntegerField(required=False, allow_null=True)
    raw_json = serializers.CharField(required=False, allow_blank=True, max_length=100000)
    payload = serializers.JSONField()
    tag_ids = serializers.ListField(
        child=serializers.IntegerField(), required=False, default=list,
        max_length=10,
    )
    tag_suggestions = TagSuggestionSerializer(
        many=True, required=False, default=list,
    )

    def validate(self, attrs):
        contribution_type = attrs['contribution_type']
        question_id = attrs.get('question_id')
        payload = attrs['payload']
        if contribution_type == ContentContribution.ContributionType.NEW_QUESTION:
            validate_question_payload(payload)
            if question_id is not None:
                raise serializers.ValidationError('新题投稿不能关联已有题目')
        else:
            if question_id is None:
                raise serializers.ValidationError('题目纠错必须关联已有题目')
            categories = payload.get('categories') if isinstance(payload, dict) else None
            description = payload.get('description') if isinstance(payload, dict) else None
            if not isinstance(categories, list) or not categories:
                raise serializers.ValidationError('请至少选择一个错误类型')
            if not set(categories).issubset(CORRECTION_CATEGORIES):
                raise serializers.ValidationError('错误类型无效')
            if not isinstance(description, str) or len(description.strip()) < 10:
                raise serializers.ValidationError('问题说明至少需要 10 个字符')
        if not attrs.get('tag_ids') and not attrs.get('tag_suggestions'):
            raise serializers.ValidationError('请至少选择或建议一个知识点标签')
        existing_ids = set(
            ConceptTag.objects.filter(pk__in=attrs.get('tag_ids', [])).values_list(
                'pk', flat=True
            )
        )
        if len(existing_ids) != len(set(attrs.get('tag_ids', []))):
            raise serializers.ValidationError('包含不存在的知识点标签')
        return attrs


class ContributionResubmitSerializer(ContributionWriteSerializer):
    contribution_type = serializers.ChoiceField(
        choices=ContentContribution.ContributionType.choices, required=False,
    )
    question_id = serializers.IntegerField(required=False, allow_null=True)
