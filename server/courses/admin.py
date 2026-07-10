from django.contrib import admin

from .models import (
    Assignment, AssignmentQuestion, ClassCourse, ClassCourseAssignment,
    ClassGroup, Course, Document,
)


class AssignmentQuestionInline(admin.TabularInline):
    model = AssignmentQuestion
    extra = 0
    autocomplete_fields = ['question']


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ['id', 'name']
    search_fields = ['name']


@admin.register(ClassGroup)
class ClassGroupAdmin(admin.ModelAdmin):
    list_display = ['id', 'name']
    search_fields = ['name']


@admin.register(ClassCourse)
class ClassCourseAdmin(admin.ModelAdmin):
    list_display = ['id', 'class_group', 'course', 'start_date', 'end_date']
    list_select_related = ['class_group', 'course']
    list_filter = ['start_date']


@admin.register(Document)
class DocumentAdmin(admin.ModelAdmin):
    list_display = ['id', 'course', 'chapter', 'title', 'updated_at']
    list_select_related = ['course']
    search_fields = ['title']


@admin.register(Assignment)
class AssignmentAdmin(admin.ModelAdmin):
    list_display = ['id', 'title', 'course', 'created_at']
    list_select_related = ['course']
    search_fields = ['title']
    inlines = [AssignmentQuestionInline]


@admin.register(AssignmentQuestion)
class AssignmentQuestionAdmin(admin.ModelAdmin):
    list_display = ['id', 'assignment', 'question', 'sort_order']
    list_select_related = ['assignment', 'question']


@admin.register(ClassCourseAssignment)
class ClassCourseAssignmentAdmin(admin.ModelAdmin):
    list_display = ['id', 'class_course', 'assignment',
                    'publish_at', 'deadline', 'is_active']
    list_select_related = ['class_course', 'assignment']
    list_filter = ['is_active', 'deadline']
