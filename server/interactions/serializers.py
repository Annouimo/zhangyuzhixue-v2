"""同步推送序列化 — batch 校验 + 各 entity_type 数据校验"""

from rest_framework import serializers


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
