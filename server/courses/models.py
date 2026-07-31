from django.db import models


class Course(models.Model):
    """讲义系列。

    保留原模型名以避免无意义的数据迁移；它不再表示售卖课程或权限单元。
    """
    name = models.CharField('课程名', max_length=128)
    description = models.TextField('描述', blank=True, default='')

    class Meta:
        verbose_name = '讲义系列'
        verbose_name_plural = '讲义系列'

    def __str__(self):
        return self.name


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


class VideoCategory(models.Model):
    """视频目录分类。"""
    name = models.CharField('名称', max_length=64, unique=True)
    description = models.CharField('说明', max_length=255, blank=True, default='')
    sort_order = models.PositiveIntegerField('排序', default=0)

    class Meta:
        ordering = ('sort_order', 'id')
        verbose_name = '视频分类'
        verbose_name_plural = '视频分类'

    def __str__(self):
        return self.name


class Video(models.Model):
    """发布在外部自媒体平台的视频。"""
    category = models.ForeignKey(
        VideoCategory, on_delete=models.PROTECT, related_name='videos',
    )
    title = models.CharField('标题', max_length=160)
    description = models.TextField('简介', blank=True, default='')
    cover_url = models.URLField('封面地址', max_length=500, blank=True, default='')
    platform_name = models.CharField('发布平台', max_length=64, blank=True, default='')
    video_url = models.URLField('视频地址', max_length=500)
    published_at = models.DateField('发布日期', null=True, blank=True)
    sort_order = models.PositiveIntegerField('排序', default=0)
    is_published = models.BooleanField('已上架', default=False)
    documents = models.ManyToManyField(
        Document, through='VideoDocumentLink', related_name='videos',
    )

    class Meta:
        ordering = ('category__sort_order', 'sort_order', '-published_at', 'id')
        verbose_name = '视频'
        verbose_name_plural = '视频'

    def __str__(self):
        return self.title


class VideoDocumentLink(models.Model):
    """视频与讲义的有序双向关联。"""
    video = models.ForeignKey(Video, on_delete=models.CASCADE)
    document = models.ForeignKey(Document, on_delete=models.CASCADE)
    relation_label = models.CharField(
        '关联说明', max_length=64, blank=True, default='',
        help_text='如“配套讲解”“例题演示”“拓展内容”',
    )
    sort_order = models.PositiveIntegerField('排序', default=0)

    class Meta:
        ordering = ('sort_order', 'id')
        constraints = [
            models.UniqueConstraint(
                fields=('video', 'document'),
                name='unique_video_document_link',
            ),
        ]
        verbose_name = '视频讲义关联'
        verbose_name_plural = '视频讲义关联'

    def __str__(self):
        return f'{self.video} → {self.document}'
