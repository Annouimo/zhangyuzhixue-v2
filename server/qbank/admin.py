from django.contrib import admin

from .models import (
    BaseQuestion, ChoiceExt, ConceptTag, KnowledgeCard,
    QuestionConceptTag, QuestionKnowledgeCard,
    SolutionMethod, SolutionStep, SubQuestion,
)


class ChoiceExtInline(admin.StackedInline):
    model = ChoiceExt
    can_delete = False
    max_num = 1


class SubQuestionInline(admin.TabularInline):
    model = SubQuestion
    extra = 0
    fields = ['stem', 'answer', 'explanation', 'sort_order']


class QuestionConceptTagInline(admin.TabularInline):
    model = QuestionConceptTag
    extra = 0
    autocomplete_fields = ['concept_tag']


class QuestionKnowledgeCardInline(admin.TabularInline):
    model = QuestionKnowledgeCard
    extra = 0
    autocomplete_fields = ['knowledge_card']


class SolutionStepInline(admin.TabularInline):
    model = SolutionStep
    extra = 0
    fields = ['step_number', 'title', 'content', 'card_titles']


class SolutionMethodInline(admin.TabularInline):
    model = SolutionMethod
    extra = 0
    fields = ['method_name', 'source', 'sort_order']


@admin.register(BaseQuestion)
class BaseQuestionAdmin(admin.ModelAdmin):
    list_display = ['id', 'year', 'region', 'exam_type', 'number',
                    'question_type', 'difficulty', 'calculation']
    list_filter = ['question_type', 'year', 'region', 'exam_type']
    search_fields = ['stem']
    inlines = [
        ChoiceExtInline, SubQuestionInline,
        QuestionConceptTagInline, QuestionKnowledgeCardInline,
    ]
    fieldsets = [
        (None, {
            'fields': ['year', 'exam_type', 'region', 'number',
                       'question_type', 'difficulty', 'calculation']
        }),
        ('内容', {
            'fields': ['stem', 'images', 'default_score']
        }),
    ]


@admin.register(ConceptTag)
class ConceptTagAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'parent']
    search_fields = ['name']


@admin.register(KnowledgeCard)
class KnowledgeCardAdmin(admin.ModelAdmin):
    list_display = ['id', 'title']
    search_fields = ['title', 'content']


@admin.register(SubQuestion)
class SubQuestionAdmin(admin.ModelAdmin):
    list_display = ['id', 'question', 'parent', 'sort_order', 'answer']
    list_select_related = ['question']
    search_fields = ['answer']
    inlines = [SolutionMethodInline]


@admin.register(SolutionMethod)
class SolutionMethodAdmin(admin.ModelAdmin):
    list_display = ['id', 'sub_question', 'method_name', 'source', 'sort_order']
    list_select_related = ['sub_question']


@admin.register(SolutionStep)
class SolutionStepAdmin(admin.ModelAdmin):
    list_display = ['id', 'method', 'step_number', 'title']
    list_select_related = ['method']
    search_fields = ['title', 'content']


@admin.register(QuestionConceptTag)
class QuestionConceptTagAdmin(admin.ModelAdmin):
    list_display = ['id', 'question', 'concept_tag']
    list_select_related = ['question', 'concept_tag']


@admin.register(QuestionKnowledgeCard)
class QuestionKnowledgeCardAdmin(admin.ModelAdmin):
    list_display = ['id', 'question', 'knowledge_card']
    list_select_related = ['question', 'knowledge_card']
