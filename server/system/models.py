from django.db import models
from django.utils import timezone

from accounts.models import Student


class LevelConfig(models.Model):
    """等级配置"""
    level = models.IntegerField('等级', primary_key=True)
    min_xp = models.IntegerField('最小累计积分')
    title = models.CharField('等级名称', max_length=64)
    icon_emoji = models.CharField('图标emoji', max_length=16, null=True, blank=True)

    class Meta:
        verbose_name = '等级配置'
        verbose_name_plural = '等级配置'
        ordering = ['level']

    def __str__(self):
        return f'Lv.{self.level} {self.title}'

    @staticmethod
    def get_level(total_pts: int) -> int:
        """根据累计积分获取等级"""
        config = LevelConfig.objects.filter(
            min_xp__lte=total_pts
        ).order_by('-min_xp').first()
        return config.level if config else 1


class AchievementDef(models.Model):
    """成就定义"""
    CATEGORY_CHOICES = [
        ('LOGIN', '登录'),
        ('PRACTICE', '练习'),
        ('STREAK', '毅力'),
        ('ACCURACY', '精确度'),
        ('PAPER', '组卷'),
        ('RATING', '评分'),
    ]

    TRIGGER_CHOICES = [
        ('LOGIN_STREAK', '连续登录'),
        ('PRACTICE_COUNT', '做题数量'),
        ('PRACTICE_STREAK', '连续做题'),
        ('ACCURACY_RATE', '正确率'),
        ('CONSECUTIVE_CORRECT', '连续正确'),
        ('PAPER_COUNT', '组卷数量'),
        ('RATING_COUNT', '评分数量'),
    ]

    code = models.CharField('编码', max_length=64, unique=True)
    name = models.CharField('名称', max_length=64)
    description = models.TextField('描述', blank=True, default='')
    icon = models.CharField('图标URL', max_length=256, null=True, blank=True)
    icon_emoji = models.CharField('图标emoji', max_length=16, null=True, blank=True)
    category = models.CharField('分类', max_length=32, choices=CATEGORY_CHOICES)
    category_label = models.CharField('分类标签', max_length=32, null=True, blank=True)
    display_order = models.IntegerField('展示顺序', default=0)
    trigger_type = models.CharField('触发类型', max_length=32, choices=TRIGGER_CHOICES,
                                    null=True, blank=True)
    threshold = models.IntegerField('达成阈值', default=0)

    class Meta:
        verbose_name = '成就定义'
        verbose_name_plural = '成就定义'
        ordering = ['category', 'display_order']

    def __str__(self):
        return self.name


class StudentAchievement(models.Model):
    """学生成就进度"""
    student = models.ForeignKey(
        Student, on_delete=models.CASCADE,
        related_name='achievements'
    )
    achievement = models.ForeignKey(
        AchievementDef, on_delete=models.CASCADE,
        related_name='student_achievements'
    )
    progress = models.IntegerField('进度', default=0)
    is_unlocked = models.BooleanField('已解锁', default=False)
    unlocked_at = models.DateTimeField('解锁时间', null=True, blank=True)
    updated_at = models.DateTimeField('更新时间', auto_now=True)

    class Meta:
        verbose_name = '学生成就'
        verbose_name_plural = '学生成就'
        constraints = [
            models.UniqueConstraint(
                fields=['student', 'achievement'],
                name='uq_student_achievement'
            )
        ]

    def __str__(self):
        return f'{self.student} - {self.achievement.name}'


class PointsTransaction(models.Model):
    """积分流水"""
    TRANSACTION_TYPE_CHOICES = [
        ('EARN', '收入'),
        ('SPEND', '支出'),
    ]

    SOURCE_CHOICES = [
        ('LOGIN_BONUS', '签到'),
        ('PRACTICE_REWARD', '做题奖励'),
        ('TASK_REWARD', '完成任务'),
        ('SIGNUP_BONUS', '新人赠送'),
        ('PAPER_PURCHASE', '组卷消费'),
        ('REVIEW_REWARD', '退出评价奖励'),
        ('RATING_REWARD', '题目评价奖励'),
        ('ADMIN_ADJUST', '管理员调整'),
    ]

    student = models.ForeignKey(
        Student, on_delete=models.CASCADE,
        related_name='point_transactions'
    )
    amount = models.FloatField('金额（正=收入，负=支出）（分）')
    transaction_type = models.CharField('类型', max_length=16,
                                        choices=TRANSACTION_TYPE_CHOICES)
    source = models.CharField('来源', max_length=32, choices=SOURCE_CHOICES)
    source_object_id = models.IntegerField('关联业务ID', null=True, blank=True)
    client_id = models.IntegerField('客户端ID', null=True, blank=True, db_index=True)
    description = models.CharField('描述', max_length=255, blank=True, default='')
    created_at = models.DateTimeField('创建时间', auto_now_add=True)

    class Meta:
        verbose_name = '积分流水'
        verbose_name_plural = '积分流水'
        ordering = ['-created_at']
        constraints = [
            models.UniqueConstraint(
                fields=['student', 'source', 'source_object_id'],
                condition=models.Q(
                    source='RATING_REWARD',
                    source_object_id__isnull=False,
                ),
                name='uq_rating_reward_per_student_question',
            ),
        ]

    def __str__(self):
        return f'{self.get_source_display()} {self.amount:+.1f} ({self.student})'


