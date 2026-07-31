from django import forms
from django.contrib.auth.password_validation import validate_password

from accounts.models import Student
from accounts.roles import ACCESS_LEVEL_CHOICES


class StudentProfileForm(forms.Form):
    real_name = forms.CharField(label='姓名', max_length=64, required=False)
    phone = forms.RegexField(
        label='手机号', regex=r'^1\d{10}$', max_length=11, required=False,
        error_messages={'invalid': '请输入有效手机号'},
    )
    school = forms.CharField(label='学校', max_length=128, required=False)
    gaokao_year = forms.IntegerField(
        label='高考年份', required=False, min_value=2020, max_value=2100,
    )

    def __init__(self, *args, user, **kwargs):
        self.user = user
        student = getattr(user, 'student', None)
        kwargs.setdefault('initial', {
            'real_name': user.get_full_name(),
            'phone': student.phone if student else '',
            'school': student.school if student else '',
            'gaokao_year': student.gaokao_year if student else None,
        })
        super().__init__(*args, **kwargs)

    def clean_phone(self):
        phone = self.cleaned_data['phone'].strip()
        if phone and Student.objects.filter(phone=phone).exclude(user=self.user).exists():
            raise forms.ValidationError('该手机号已被其他学生使用')
        return phone


class AccessLevelForm(forms.Form):
    access_level = forms.ChoiceField(label='日常权限', choices=ACCESS_LEVEL_CHOICES)

    def __init__(self, *args, user, **kwargs):
        kwargs.setdefault('initial', {'access_level': user.access_level})
        super().__init__(*args, **kwargs)


class PointsAdjustmentForm(forms.Form):
    amount = forms.DecimalField(
        label='调整积分', max_digits=10, decimal_places=1,
        min_value=-100000, max_value=100000,
        help_text='增加填正数，扣除填负数',
    )
    description = forms.CharField(label='调整原因', max_length=255)

    def clean_amount(self):
        amount = self.cleaned_data['amount']
        if amount == 0:
            raise forms.ValidationError('调整积分不能为 0')
        return amount


class PasswordResetForm(forms.Form):
    new_password = forms.CharField(
        label='新密码', strip=False, widget=forms.PasswordInput,
    )
    confirm_password = forms.CharField(
        label='确认新密码', strip=False, widget=forms.PasswordInput,
    )

    def __init__(self, *args, user, **kwargs):
        self.user = user
        super().__init__(*args, **kwargs)

    def clean(self):
        cleaned = super().clean()
        password = cleaned.get('new_password')
        if password:
            validate_password(password, user=self.user)
        if password and password != cleaned.get('confirm_password'):
            self.add_error('confirm_password', '两次输入的密码不一致')
        return cleaned
