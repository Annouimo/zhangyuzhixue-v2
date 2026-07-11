from django.db import models

from qbank.models import BaseQuestion


class Course(models.Model):
    """课程"""
    name = models.CharField('课程名', max_length=128)
    description = models.TextField('描述', blank=True, default='')

    class Meta:
        verbose_name = '课程'
        verbose_name_plural = '课程'

    def __str__(self):
        return self.name


class ClassGroup(models.Model):
    """班级"""
    name = models.CharField('班级名', max_length=64, unique=True)

    class Meta:
        verbose_name = '班级'
        verbose_name_plural = '班级'

    def __str__(self):
        return self.name


class ClassCourse(models.Model):
    """班级-课程绑定"""
    class_group = models.ForeignKey(
        ClassGroup, on_delete=models.CASCADE,
        related_name='class_courses'
    )
    course = models.ForeignKey(
        Course, on_delete=models.CASCADE,
        related_name='class_courses'
    )
    start_date = models.DateField('开始日期', null=True, blank=True)
    end_date = models.DateField('结束日期', null=True, blank=True)

    class Meta:
        verbose_name = '班级-课程'
        verbose_name_plural = '班级-课程'
        constraints = [
            models.UniqueConstraint(
                fields=['class_group', 'course'],
                name='uq_class_course'
            )
        ]

    def __str__(self):
        return f'{self.class_group.name} - {self.course.name}'


class Document(models.Model):
    """讲义文档"""
    course = models.ForeignKey(
        Course, on_delete=models.CASCADE,
        related_name='documents'
    )
    chapter = models.CharField('讲次标识', max_length=32,
                               help_text='如 "01"、"02"')
    title = models.CharField('标题', max_length=128)
    md_content = models.TextField('Markdown内容（含分隔符）')
    updated_at = models.DateTimeField('更新时间', auto_now=True)

    class Meta:
        verbose_name = '讲义'
        verbose_name_plural = '讲义'

    def __str__(self):
        return f'第{self.chapter}讲 {self.title}'


class Assignment(models.Model):
    """作业"""
    title = models.CharField('标题', max_length=128)
    description = models.TextField('描述', blank=True, default='')
    course = models.ForeignKey(
        Course, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='assignments'
    )
    questions = models.ManyToManyField(
        BaseQuestion, through='AssignmentQuestion',
        related_name='assignments', blank=True
    )
    created_at = models.DateTimeField('创建时间', auto_now_add=True)

    class Meta:
        verbose_name = '作业'
        verbose_name_plural = '作业'

    def __str__(self):
        return self.title


class AssignmentQuestion(models.Model):
    """作业-题目中间表"""
    assignment = models.ForeignKey(
        Assignment, on_delete=models.CASCADE,
        related_name='assignment_questions'
    )
    question = models.ForeignKey(
        BaseQuestion, on_delete=models.CASCADE,
        related_name='assignment_questions'
    )
    sort_order = models.IntegerField('排序')

    class Meta:
        verbose_name = '作业-题目'
        verbose_name_plural = '作业-题目'
        ordering = ['assignment', 'sort_order']
        constraints = [
            models.UniqueConstraint(
                fields=['assignment', 'question'],
                name='uq_assignment_question'
            )
        ]


class ClassCourseAssignment(models.Model):
    """作业发布表"""
    class_course = models.ForeignKey(
        ClassCourse, on_delete=models.CASCADE,
        related_name='assignments'
    )
    assignment = models.ForeignKey(
        Assignment, on_delete=models.CASCADE,
        related_name='class_course_assignments'
    )
    publish_at = models.DateTimeField('发布时间', null=True, blank=True)
    deadline = models.DateField('截止日期', null=True, blank=True)
    is_active = models.BooleanField('是否有效', default=True)

    class Meta:
        verbose_name = '作业发布'
        verbose_name_plural = '作业发布'

    def __str__(self):
        return f'{self.assignment.title} → {self.class_course}'
