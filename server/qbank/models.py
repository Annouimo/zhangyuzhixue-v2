from django.db import models


from accounts.models import Student
from django.contrib.auth.models import User


class ContentOrigin(models.TextChoices):
    EXTERNAL = 'external', '外部'
    ORIGINAL = 'original', '原创'


class ConceptTag(models.Model):
    """概念标签 - 树形结构"""
    name = models.CharField('标签名', max_length=64, unique=True)
    parent = models.ForeignKey(
        'self', on_delete=models.CASCADE, null=True, blank=True,
        related_name='children'
    )

    class Meta:
        verbose_name = '概念标签'
        verbose_name_plural = '概念标签'

    def __str__(self):
        return self.name


class KnowledgeCard(models.Model):
    """知识卡片"""
    CATEGORY_CHOICES = [
        ('流程', '流程'),
        ('定理', '定理'),
    ]
    title = models.CharField('标题', max_length=128)
    category = models.CharField('分类', max_length=16, choices=CATEGORY_CHOICES)
    content = models.TextField('内容')

    class Meta:
        verbose_name = '知识卡片'
        verbose_name_plural = '知识卡片'

    def __str__(self):
        return self.title


class BaseQuestion(models.Model):
    """题目主表"""
    QUESTION_TYPE_CHOICES = [
        ('choice', '选择题'),
        ('fill', '填空题'),
        ('solution', '解答题'),
    ]

    year = models.IntegerField('年份', null=True, blank=True)
    exam_type = models.CharField('考试类型', max_length=32, blank=True, default='')
    region = models.CharField('地区', max_length=32, blank=True, default='')
    source_name = models.CharField(
        '试卷或资料名称', max_length=255, blank=True, default=''
    )
    number = models.CharField('题号', max_length=16, blank=True, default='')
    content_origin = models.CharField(
        '来源性质', max_length=16, choices=ContentOrigin.choices,
        default=ContentOrigin.EXTERNAL,
    )
    contributed_by = models.ForeignKey(
        Student, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='contributed_questions', verbose_name='题目投稿人',
    )
    question_type = models.CharField(
        '题型', max_length=16, choices=QUESTION_TYPE_CHOICES
    )
    difficulty = models.FloatField('困难度', null=True, blank=True)
    calculation = models.FloatField('计算量', null=True, blank=True)
    stem = models.TextField('题干（不含img标签）')
    images = models.JSONField('配图路径列表', blank=True, default=list)
    default_score = models.FloatField('参考分值', null=True, blank=True)
    updated_at = models.DateTimeField('更新时间', auto_now=True)

    # 多对多关联
    concept_tags = models.ManyToManyField(
        ConceptTag, through='QuestionConceptTag',
        related_name='questions', blank=True
    )
    knowledge_cards = models.ManyToManyField(
        KnowledgeCard, through='QuestionKnowledgeCard',
        related_name='questions', blank=True
    )

    class Meta:
        verbose_name = '题目'
        verbose_name_plural = '题目'
        # 设计文档提到 year=2099 的 3 条测试数据已排除，不在 schema 层面约束

    def __str__(self):
        parts = [str(self.year) if self.year else '',
                 self.region, self.exam_type, str(self.number)]
        return ' '.join(p for p in parts if p)


class QuestionConceptTag(models.Model):
    """题目-概念标签 中间表"""
    question = models.ForeignKey(BaseQuestion, on_delete=models.CASCADE,
                                 related_name='question_concept_tags')
    concept_tag = models.ForeignKey(ConceptTag, on_delete=models.CASCADE,
                                    related_name='tag_questions')

    class Meta:
        verbose_name = '题目-概念标签'
        verbose_name_plural = '题目-概念标签'
        constraints = [
            models.UniqueConstraint(
                fields=['question', 'concept_tag'],
                name='uq_question_concept_tag'
            )
        ]


