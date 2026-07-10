from rest_framework.response import Response
from rest_framework.views import APIView

from system.models import DbVersion


class VersionCheckView(APIView):
    """数据库版本检查 — 无需认证"""
    permission_classes = []

    def get(self, request, db_type):
        try:
            version = DbVersion.objects.get(db_type=db_type)
        except DbVersion.DoesNotExist:
            return Response({
                'code': 0,
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
            'data': {
                'schema_version': version.schema_version,
                'data_version': version.data_version,
                'force_update': version.force_update,
                'message': version.message,
                'download_url': version.download_url,
                'checksum': version.checksum,
                'size_bytes': version.size_bytes,
            },
        })
