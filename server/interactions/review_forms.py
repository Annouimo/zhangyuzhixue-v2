import json

from django import forms
from django.contrib.auth.forms import AuthenticationForm

from accounts.roles import is_content_reviewer
from qbank.models import ConceptTag, KnowledgeCard

from .serializers import validate_question_payload, validate_solution_payload


class ReviewerAuthenticationForm(AuthenticationForm):
    error_messages = {
        **AuthenticationForm.error_messages,
        'invalid_login': '账号、密码或审核权限不正确。',
    }

    def confirm_login_allowed(self, user):
        super().confirm_login_allowed(user)
        if not is_content_reviewer(user):
            raise forms.ValidationError(
                self.error_messages['invalid_login'], code='invalid_login'
            )


class ContributionReviewForm(forms.Form):
    content_json = forms.CharField(widget=forms.Textarea(attrs={'rows': 24}))
    tags = forms.ModelMultipleChoiceField(
        queryset=ConceptTag.objects.none(), required=False,
        widget=forms.CheckboxSelectMultiple,
    )
    note = forms.CharField(
        required=False, max_length=2000,
        widget=forms.Textarea(attrs={'rows': 3}),
    )
    version = forms.CharField(widget=forms.HiddenInput)

    def __init__(self, *args, **kwargs):
        self.contribution_type = kwargs.pop('contribution_type', 'new_question')
        super().__init__(*args, **kwargs)
        self.fields['tags'].queryset = ConceptTag.objects.order_by('parent_id', 'name')

    def clean_content_json(self):
        value = self.cleaned_data['content_json']
        try:
            payload = json.loads(value)
        except json.JSONDecodeError as exc:
            raise forms.ValidationError(
                f'JSON 格式错误：第 {exc.lineno} 行第 {exc.colno} 列'
            ) from exc
        try:
            if self.contribution_type == 'new_solution':
                validate_solution_payload(payload)
            else:
                validate_question_payload(payload)
        except Exception as exc:
            detail = getattr(exc, 'detail', exc)
            raise forms.ValidationError(str(detail)) from exc
        return payload


class QuestionWorkbenchForm(ContributionReviewForm):
    knowledge_cards = forms.ModelMultipleChoiceField(
        queryset=KnowledgeCard.objects.none(), required=False,
        widget=forms.SelectMultiple(attrs={'size': 8}),
    )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, contribution_type='new_question', **kwargs)
        self.fields['knowledge_cards'].queryset = KnowledgeCard.objects.order_by(
            'category', 'title'
        )
        self.fields['note'].required = True
        self.fields['note'].label = '修改说明'

    def clean(self):
        cleaned = super().clean()
        if not cleaned.get('tags'):
            self.add_error('tags', '正式题目至少需要一个概念标签。')
        return cleaned


class ConceptTagWorkbenchForm(forms.ModelForm):
    note = forms.CharField(label='修改说明', max_length=500)

    class Meta:
        model = ConceptTag
        fields = ['name', 'parent']

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        queryset = ConceptTag.objects.order_by('parent_id', 'name')
        if self.instance.pk:
            descendants = {self.instance.pk}
            frontier = {self.instance.pk}
            while frontier:
                frontier = set(
                    ConceptTag.objects.filter(parent_id__in=frontier)
                    .values_list('pk', flat=True)
                ) - descendants
                descendants.update(frontier)
            queryset = queryset.exclude(pk__in=descendants)
        self.fields['parent'].queryset = queryset


class KnowledgeCardWorkbenchForm(forms.ModelForm):
    note = forms.CharField(label='修改说明', max_length=500)

    class Meta:
        model = KnowledgeCard
        fields = ['title', 'category', 'content']
        widgets = {'content': forms.Textarea(attrs={'rows': 14})}
