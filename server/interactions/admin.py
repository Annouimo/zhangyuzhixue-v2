from django import forms
from django.contrib import admin
from django.utils import timezone

from .models import (
    CardFeedback, CustomPaper, CustomPaperQuestion, PageSatisfactionFeedback,
    PaperCollect, PaperLike,
    ContentContribution, ContributionReview, ContributionRevision,
    ContributionTagSelection, ContributionTagSuggestion,
    QuestionRating, StepFeedback, StudentSubmission, SubmissionDetail,
)


class ContentContributionAdminForm(forms.ModelForm):
    class Meta:
        model = ContentContribution
        fields = '__all__'

    def clean(self):
        cleaned = super().clean()
        status_value = cleaned.get('status')
        if status_value in {
            ContentContribution.Status.NEEDS_REVISION,
            ContentContribution.Status.REJECTED,
        } and not (cleaned.get('review_note') or '').strip():
            self.add_error('review_note', '打回修改或不采纳时必须填写审核意见。')
        if (
            status_value in {
                ContentContribution.Status.APPROVED_PENDING_RELEASE,
                ContentContribution.Status.COMPLETED,
            }
            and cleaned.get('completed_question') is None
        ):
            self.add_error('completed_question', '标记已完成前必须关联处理后的题目。')
        return cleaned


class ContributionRevisionInline(admin.StackedInline):
    model = ContributionRevision
    extra = 0
    can_delete = False
    fields = [
        'revision_number', 'raw_json', 'normalized_payload',
        'question_snapshot', 'created_at',
    ]
    readonly_fields = fields


class ContributionTagSelectionInline(admin.TabularInline):
    model = ContributionTagSelection
    extra = 0
    autocomplete_fields = ['concept_tag']


class ContributionTagSuggestionInline(admin.TabularInline):
    model = ContributionTagSuggestion
    extra = 0
    fields = [
        'suggested_name', 'suggested_parent', 'reason', 'status',
        'resolved_tag', 'reviewer_note',
    ]
    autocomplete_fields = ['suggested_parent', 'resolved_tag']


class ContributionReviewInline(admin.TabularInline):
    model = ContributionReview
    extra = 0
    can_delete = False
    fields = ['actor', 'action', 'note', 'created_at']
    readonly_fields = fields


@admin.register(ContentContribution)
class ContentContributionAdmin(admin.ModelAdmin):
    form = ContentContributionAdminForm
    list_display = [
        'id', 'contribution_type', 'student', 'question', 'status',
        'revision_count', 'updated_at',
    ]
    list_filter = ['contribution_type', 'status', 'created_at']
    search_fields = [
        'student__user__username', 'question__stem',
        'revisions__normalized_payload',
    ]
    list_select_related = ['student', 'question', 'completed_question']
    autocomplete_fields = ['question', 'completed_question', 'reviewed_by']
    readonly_fields = ['student', 'contribution_type', 'question', 'created_at', 'updated_at']
    inlines = [
        ContributionRevisionInline,
        ContributionTagSelectionInline,
        ContributionTagSuggestionInline,
        ContributionReviewInline,
    ]

    @admin.display(description='修订次数')
    def revision_count(self, obj):
        return obj.revisions.count()

    def save_model(self, request, obj, form, change):
        previous_status = None
        if change:
            previous_status = ContentContribution.objects.filter(
                pk=obj.pk
            ).values_list('status', flat=True).first()
        if previous_status != obj.status:
            obj.reviewed_by = request.user
            obj.reviewed_at = timezone.now()
        super().save_model(request, obj, form, change)
        if previous_status and previous_status != obj.status:
            action_by_status = {
                ContentContribution.Status.NEEDS_REVISION: 'needs_revision',
                ContentContribution.Status.PROCESSING: 'processing',
                ContentContribution.Status.APPROVED_PENDING_RELEASE: 'completed',
                ContentContribution.Status.COMPLETED: 'completed',
                ContentContribution.Status.REJECTED: 'rejected',
            }
            action = action_by_status.get(obj.status)
            if action:
                ContributionReview.objects.create(
                    contribution=obj,
                    actor=request.user,
                    action=action,
                    note=obj.review_note,
                )


