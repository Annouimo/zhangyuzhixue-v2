from drf_spectacular.utils import OpenApiResponse, extend_schema
from rest_framework import permissions
from rest_framework.response import Response
from rest_framework.views import APIView

from system.models import DbVersion


class VersionCheckView(APIView):
    """数据库版本检查 — 无需认证"""
    permission_classes = []

    @extend_schema(
        responses={200: OpenApiResponse(description='数据库版本信息')},
    )
    def get(self, request, db_type):
        try:
            version = DbVersion.objects.get(db_type=db_type)
        except DbVersion.DoesNotExist:
            return Response({
                'code': 0,
                'message': 'ok',
                'data': {
                    'schema_version': 0,
                    'data_version': 0,
                    'force_update': False,
                    'message': '暂无数据',
                    'download_url': '',
                    'checksum': '',
                    'size_bytes': 0,
                },
            })

        return Response({
            'code': 0,
            'message': 'ok',
            'data': {
                'schema_version': version.schema_version,
                'data_version': version.data_version,
                'force_update': version.force_update,
                'message': version.message,
                'download_url': request.build_absolute_uri(
                    version.download_url
                ) if version.download_url else '',
                'checksum': version.checksum,
                'size_bytes': version.size_bytes,
            },
        })


class UserVersionCheckView(APIView):
    """用户 data_version 检查 — 需登录，仅返回版本号，不生成 .db.gz"""
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        responses={200: OpenApiResponse(description='用户数据版本信息')},
    )
    def get(self, request):
        student = getattr(request.user, 'student', None)
        if not student:
            return Response({
                'code': 40003, 'message': '仅学生可查询',
                'data': None,
            }, status=403)

        from interactions.sync_views import USER_DB_SCHEMA_VERSION
        return Response({
            'code': 0, 'message': 'ok',
            'data': {
                'schema_version': USER_DB_SCHEMA_VERSION,
                'data_version': student.data_version,
                'force_update': False,
                'message': '你在其他设备上产生了新的学习记录，是否更新？',
                'download_url': '',
                'checksum': '',
                'size_bytes': 0,
            },
        })