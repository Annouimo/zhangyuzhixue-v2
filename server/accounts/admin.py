from django.contrib import admin

from .models import (
    AccountDeletionRequest,
    RegistrationConsent,
    Student,
    UserLoginLog,
)


@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'student_id',
                    'school', 'gaokao_year', 'created_at']
    list_select_related = ['user']
    search_fields = ['user__username', 'student_id', 'school']
    list_filter = ['account_status', 'gaokao_year']


@admin.register(AccountDeletionRequest)
class AccountDeletionRequestAdmin(admin.ModelAdmin):
    list_display = [
        'user', 'status', 'requested_at', 'scheduled_for', 'anonymized_at',
    ]
    list_filter = ['status']
    search_fields = ['user__username']
    readonly_fields = [
        'requested_at', 'scheduled_for', 'cancelled_at', 'anonymized_at',
    ]


@admin.register(RegistrationConsent)
class RegistrationConsentAdmin(admin.ModelAdmin):
    list_display = [
        'user', 'terms_version', 'privacy_version', 'source', 'accepted_at',
    ]
    list_select_related = ['user']
    search_fields = ['user__username']
    readonly_fields = [
        'user', 'terms_version', 'privacy_version', 'source', 'accepted_at',
    ]


@admin.register(UserLoginLog)
class UserLoginLogAdmin(admin.ModelAdmin):
    list_display = ['student', 'login_date', 'created_at']
    list_select_related = ['student']
    list_filter = ['login_date']
    date_hierarchy = 'login_date'
