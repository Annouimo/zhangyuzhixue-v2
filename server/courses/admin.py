from django.contrib import admin

from .models import (
    Course, Document, Video, VideoCategory, VideoDocumentLink,
)


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ['id', 'name']
    search_fields = ['name']


@admin.register(Document)
class DocumentAdmin(admin.ModelAdmin):
    list_display = ['id', 'course', 'chapter', 'title', 'updated_at']
    list_select_related = ['course']
    search_fields = ['title']


class VideoDocumentLinkInline(admin.TabularInline):
    model = VideoDocumentLink
    extra = 0
    autocomplete_fields = ['document']
    fields = ['document', 'relation_label', 'sort_order']


@admin.register(VideoCategory)
class VideoCategoryAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'sort_order']
    list_editable = ['sort_order']
    search_fields = ['name']


@admin.register(Video)
class VideoAdmin(admin.ModelAdmin):
    list_display = [
        'id', 'title', 'category', 'platform_name', 'published_at',
        'sort_order', 'is_published',
    ]
    list_filter = ['category', 'is_published', 'platform_name']
    list_editable = ['sort_order', 'is_published']
    search_fields = ['title', 'description']
    autocomplete_fields = ['category']
    inlines = [VideoDocumentLinkInline]
