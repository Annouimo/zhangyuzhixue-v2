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
