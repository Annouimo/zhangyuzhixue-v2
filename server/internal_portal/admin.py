from django.contrib import admin

from .models import (
    BusinessArea,
    HandbookSection,
    PortalEntry,
    ProjectProfile,
    TeamMember,
)


@admin.register(ProjectProfile)
class ProjectProfileAdmin(admin.ModelAdmin):
    fieldsets = (
        (None, {'fields': ('title', 'positioning')}),
        ('当前情况', {'fields': ('current_phase', 'current_focus')}),
    )

    def has_add_permission(self, request):
        return not ProjectProfile.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(TeamMember)
class TeamMemberAdmin(admin.ModelAdmin):
    list_display = ('name', 'responsibility', 'is_active', 'sort_order', 'updated_at')
    list_editable = ('is_active', 'sort_order')
    search_fields = ('name', 'responsibility')


@admin.register(BusinessArea)
class BusinessAreaAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug', 'status', 'is_visible', 'sort_order', 'updated_at')
    list_editable = ('status', 'is_visible', 'sort_order')
    filter_horizontal = ('owners',)
    search_fields = ('name', 'summary')


@admin.register(HandbookSection)
class HandbookSectionAdmin(admin.ModelAdmin):
    list_display = ('title', 'page', 'is_visible', 'sort_order', 'updated_at')
    list_editable = ('is_visible', 'sort_order')
    list_filter = ('page', 'is_visible')
    search_fields = ('title', 'body')


@admin.register(PortalEntry)
class PortalEntryAdmin(admin.ModelAdmin):
    list_display = (
        'name', 'area', 'section', 'entry_type', 'status', 'is_visible',
        'sort_order', 'updated_at',
    )
    list_editable = ('status', 'is_visible', 'sort_order')
    list_filter = ('area', 'section', 'entry_type', 'status', 'is_visible')
    filter_horizontal = ('owners',)
    search_fields = ('name', 'description', 'url')
