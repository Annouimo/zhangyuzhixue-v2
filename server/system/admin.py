
from django.contrib import admin
from django.contrib.admin.views.decorators import staff_member_required
from django.http import HttpResponseRedirect
from django.shortcuts import render
from django.urls import reverse
from django.utils.decorators import method_decorator
from django.views import View

from django.utils import timezone
from .models import (
    AchievementDef, AdminHelpProxy, Announcement, AppVersion, DbVersion,
    LevelConfig, PointsTransaction, StudentAchievement,
    SystemConfig, SystemToolsProxy,
)


# ── 已有模型注册 ──────────────────────────────────────────────


@admin.register(LevelConfig)
class LevelConfigAdmin(admin.ModelAdmin):
    list_display = ['level', 'min_xp', 'title', 'icon_emoji']
    ordering = ['level']


@admin.register(AchievementDef)
class AchievementDefAdmin(admin.ModelAdmin):
    list_display = ['code', 'name', 'category', 'trigger_type',
                    'threshold', 'display_order']
    list_filter = ['category', 'trigger_type']
    search_fields = ['code', 'name']


@admin.register(StudentAchievement)
class StudentAchievementAdmin(admin.ModelAdmin):
    list_display = ['id', 'student', 'achievement', 'progress',
                    'is_unlocked', 'unlocked_at']
    list_select_related = ['student', 'achievement']
    list_filter = ['is_unlocked']


@admin.register(PointsTransaction)
class PointsTransactionAdmin(admin.ModelAdmin):
    list_display = ['id', 'student', 'amount', 'transaction_type',
                    'source', 'description', 'created_at']
    list_select_related = ['student']
    list_filter = ['transaction_type', 'source', 'created_at']
    date_hierarchy = 'created_at'


@admin.register(DbVersion)
class DbVersionAdmin(admin.ModelAdmin):
    list_display = ['db_type', 'schema_version', 'data_version',
                    'force_update', 'built_at']
    list_filter = ['db_type', 'force_update']


@admin.register(AppVersion)
class AppVersionAdmin(admin.ModelAdmin):
    list_display = ['platform', 'version_name', 'version_code',
                    'force_update', 'created_at']
    list_filter = ['platform', 'force_update']


@admin.register(Announcement)
class AnnouncementAdmin(admin.ModelAdmin):
    list_display = ['title', 'is_active', 'created_at']
    list_filter = ['is_active']
    search_fields = ['title', 'content']


@admin.register(SystemConfig)
class SystemConfigAdmin(admin.ModelAdmin):
    list_display = ['key', 'value', 'description']
    search_fields = ['key']


@admin.register(SystemToolsProxy)
class SystemToolsAdmin(admin.ModelAdmin):
    """系统工具页入口 — 点击跳转到 /admin/system/tools/"""

    def changelist_view(self, request, extra_context=None):
        return HttpResponseRedirect(reverse('admin-system-tools'))

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return request.user.is_staff


@admin.register(AdminHelpProxy)
class AdminHelpAdmin(admin.ModelAdmin):
    """管理员使用说明入口 — 跳转到 /admin/system/help/"""

    def changelist_view(self, request, extra_context=None):
        return HttpResponseRedirect(reverse('admin-system-help'))

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return request.user.is_staff


# ── 工具页面 ──────────────────────────────────────────────────


@method_decorator(staff_member_required, name='dispatch')
class ToolsView(View):
    """系统管理工具页面 — 构建/邀请码/批量导入"""
    template_name = 'admin/system/tools.html'

    def get(self, request):
        ctx = self._get_context(request)
        return render(request, self.template_name, ctx)

    def post(self, request):
        action = request.POST.get('action', '')

        if action == 'build_assets':
            self._run_build('qbank', request.POST.get('mode') == 'test')
        elif action == 'build_lectures':
            self._run_build('lecture', request.POST.get('mode') == 'test')
        elif action == 'generate_codes':
            self._generate_codes(request)

        return HttpResponseRedirect(reverse('admin-system-tools'))

    def _get_context(self, request):
        """准备模板上下文"""
        from accounts.models import InvitationCode
        return {
            'qbank_version': DbVersion.objects.filter(db_type='qbank').first(),
            'lecture_version': DbVersion.objects.filter(db_type='lecture').first(),
            'invitation_codes': InvitationCode.objects.all().order_by('-created_at')[:50],
            'has_error': False,
            'messages': [],
            'now': timezone.now(),
        }

    def _run_build(self, db_type, test_mode):
        """执行构建"""
        import io
        import sys
        from scripts.build_schemas import ASSETS_TABLES, LECTURE_TABLES
        from scripts.build_utils import build_database
        from system.models import DbVersion

        schema = ASSETS_TABLES if db_type == 'qbank' else LECTURE_TABLES

        try:
            ver = DbVersion.objects.get(db_type=db_type)
            version_info = {
                'schema_version': ver.schema_version,
                'data_version': ver.data_version + (0 if test_mode else 1),
            }
        except DbVersion.DoesNotExist:
            version_info = {'schema_version': 1, 'data_version': 1}

        # 捕获 print 输出到日志
        old_stdout = sys.stdout
        sys.stdout = buf = io.StringIO()
        try:
            build_database(
                schema=schema,
                db_type=db_type,
                version_info=version_info,
                test_mode=test_mode,
            )
        except Exception as e:
            buf.write(f'\nERROR: {e}')
        finally:
            sys.stdout = old_stdout
        return buf.getvalue()

    def _generate_codes(self, request):
        """批量生成邀请码"""
        from accounts.models import InvitationCode
        import secrets
        import string

        try:
            count = int(request.POST.get('count', 10))
        except (ValueError, TypeError):
            count = 10
        count = max(1, min(100, count))

        days = request.POST.get('days', '')
        if days:
            try:
                expires = timezone.now() + timezone.timedelta(days=int(days))
            except (ValueError, TypeError):
                expires = None
        else:
            expires = None

        chars = string.ascii_uppercase + string.digits
        created = 0
        for _ in range(count * 2):  # 最多尝试 2 倍次数去重
            if created >= count:
                break
            code = '-'.join([
                ''.join(secrets.choice(chars) for _ in range(4)),
                ''.join(secrets.choice(chars) for _ in range(4)),
                ''.join(secrets.choice(chars) for _ in range(4)),
            ])
            if not InvitationCode.objects.filter(code=code).exists():
                InvitationCode.objects.create(
                    code=code,
                    is_used=False,
                    expires_at=expires,
                )
                created += 1


@method_decorator(staff_member_required, name='dispatch')
class HelpView(View):
    """管理员使用说明页面"""
    template_name = 'admin/system/help.html'

    def get(self, request):
        return render(request, self.template_name)
