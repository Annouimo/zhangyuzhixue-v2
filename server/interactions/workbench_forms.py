from django import forms

from django.forms import inlineformset_factory

from courses.models import (
    Course, Document, Video, VideoCategory, VideoDocumentLink,
)


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


class VideoCategoryWorkbenchForm(forms.ModelForm):
    class Meta:
        model = VideoCategory
        fields = ('name', 'description', 'sort_order')


class VideoWorkbenchForm(forms.ModelForm):
    note = forms.CharField(label='修改说明', max_length=500)

    class Meta:
        model = Video
        fields = (
            'category', 'title', 'description', 'cover_url', 'platform_name',
            'video_url', 'published_at', 'sort_order',
        )
        widgets = {
            'description': forms.Textarea(attrs={'rows': 6}),
            'published_at': forms.DateInput(attrs={'type': 'date'}),
        }

    def validate_for_publish(self):
        required = (
            ('cover_url', '上架前请填写封面地址。'),
            ('platform_name', '上架前请填写发布平台。'),
            ('published_at', '上架前请填写发布日期。'),
        )
        valid = True
        for field, message in required:
            if not self.cleaned_data.get(field):
                self.add_error(field, message)
                valid = False
        return valid


VideoDocumentLinkFormSet = inlineformset_factory(
    Video,
    VideoDocumentLink,
    fields=('document', 'relation_label', 'sort_order'),
    extra=1,
    can_delete=True,
)
