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
