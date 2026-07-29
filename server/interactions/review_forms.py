import json

from django import forms
from django.contrib.auth.forms import AuthenticationForm

from accounts.roles import is_content_reviewer
from qbank.models import ConceptTag

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
