from django.contrib import admin

from .models import (
    AchievementDef, Announcement, AppVersion, DbVersion,
    LevelConfig, PointsTransaction, StudentAchievement,
)


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
