from django.contrib.auth.models import User
from django.db import models

from accounts.utils import encode_lcg, get_student_id_template


class Teacher(models.Model):
    """教师 - OneToOne 关联 Django User"""
    user = models.OneToOneField(User, on_delete=models.CASCADE,
                                related_name='teacher')
    name = models.CharField('显示名称', max_length=128, default='',
                            blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = '教师'
        verbose_name_plural = '教师'

    def __str__(self):
        return f'教师: {self.name or self.user.username}'


class Student(models.Model):
    """学生 - OneToOne 关联 Django User"""
    class AccountStatus(models.TextChoices):
        ACTIVE = 'active', '正常'
        PENDING_DELETION = 'pending_deletion', '待注销'
        ANONYMIZED = 'anonymized', '已匿名化'

    user = models.OneToOneField(User, on_delete=models.CASCADE,
                                related_name='student')
    class_group = models.ForeignKey(
        'courses.ClassGroup', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='students'
    )
    student_id = models.CharField(
        '学号', max_length=64,
        unique=True,             # 不允许重复
        blank=True, default=''
    )
    school = models.CharField('学校', max_length=128, blank=True, default='')
    phone = models.CharField('手机号', max_length=20, blank=True, default='')
    gaokao_year = models.IntegerField('高考年份', null=True, blank=True)
    avatar = models.URLField('头像URL', max_length=512, blank=True, default='')
    data_version = models.IntegerField('数据版本', default=0)
    account_status = models.CharField(
        '账号状态', max_length=24,
        choices=AccountStatus.choices,
        default=AccountStatus.ACTIVE,
        db_index=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = '学生'
        verbose_name_plural = '学生'

    def __str__(self):
        return f'学生: {self.user.username}'

    def save(self, *args, **kwargs):
        """首次创建且 student_id 为空时自动生成"""
        is_new = self.pk is None
        super().save(*args, **kwargs)
        if is_new and not self.student_id:
            lcg = encode_lcg(self.pk)
            template = get_student_id_template()
            self.student_id = template.replace('{lcg}', lcg)
            Student.objects.filter(pk=self.pk).update(
                student_id=self.student_id
            )


class InvitationCode(models.Model):
    """邀请码"""
    code = models.CharField('邀请码', max_length=32, unique=True)
    is_used = models.BooleanField('已使用', default=False)
    used_by = models.ForeignKey(User, on_delete=models.SET_NULL,
                                null=True, blank=True,
                                related_name='used_invitations')
    used_at = models.DateTimeField('使用时间', null=True, blank=True)
    expires_at = models.DateTimeField('过期时间', null=True, blank=True)
    created_at = models.DateTimeField('创建时间', auto_now_add=True)

    class Meta:
        verbose_name = '邀请码'
        verbose_name_plural = '邀请码'

    def __str__(self):
        return self.code


class AccountDeletionRequest(models.Model):
    """账号注销申请：先禁用，冷静期结束后匿名化。"""

    class Status(models.TextChoices):
        PENDING = 'pending', '冷静期内'
        CANCELLED = 'cancelled', '已撤销'
        ANONYMIZED = 'anonymized', '已匿名化'

    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name='deletion_request',
    )
    previous_class_group = models.ForeignKey(
        'courses.ClassGroup', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='+',
    )
    status = models.CharField(
        '状态', max_length=16,
        choices=Status.choices,
        default=Status.PENDING,
        db_index=True,
    )
    requested_at = models.DateTimeField('申请时间')
    scheduled_for = models.DateTimeField('计划匿名化时间', db_index=True)
    cancelled_at = models.DateTimeField('撤销时间', null=True, blank=True)
    anonymized_at = models.DateTimeField('匿名化时间', null=True, blank=True)

    class Meta:
        verbose_name = '账号注销申请'
        verbose_name_plural = '账号注销申请'

    def __str__(self):
        return f'{self.user_id}: {self.status}'


class RegistrationConsent(models.Model):
    """注册时形成的协议与隐私政策同意记录。"""

    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='registration_consents',
    )
    terms_version = models.CharField('用户协议版本', max_length=32)
    privacy_version = models.CharField('隐私政策版本', max_length=32)
    source = models.CharField('来源', max_length=32, default='student_app')
    accepted_at = models.DateTimeField('同意时间', auto_now_add=True)

    class Meta:
        verbose_name = '注册协议同意记录'
        verbose_name_plural = '注册协议同意记录'
        ordering = ['-accepted_at']

    def __str__(self):
        return f'{self.user_id}: {self.terms_version}/{self.privacy_version}'


class UserLoginLog(models.Model):
    """登录轨迹 - 每天一条"""
    student = models.ForeignKey(Student, on_delete=models.CASCADE,
                                related_name='login_logs')
    login_date = models.DateField('登录日期')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = '登录轨迹'
        verbose_name_plural = '登录轨迹'
        constraints = [
            models.UniqueConstraint(
                fields=['student', 'login_date'],
                name='uq_student_login_date'
            )
        ]

    def __str__(self):
        return f'{self.student.user.username} - {self.login_date}'
