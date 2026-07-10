from django.contrib import admin

from .models import InvitationCode, Student, Teacher, UserLoginLog


@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'class_group', 'student_id',
                    'school', 'gaokao_year', 'created_at']
    list_select_related = ['user', 'class_group']
    search_fields = ['user__username', 'student_id', 'school']
    list_filter = ['class_group', 'gaokao_year']


@admin.register(Teacher)
class TeacherAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'created_at']
    list_select_related = ['user']
    search_fields = ['user__username']


@admin.register(InvitationCode)
class InvitationCodeAdmin(admin.ModelAdmin):
    list_display = ['code', 'is_used', 'used_by', 'expires_at', 'created_at']
    list_filter = ['is_used']
    search_fields = ['code']


@admin.register(UserLoginLog)
class UserLoginLogAdmin(admin.ModelAdmin):
    list_display = ['student', 'login_date', 'created_at']
    list_select_related = ['student']
    list_filter = ['login_date']
    date_hierarchy = 'login_date'
