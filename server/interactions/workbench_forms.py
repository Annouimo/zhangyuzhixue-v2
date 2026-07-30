from django import forms

from courses.models import Course, Document


class CourseWorkbenchForm(forms.ModelForm):
    note = forms.CharField(label='修改说明', max_length=500)

    class Meta:
        model = Course
        fields = ('name', 'description')
        widgets = {'description': forms.Textarea(attrs={'rows': 5})}


class DocumentWorkbenchForm(forms.ModelForm):
    note = forms.CharField(label='修改说明', max_length=500)

    class Meta:
        model = Document
        fields = ('course', 'chapter', 'title', 'md_content')
        widgets = {'md_content': forms.Textarea(attrs={'rows': 24})}
