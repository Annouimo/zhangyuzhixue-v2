from django.db import models

from django.contrib.auth.models import User
from accounts.models import Student
from qbank.models import BaseQuestion, ConceptTag


class StudentSubmission(models.Model):
    """提交头 - 一次做题过程"""
    student = models.ForeignKey(
        Student, on_delete=models.CASCADE,
        related_name='submissions'
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


class PaperFolder(models.Model):
    """可持续编辑的试题篮。正式试卷仍是不可变快照。"""
    student = models.ForeignKey(
        Student, on_delete=models.CASCADE, related_name='paper_folders'
    )
    name = models.CharField('名称', max_length=128)
    revision = models.PositiveIntegerField('版本号', default=0)
    is_default = models.BooleanField('默认试题篮', default=False)
    client_updated_at = models.DateTimeField('客户端更新时间')
    last_generated_at = models.DateTimeField(
        '最近生成时间', null=True, blank=True
    )
    last_generated_fingerprint = models.CharField(
        '最近生成内容指纹', max_length=64, blank=True, default=''
    )
    last_generated_paper = models.ForeignKey(
        CustomPaper, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='source_folders'
    )
    created_at = models.DateTimeField('创建时间', auto_now_add=True)
    updated_at = models.DateTimeField('更新时间', auto_now=True)

    questions = models.ManyToManyField(
        BaseQuestion, through='PaperFolderQuestion',
        related_name='paper_folders', blank=True
    )

    class Meta:
        verbose_name = '试题篮'
        verbose_name_plural = '试题篮'
        ordering = ['-updated_at', '-id']

    def __str__(self):
        return f'{self.student_id} - {self.name}'


class PaperFolderQuestion(models.Model):
    """试题篮中的有序题目。"""
    folder = models.ForeignKey(
        PaperFolder, on_delete=models.CASCADE, related_name='folder_questions'
    )
    question = models.ForeignKey(
        BaseQuestion, on_delete=models.CASCADE,
        related_name='paper_folder_questions'
    )
    sort_order = models.IntegerField('排序')
    created_at = models.DateTimeField('加入时间', auto_now_add=True)

    class Meta:
        verbose_name = '试题篮题目'
        verbose_name_plural = '试题篮题目'
        ordering = ['folder', 'sort_order']
        constraints = [
            models.UniqueConstraint(
                fields=['folder', 'question'],
                name='uq_paper_folder_question'
            )
        ]


class SyncIdentity(models.Model):
    """Maps stable client UUIDs to server objects without changing them."""
    student = models.ForeignKey(
        Student, on_delete=models.CASCADE, related_name='sync_identities'
    )
    entity_type = models.CharField('实体类型', max_length=32)
    client_id = models.CharField('客户端唯一标识', max_length=128)
    object_id = models.PositiveBigIntegerField('服务端对象 ID')
    created_at = models.DateTimeField('创建时间', auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=['student', 'entity_type', 'client_id'],
                name='uq_sync_identity_client'
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


class PageSatisfactionFeedback(models.Model):
    """退出评价反馈 — 通过 sync push (exitRating) 接收"""
    user = models.ForeignKey(
        User, on_delete=models.CASCADE,
        related_name='satisfaction_feedbacks'
    )
    page_url = models.CharField('页面URL', max_length=500, blank=True, default='')
    rating = models.IntegerField('评分(1-5)')
    comment = models.TextField('评价内容', blank=True, default='')
    device_type = models.CharField('设备类型', max_length=32, null=True, blank=True)
    created_at = models.DateTimeField('创建时间', auto_now_add=True)

    class Meta:
        verbose_name = '退出评价反馈'
        verbose_name_plural = '退出评价反馈'
        ordering = ['-created_at']

    def __str__(self):
        return f'评价 {self.rating}/5 ({self.user.username})'


class PreferenceFilter(models.Model):
    """筛选预设 — 通过同步队列从客户端接收"""
    student = models.ForeignKey(
        Student, on_delete=models.CASCADE,
        related_name='preference_filters'
    )
    client_id = models.IntegerField('客户端本地ID', null=True, blank=True)
    name = models.CharField('预设名称', max_length=128)
    keyword = models.CharField('搜索词', max_length=256, blank=True, default='')
    years = models.TextField('年份(JSON list)', blank=True, default='')
    regions = models.TextField('地区(JSON list)', blank=True, default='')
    concept_tags = models.TextField('概念标签(JSON list)', blank=True, default='')
    types = models.TextField('考试类型(JSON list)', blank=True, default='')
    knowledge_cards = models.TextField('知识卡片(JSON list)', blank=True, default='')
    question_types = models.TextField('题型(JSON list)', blank=True, default='')
    diff_min = models.FloatField('难度下限', null=True, blank=True)
    diff_max = models.FloatField('难度上限', null=True, blank=True)
    calc_min = models.FloatField('计算量下限', null=True, blank=True)
    calc_max = models.FloatField('计算量上限', null=True, blank=True)
    created_at = models.DateTimeField('创建时间', auto_now_add=True)
    updated_at = models.DateTimeField('更新时间', auto_now=True)

    class Meta:
        verbose_name = '筛选预设'
        verbose_name_plural = '筛选预设'
        unique_together = [('student', 'client_id')]

    def __str__(self):
        return f'{self.name} ({self.student})'


class ContentContribution(models.Model):
    """Student-authored question submission or correction report."""

    class ContributionType(models.TextChoices):
        NEW_QUESTION = 'new_question', '新题投稿'
        NEW_SOLUTION = 'new_solution', '解法投稿'
        QUESTION_CORRECTION = 'question_correction', '题目纠错'

    class ContentOrigin(models.TextChoices):
        EXTERNAL = 'external', '外部'
        ORIGINAL = 'original', '原创'

    class Status(models.TextChoices):
        PENDING = 'pending', '待首次审核'
        RESUBMITTED = 'resubmitted', '修改后待复审'
        NEEDS_REVISION = 'needs_revision', '待修改'
        PROCESSING = 'processing', '处理中'
        APPROVED_PENDING_RELEASE = 'approved_pending_release', '已通过，待题库发布'
        COMPLETED = 'completed', '已发布'
        REJECTED = 'rejected', '未采纳'
        WITHDRAWN = 'withdrawn', '已撤回'

    student = models.ForeignKey(
        Student, on_delete=models.CASCADE, related_name='content_contributions'
    )
    contribution_type = models.CharField(
        '贡献类型', max_length=32, choices=ContributionType.choices
    )
    content_origin = models.CharField(
        '来源性质', max_length=16, choices=ContentOrigin.choices,
        null=True, blank=True,
    )
    question = models.ForeignKey(
        BaseQuestion, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='correction_contributions', verbose_name='纠错题目',
    )
    target_sub_question = models.ForeignKey(
        'qbank.SubQuestion', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='solution_contributions', verbose_name='目标小题',
    )
    completed_question = models.ForeignKey(
        BaseQuestion, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='completed_contributions', verbose_name='处理后题目',
    )
    completed_solution_method = models.ForeignKey(
        'qbank.SolutionMethod', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='source_contributions', verbose_name='处理后解法',
    )
    status = models.CharField(
        '状态', max_length=24, choices=Status.choices,
        default=Status.PENDING, db_index=True,
    )
    review_note = models.TextField('当前审核意见', blank=True, default='')
    reviewed_by = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='reviewed_content_contributions', verbose_name='审核人',
    )
    reviewed_at = models.DateTimeField('审核时间', null=True, blank=True)
    published_qbank_version = models.PositiveIntegerField(
        '发布题库版本', null=True, blank=True
    )
    created_at = models.DateTimeField('创建时间', auto_now_add=True)
    updated_at = models.DateTimeField('更新时间', auto_now=True)

    class Meta:
        verbose_name = '内容贡献'
        verbose_name_plural = '内容贡献审核'
        ordering = ['-updated_at']
        permissions = [
            ('access_review_workbench', '可访问内容审核工作台'),
            ('publish_content_contribution', '可将投稿录入正式题库'),
        ]

    def __str__(self):
        return f'{self.get_contribution_type_display()} #{self.pk}'


class ContributionRevision(models.Model):
    """Immutable payload snapshot for each submission/resubmission."""

    contribution = models.ForeignKey(
        ContentContribution, on_delete=models.CASCADE, related_name='revisions'
    )
    revision_number = models.PositiveIntegerField('修订版本')
    raw_json = models.TextField('原始 JSON', blank=True, default='')
    normalized_payload = models.JSONField('规范化内容', default=dict)
    question_snapshot = models.JSONField('原题快照', default=dict, blank=True)
    created_at = models.DateTimeField('创建时间', auto_now_add=True)

    class Meta:
        verbose_name = '贡献修订'
        verbose_name_plural = '贡献修订'
        ordering = ['contribution', '-revision_number']
        constraints = [
            models.UniqueConstraint(
                fields=['contribution', 'revision_number'],
                name='uq_contribution_revision_number',
            )
        ]

    def __str__(self):
        return f'{self.contribution_id} v{self.revision_number}'


class ContributionTagSelection(models.Model):
    contribution = models.ForeignKey(
        ContentContribution, on_delete=models.CASCADE,
        related_name='tag_selections',
    )
    concept_tag = models.ForeignKey(
        ConceptTag, on_delete=models.CASCADE,
        related_name='contribution_selections',
    )

    class Meta:
        verbose_name = '贡献标签'
        verbose_name_plural = '贡献标签'
        constraints = [
            models.UniqueConstraint(
                fields=['contribution', 'concept_tag'],
                name='uq_contribution_concept_tag',
            )
        ]


class ContributionTagSuggestion(models.Model):
    class Status(models.TextChoices):
        PENDING = 'pending', '待审核'
        CREATED = 'created', '已创建'
        MERGED = 'merged', '已合并'
        REJECTED = 'rejected', '未采纳'

    contribution = models.ForeignKey(
        ContentContribution, on_delete=models.CASCADE,
        related_name='tag_suggestions',
    )
    suggested_name = models.CharField('建议名称', max_length=64)
    suggested_parent = models.ForeignKey(
        ConceptTag, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='child_tag_suggestions', verbose_name='建议上级标签',
    )
    reason = models.CharField('建议理由', max_length=500, blank=True, default='')
    status = models.CharField(
        '状态', max_length=16, choices=Status.choices,
        default=Status.PENDING,
    )
    resolved_tag = models.ForeignKey(
        ConceptTag, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='resolved_tag_suggestions', verbose_name='处理后标签',
    )
    reviewer_note = models.CharField(
        '审核说明', max_length=500, blank=True, default=''
    )

    class Meta:
        verbose_name = '新标签建议'
        verbose_name_plural = '新标签建议'


class ContributionReview(models.Model):
    class Action(models.TextChoices):
        SUBMITTED = 'submitted', '已提交'
        RESUBMITTED = 'resubmitted', '重新提交'
        NEEDS_REVISION = 'needs_revision', '打回修改'
        PROCESSING = 'processing', '进入处理'
        COMPLETED = 'completed', '处理完成'
        PUBLISHED = 'published', '已发布到题库'
        PUBLICATION_ROLLED_BACK = 'publication_rolled_back', '题库发布已回滚'
        REJECTED = 'rejected', '未采纳'
        WITHDRAWN = 'withdrawn', '已撤回'

    contribution = models.ForeignKey(
        ContentContribution, on_delete=models.CASCADE, related_name='reviews'
    )
    actor = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='content_contribution_actions',
    )
    action = models.CharField('操作', max_length=24, choices=Action.choices)
    note = models.TextField('说明', blank=True, default='')
    created_at = models.DateTimeField('操作时间', auto_now_add=True)

    class Meta:
        verbose_name = '贡献审核记录'
        verbose_name_plural = '贡献审核记录'
        ordering = ['created_at']