@admin.register(ContributionTagSuggestion)
class ContributionTagSuggestionAdmin(admin.ModelAdmin):
    list_display = [
        'id', 'suggested_name', 'suggested_parent', 'contribution',
        'status', 'resolved_tag',
    ]
    list_filter = ['status']
    search_fields = ['suggested_name', 'reason']
    autocomplete_fields = ['suggested_parent', 'resolved_tag']
    actions = ['create_suggested_tags']

    @admin.action(description='创建所选建议为正式标签')
    def create_suggested_tags(self, request, queryset):
        count = 0
        for suggestion in queryset.filter(status='pending'):
            tag = suggestion.resolved_tag
            if tag is None:
                from qbank.models import ConceptTag
                tag, _ = ConceptTag.objects.get_or_create(
                    name=suggestion.suggested_name.strip(),
                    defaults={'parent': suggestion.suggested_parent},
                )
            suggestion.status = 'created'
            suggestion.resolved_tag = tag
            suggestion.save(update_fields=['status', 'resolved_tag'])
            ContributionTagSelection.objects.get_or_create(
                contribution=suggestion.contribution,
                concept_tag=tag,
            )
            count += 1
        self.message_user(request, f'已处理 {count} 条标签建议。')


class SubmissionDetailInline(admin.TabularInline):
    model = SubmissionDetail
    extra = 0
    fields = ['question', 'attempt_number', 'status', 'answer_text', 'is_correct']


@admin.register(StudentSubmission)
class StudentSubmissionAdmin(admin.ModelAdmin):
    list_display = ['id', 'student', 'created_at', 'updated_at']
    list_select_related = ['student']
    list_filter = ['created_at']
    inlines = [SubmissionDetailInline]


@admin.register(SubmissionDetail)
class SubmissionDetailAdmin(admin.ModelAdmin):
    list_display = ['id', 'submission', 'question', 'attempt_number',
                    'status', 'is_correct']
    list_select_related = ['submission', 'question']
    list_filter = ['status', 'is_correct']


class StepFeedbackInline(admin.TabularInline):
    model = StepFeedback
    extra = 0
    fields = ['question', 'step_number', 'status', 'sub_question_index']


@admin.register(StepFeedback)
class StepFeedbackAdmin(admin.ModelAdmin):
    list_display = ['id', 'submission_detail', 'question',
                    'step_number', 'status']
    list_select_related = ['submission_detail', 'question']
    list_filter = ['status']


@admin.register(CardFeedback)
class CardFeedbackAdmin(admin.ModelAdmin):
    list_display = ['id', 'submission_detail', 'card_title', 'card_status']
    list_select_related = ['submission_detail']
    list_filter = ['card_status']


@admin.register(QuestionRating)
class QuestionRatingAdmin(admin.ModelAdmin):
    list_display = ['id', 'student', 'question',
                    'difficulty_score', 'calculation_score', 'elegance_score']
    list_select_related = ['student', 'question']


class CustomPaperQuestionInline(admin.TabularInline):
    model = CustomPaperQuestion
    extra = 0
    fields = ['question', 'sort_order']


@admin.register(CustomPaper)
class CustomPaperAdmin(admin.ModelAdmin):
    list_display = ['id', 'title', 'student', 'is_public',
                    'view_count', 'created_at']
    list_select_related = ['student']
    list_filter = ['is_public', 'created_at']
    search_fields = ['title']
    inlines = [CustomPaperQuestionInline]


@admin.register(CustomPaperQuestion)
class CustomPaperQuestionAdmin(admin.ModelAdmin):
    list_display = ['id', 'paper', 'question', 'sort_order']
    list_select_related = ['paper', 'question']


@admin.register(PaperCollect)
class PaperCollectAdmin(admin.ModelAdmin):
    list_display = ['id', 'student', 'paper', 'created_at']
    list_select_related = ['student', 'paper']


@admin.register(PaperLike)
class PaperLikeAdmin(admin.ModelAdmin):
    list_display = ['id', 'student', 'paper', 'created_at']
    list_select_related = ['student', 'paper']


@admin.register(PageSatisfactionFeedback)
class PageSatisfactionFeedbackAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'rating', 'page_url', 'created_at']
    list_select_related = ['user']
    list_filter = ['rating', 'created_at']
    date_hierarchy = 'created_at'
