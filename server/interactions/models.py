from django.db import models

from accounts.models import Student
from qbank.models import BaseQuestion


class StudentSubmission(models.Model):
    """提交头 - 一次做题过程"""
    student = models.ForeignKey(
        Student, on_delete=models.CASCADE,
        related_name='submissions'
    )
    assignment = models.ForeignKey(
        'courses.Assignment', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='submissions'
    )
    created_at = models.DateTimeField('创建时间', auto_now_add=True)
    updated_at = models.DateTimeField('更新时间', auto_now=True)

    class Meta:
        verbose_name = '提交头'
        verbose_name_plural = '提交头'

    def __str__(self):
        return f'提交 {self.id} ({self.student})'


class SubmissionDetail(models.Model):
    """提交明细 - 一道题的一次作答"""
    STATUS_CHOICES = [
        ('in_progress', '进行中'),
        ('completed', '已完成'),
    ]

    submission = models.ForeignKey(
        StudentSubmission, on_delete=models.CASCADE,
        null=True, blank=True, related_name='details'
    )
    question = models.ForeignKey(
        BaseQuestion, on_delete=models.CASCADE,
        related_name='submission_details'
    )
    attempt_number = models.IntegerField('第几次作答', default=1)
    status = models.CharField('状态', max_length=16,
                              choices=STATUS_CHOICES, default='in_progress')
    answer_text = models.TextField('学生答案', blank=True, default='')
    is_correct = models.BooleanField('是否正确', null=True, blank=True)
    created_at = models.DateTimeField('创建时间', auto_now_add=True)
    updated_at = models.DateTimeField('更新时间', auto_now=True)

    class Meta:
        verbose_name = '提交明细'
        verbose_name_plural = '提交明细'

    def __str__(self):
        return f'detail {self.id} (题 {self.question_id})'


class StepFeedback(models.Model):
    """步骤反馈"""
    STATUS_CHOICES = [
        ('full_correct', '全对'),
        ('partial_correct', '过程对计算错'),
        ('wrong', '不会'),
    ]

    submission_detail = models.ForeignKey(
        SubmissionDetail, on_delete=models.CASCADE,
        related_name='step_feedbacks'
    )
    question = models.ForeignKey(
        BaseQuestion, on_delete=models.CASCADE,
        related_name='step_feedbacks'
    )
    sub_question_index = models.IntegerField('小题索引', default=0)
    method_id = models.IntegerField('解法ID', null=True, blank=True)
    step_number = models.IntegerField('步骤编号')
    status = models.CharField('状态', max_length=32, choices=STATUS_CHOICES)
    created_at = models.DateTimeField('创建时间', auto_now_add=True)

    class Meta:
        verbose_name = '步骤反馈'
        verbose_name_plural = '步骤反馈'

    def __str__(self):
        return f'步骤 {self.step_number}: {self.get_status_display()}'


class CardFeedback(models.Model):
    """卡片反馈"""
    CARD_STATUS_CHOICES = [
        ('mastered', '完全掌握'),
        ('understood', '了解'),
        ('not_understood', '不了解'),
    ]

    submission_detail = models.ForeignKey(
        SubmissionDetail, on_delete=models.CASCADE,
        related_name='card_feedbacks'
    )
    question = models.ForeignKey(
        BaseQuestion, on_delete=models.CASCADE,
        related_name='card_feedbacks'
    )
    card_title = models.CharField('卡片标题', max_length=128)
    card_status = models.CharField('掌握程度', max_length=32,
                                   choices=CARD_STATUS_CHOICES)
    created_at = models.DateTimeField('创建时间', auto_now_add=True)

    class Meta:
        verbose_name = '卡片反馈'
        verbose_name_plural = '卡片反馈'

    def __str__(self):
        return f'{self.card_title}: {self.get_card_status_display()}'


class QuestionRating(models.Model):
    """题目评分 - 每人每题一条"""
    student = models.ForeignKey(
        Student, on_delete=models.CASCADE,
        related_name='ratings'
    )
    question = models.ForeignKey(
        BaseQuestion, on_delete=models.CASCADE,
        related_name='ratings'
    )
    difficulty_score = models.IntegerField('困难度评分')
    calculation_score = models.IntegerField('计算量评分')
    elegance_score = models.IntegerField('优美度评分')
    created_at = models.DateTimeField('创建时间', auto_now_add=True)

    class Meta:
        verbose_name = '题目评分'
        verbose_name_plural = '题目评分'
        constraints = [
            models.UniqueConstraint(
                fields=['student', 'question'],
                name='uq_student_question_rating'
            )
        ]

    def __str__(self):
        return f'评分 {self.student_id} → 题 {self.question_id}'


class CustomPaper(models.Model):
    """个性化组卷"""
    student = models.ForeignKey(
        Student, on_delete=models.CASCADE,
        related_name='custom_papers'
    )
    title = models.CharField('标题', max_length=128)
    description = models.TextField('描述', blank=True, default='')
    filter_snapshot = models.JSONField('筛选条件快照', blank=True, default=dict)
    is_public = models.BooleanField('是否公开', default=False)
    view_count = models.IntegerField('浏览数', default=0)
    created_at = models.DateTimeField('创建时间', auto_now_add=True)
    updated_at = models.DateTimeField('更新时间', auto_now=True)

    # 题目多对多通过中间表
    questions = models.ManyToManyField(
        BaseQuestion, through='CustomPaperQuestion',
        related_name='custom_papers', blank=True
    )

    class Meta:
        verbose_name = '组卷'
        verbose_name_plural = '组卷'

    def __str__(self):
        return self.title


class CustomPaperQuestion(models.Model):
    """组卷-题目中间表"""
    paper = models.ForeignKey(
        CustomPaper, on_delete=models.CASCADE,
        related_name='paper_questions'
    )
    question = models.ForeignKey(
        BaseQuestion, on_delete=models.CASCADE,
        related_name='paper_questions'
    )
    sort_order = models.IntegerField('排序')

    class Meta:
        verbose_name = '组卷-题目'
        verbose_name_plural = '组卷-题目'
        ordering = ['paper', 'sort_order']
        constraints = [
            models.UniqueConstraint(
                fields=['paper', 'question'],
                name='uq_paper_question'
            )
        ]


class PaperLike(models.Model):
    """组卷点赞"""
    student = models.ForeignKey(
        Student, on_delete=models.CASCADE,
        related_name='paper_likes'
    )
    paper = models.ForeignKey(
        CustomPaper, on_delete=models.CASCADE,
        related_name='likes'
    )
    created_at = models.DateTimeField('创建时间', auto_now_add=True)

    class Meta:
        verbose_name = '组卷点赞'
        verbose_name_plural = '组卷点赞'
        constraints = [
            models.UniqueConstraint(
                fields=['student', 'paper'],
                name='uq_student_paper_like'
            )
        ]

    def __str__(self):
        return f'{self.student_id} 赞 组卷 {self.paper_id}'


class PaperCollect(models.Model):
    """组卷收藏"""
    student = models.ForeignKey(
        Student, on_delete=models.CASCADE,
        related_name='paper_collects'
    )
    paper = models.ForeignKey(
        CustomPaper, on_delete=models.CASCADE,
        related_name='collects'
    )
    created_at = models.DateTimeField('收藏时间', auto_now_add=True)

    class Meta:
        verbose_name = '组卷收藏'
        verbose_name_plural = '组卷收藏'
        constraints = [
            models.UniqueConstraint(
                fields=['student', 'paper'],
                name='uq_student_paper_collect'
            )
        ]

    def __str__(self):
        return f'{self.student_id} 收藏 组卷 {self.paper_id}'
