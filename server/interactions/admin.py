from django.contrib import admin

from .models import (
    CardFeedback, CustomPaper, CustomPaperQuestion, PaperLike,
    QuestionRating, StepFeedback, StudentSubmission, SubmissionDetail,
)


class SubmissionDetailInline(admin.TabularInline):
    model = SubmissionDetail
    extra = 0
    fields = ['question', 'attempt_number', 'status', 'answer_text', 'is_correct']


@admin.register(StudentSubmission)
class StudentSubmissionAdmin(admin.ModelAdmin):
    list_display = ['id', 'student', 'assignment', 'created_at', 'updated_at']
    list_select_related = ['student', 'assignment']
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


@admin.register(PaperLike)
class PaperLikeAdmin(admin.ModelAdmin):
    list_display = ['id', 'student', 'paper', 'created_at']
    list_select_related = ['student', 'paper']
