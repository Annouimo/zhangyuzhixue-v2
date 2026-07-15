"""教师端 API 序列化器"""
from rest_framework import serializers


class CreateAssignmentSerializer(serializers.Serializer):
    """发布作业请求校验"""
    question_ids = serializers.ListField(
        child=serializers.IntegerField(),
        min_length=1,
    )
    title = serializers.CharField(max_length=128, required=False, allow_blank=True)
    deadline = serializers.DateField()
    description = serializers.CharField(required=False, allow_blank=True, default='')
    class_ids = serializers.ListField(
        child=serializers.IntegerField(),
        min_length=1,
    )
    course_id = serializers.IntegerField(required=False, allow_null=True)


class PatchAssignmentSerializer(serializers.Serializer):
    """修改作业请求校验"""
    deadline = serializers.DateField(required=False)
    description = serializers.CharField(required=False, allow_blank=True)
    title = serializers.CharField(max_length=128, required=False)