class DbVersion(models.Model):
    """数据库版本"""
    DB_TYPE_CHOICES = [
        ('qbank', '题库'),
        ('courses', '课程'),
    ]

    db_type = models.CharField('数据库类型', max_length=16,
                               choices=DB_TYPE_CHOICES, unique=True)
    schema_version = models.IntegerField('Schema版本', default=1)
    data_version = models.IntegerField('数据版本', default=1)
    checksum = models.CharField('SHA256校验和', max_length=128, blank=True, default='')
    size_bytes = models.IntegerField('文件大小', default=0)
    download_url = models.CharField('下载路径', max_length=500, blank=True, default='')
    force_update = models.BooleanField('强制更新', default=False)
    message = models.TextField('更新说明', blank=True, default='')
    built_at = models.DateTimeField('构建时间', null=True, blank=True)
    created_at = models.DateTimeField('创建时间', default=timezone.now)
    updated_at = models.DateTimeField('更新时间', auto_now=True)

    class Meta:
        verbose_name = '数据库版本'
        verbose_name_plural = '数据库版本'

    def __str__(self):
        return f'{self.get_db_type_display()} v{self.data_version}'


class AppVersion(models.Model):
    """App版本"""
    PLATFORM_CHOICES = [
        ('android', 'Android'),
        ('ios', 'iOS'),
    ]

    platform = models.CharField('平台', max_length=16, choices=PLATFORM_CHOICES)
    version_name = models.CharField('版本名', max_length=32)
    version_code = models.IntegerField('版本号')
    force_update = models.BooleanField('强制更新', default=False)
    download_url = models.URLField('下载地址', max_length=512, blank=True, default='')
    release_notes = models.TextField('更新说明', blank=True, default='')
    created_at = models.DateTimeField('创建时间', auto_now_add=True)

    class Meta:
        verbose_name = 'App版本'
        verbose_name_plural = 'App版本'
        constraints = [
            models.UniqueConstraint(
                fields=['platform', 'version_code'],
                name='uq_platform_version_code'
            )
        ]

    def __str__(self):
        return f'{self.get_platform_display()} {self.version_name}'


class Announcement(models.Model):
    """公告"""
    title = models.CharField('标题', max_length=128)
    content = models.TextField('内容')
    is_active = models.BooleanField('是否有效', default=True)
    created_at = models.DateTimeField('创建时间', auto_now_add=True)

    class Meta:
        verbose_name = '公告'
        verbose_name_plural = '公告'
        ordering = ['-created_at']

    def __str__(self):
        return self.title


class SystemConfig(models.Model):
    """系统级键值配置"""
    key = models.CharField('键', max_length=64, unique=True)
    value = models.TextField('值', blank=True, default='')
    description = models.CharField('说明', max_length=255, blank=True, default='')

    class Meta:
        verbose_name = '系统配置'
        verbose_name_plural = '系统配置'
        ordering = ['key']

    def __str__(self):
        return self.key


# ── 系统工具入口（admin 虚拟代理） ──────────────────────────


class SystemToolsProxy(models.Model):
    """仅用于在 admin 首页展示「系统工具」入口，无数据库表"""

    class Meta:
        managed = False
        verbose_name = '系统工具'
        verbose_name_plural = '系统工具'


class AdminHelpProxy(models.Model):
    """仅用于在 admin 首页展示「管理员使用说明」入口，无数据库表"""

    class Meta:
        managed = False
        verbose_name = '管理员使用说明'
        verbose_name_plural = '管理员使用说明'
