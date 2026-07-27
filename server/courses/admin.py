from django.contrib import admin

from .models import Course, Document


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ['id', 'name']
    search_fields = ['name']


@admin.register(Document)
class DocumentAdmin(admin.ModelAdmin):
    list_display = ['id', 'course', 'chapter', 'title', 'updated_at']
    list_select_related = ['course']
    search_fields = ['title']
