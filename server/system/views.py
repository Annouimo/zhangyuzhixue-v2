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