from django.core.exceptions import ValidationError
from django.db import models


class PortalStatus(models.TextChoices):
    ACTIVE = 'active', '正常运行'
    INTERNAL_TEST = 'internal_test', '内部测试'
    IN_PROGRESS = 'in_progress', '开发中'
    PENDING = 'pending', '待确认'
    PAUSED = 'paused', '暂停维护'
    RETIRED = 'retired', '已下线'
    ARCHIVED = 'archived', '历史资料'


class ProjectProfile(models.Model):
    title = models.CharField('门户标题', max_length=80, default='章鱼智学项目中心')
    positioning = models.CharField('项目定位', max_length=240, blank=True)
    current_phase = models.CharField('当前阶段', max_length=160, blank=True)
    current_focus = models.TextField('当前重点', blank=True)
    updated_at = models.DateTimeField('更新时间', auto_now=True)

    class Meta:
        verbose_name = '项目概览'
        verbose_name_plural = '项目概览'

    def clean(self):
        if ProjectProfile.objects.exclude(pk=self.pk).exists():
            raise ValidationError('项目概览只能保留一条记录。')

    def __str__(self):
        return self.title


class TeamMember(models.Model):
    name = models.CharField('姓名', max_length=40, unique=True)
    responsibility = models.CharField('主要职责', max_length=160, blank=True)
    is_active = models.BooleanField('在团队中', default=True)
    sort_order = models.PositiveIntegerField('排序', default=0)
    updated_at = models.DateTimeField('更新时间', auto_now=True)

    class Meta:
        ordering = ('sort_order', 'id')
        verbose_name = '团队成员'
        verbose_name_plural = '团队成员'

    def __str__(self):
        return self.name


class BusinessArea(models.Model):
    name = models.CharField('板块名称', max_length=60)
    slug = models.SlugField('地址标识', max_length=40, unique=True)
    summary = models.CharField('板块说明', max_length=240)
    status = models.CharField(
        '状态', max_length=24, choices=PortalStatus.choices,
        default=PortalStatus.ACTIVE,
    )
    owners = models.ManyToManyField(
        TeamMember, verbose_name='负责人', blank=True,
        related_name='business_areas',
    )
    is_visible = models.BooleanField('显示', default=True)
    sort_order = models.PositiveIntegerField('排序', default=0)
    updated_at = models.DateTimeField('更新时间', auto_now=True)

    class Meta:
        ordering = ('sort_order', 'id')
        verbose_name = '业务板块'
        verbose_name_plural = '业务板块'

    def __str__(self):
        return self.name


class HandbookSection(models.Model):
    page = models.ForeignKey(
        BusinessArea, verbose_name='所属页面', on_delete=models.CASCADE,
        related_name='sections',
    )
    title = models.CharField('章节标题', max_length=100)
    slug = models.SlugField('章节标识', max_length=50)
    body = models.TextField('正文', blank=True)
    is_visible = models.BooleanField('显示', default=True)
    sort_order = models.PositiveIntegerField('排序', default=0)
    updated_at = models.DateTimeField('更新时间', auto_now=True)

    class Meta:
        ordering = ('page__sort_order', 'sort_order', 'id')
        constraints = [
            models.UniqueConstraint(
                fields=('page', 'slug'), name='unique_handbook_page_section',
            ),
        ]
        verbose_name = '手册章节'
        verbose_name_plural = '手册章节'

    def __str__(self):
        return f'{self.page.name} / {self.title}'


class PortalEntry(models.Model):
    class EntryType(models.TextChoices):
        PRODUCT = 'product', '产品'
        DOWNLOAD = 'download', '下载'
        MEDIA = 'media', '自媒体'
        DOCUMENT = 'document', '文档'
        TOOL = 'tool', '工具'
        SERVICE = 'service', '服务'

    area = models.ForeignKey(
        BusinessArea, verbose_name='所属板块', on_delete=models.CASCADE,
        related_name='entries',
    )
    section = models.ForeignKey(
        HandbookSection, verbose_name='所属章节', on_delete=models.SET_NULL,
        related_name='entries', null=True, blank=True,
    )
    name = models.CharField('名称', max_length=100)
    entry_type = models.CharField(
        '类型', max_length=20, choices=EntryType.choices,
    )
    description = models.CharField('说明', max_length=300, blank=True)
    status = models.CharField(
        '状态', max_length=24, choices=PortalStatus.choices,
        default=PortalStatus.ACTIVE,
    )
    owners = models.ManyToManyField(
        TeamMember, verbose_name='负责人', blank=True,
        related_name='portal_entries',
    )
    url = models.CharField('入口地址', max_length=600, blank=True)
    link_label = models.CharField('入口文字', max_length=40, default='打开入口')
    is_visible = models.BooleanField('显示', default=True)
    sort_order = models.PositiveIntegerField('排序', default=0)
    updated_at = models.DateTimeField('更新时间', auto_now=True)

    class Meta:
        ordering = ('area__sort_order', 'sort_order', 'id')
        verbose_name = '门户条目'
        verbose_name_plural = '门户条目'

    def clean(self):
        if self.url and not self.url.startswith(('/', 'https://', 'http://')):
            raise ValidationError({'url': '地址必须是站内路径或 HTTP(S) 地址。'})

    @property
    def is_external(self):
        return self.url.startswith(('https://', 'http://'))

    def __str__(self):
        return self.name