class QuestionKnowledgeCard(models.Model):
    """题目-知识卡片 中间表"""
    question = models.ForeignKey(BaseQuestion, on_delete=models.CASCADE,
                                 related_name='question_knowledge_cards')
    knowledge_card = models.ForeignKey(KnowledgeCard, on_delete=models.CASCADE,
                                       related_name='card_questions')

    class Meta:
        verbose_name = '题目-知识卡片'
        verbose_name_plural = '题目-知识卡片'
        constraints = [
            models.UniqueConstraint(
                fields=['question', 'knowledge_card'],
                name='uq_question_knowledge_card'
            )
        ]


class ChoiceExt(models.Model):
    """选择题扩展 - options 存四个选项"""
    question = models.OneToOneField(
        BaseQuestion, on_delete=models.CASCADE,
        related_name='choice_ext'
    )
    options = models.JSONField('选项', help_text='{"A":"...","B":"...","C":"...","D":"..."}')

    class Meta:
        verbose_name = '选择题选项'
        verbose_name_plural = '选择题选项'

    def __str__(self):
        return f'选项: {self.question_id}'


class SubQuestion(models.Model):
    """小题表 - 每道题必有至少一行"""
    question = models.ForeignKey(BaseQuestion, on_delete=models.CASCADE,
                                 related_name='sub_questions')
    parent = models.ForeignKey(
        'self', on_delete=models.CASCADE, null=True, blank=True,
        related_name='children'
    )
    stem = models.TextField('小题题干', null=True, blank=True)
    answer = models.TextField('正确答案', blank=True, default='')
    explanation = models.TextField('解析', blank=True, default='')
    sort_order = models.IntegerField('排序')

    class Meta:
        verbose_name = '小题'
        verbose_name_plural = '小题'
        ordering = ['question', 'sort_order']

    def __str__(self):
        return f'小题 {self.sort_order} (题 {self.question_id})'


class SolutionMethod(models.Model):
    """解法表"""
    sub_question = models.ForeignKey(
        SubQuestion, on_delete=models.CASCADE,
        related_name='solution_methods'
    )
    method_name = models.CharField('解法名称', max_length=64,
                                   null=True, blank=True,
                                   help_text='null=唯一解法')
    source = models.CharField('来源', max_length=32, blank=True, default='')
    content_origin = models.CharField(
        '来源性质', max_length=16, choices=ContentOrigin.choices,
        default=ContentOrigin.EXTERNAL,
    )
    contributed_by = models.ForeignKey(
        Student, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='contributed_solution_methods', verbose_name='解法投稿人',
    )
    sort_order = models.IntegerField('排序')

    class Meta:
        verbose_name = '解法'
        verbose_name_plural = '解法'
        ordering = ['sub_question', 'sort_order']

    def __str__(self):
        name = self.method_name or '唯一解法'
        return f'{name} (小题 {self.sub_question_id})'


class SolutionStep(models.Model):
    """解题步骤"""
    method = models.ForeignKey(
        SolutionMethod, on_delete=models.CASCADE,
        related_name='solution_steps'
    )
    step_number = models.IntegerField('步骤编号')
    title = models.CharField('步骤标题', max_length=128)
    content = models.TextField('步骤内容（含LaTeX）')
    card_titles = models.JSONField('关联知识卡片标题', blank=True, default=list)

    class Meta:
        verbose_name = '解题步骤'
        verbose_name_plural = '解题步骤'
        ordering = ['method', 'step_number']

    def __str__(self):
        return f'步骤 {self.step_number}: {self.title}'


class ContentChangeLog(models.Model):
    """内容工作台中人工修改的业务说明。"""

    actor = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='content_change_logs', verbose_name='操作人',
    )
    question = models.ForeignKey(
        BaseQuestion, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='workbench_changes', verbose_name='题目',
    )
    object_type = models.CharField('内容类型', max_length=32)
    object_id = models.PositiveIntegerField('内容 ID', null=True, blank=True)
    object_label = models.CharField('内容标题', max_length=255, blank=True)
    action = models.CharField('操作', max_length=32)
    note = models.CharField('修改说明', max_length=500)
    created_at = models.DateTimeField('操作时间', auto_now_add=True)

    class Meta:
        verbose_name = '内容修改记录'
        verbose_name_plural = '内容修改记录'
        ordering = ['-created_at', '-pk']

    def __str__(self):
        return f'{self.object_type} #{self.object_id or "-"}: {self.note}'
