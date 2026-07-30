from django.core.management.base import BaseCommand
from django.db import transaction

from courses.models import Course, Document
from interactions.workbench_revisions import ensure_baseline_revision
from qbank.models import BaseQuestion, ConceptTag, KnowledgeCard, WorkbenchRevision


CONTENT_MODELS = (
    ('question', BaseQuestion),
    ('tag', ConceptTag),
    ('card', KnowledgeCard),
    ('course', Course),
    ('document', Document),
)


class Command(BaseCommand):
    help = '为尚无工作台修订历史的现有内容生成幂等初始基线'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run', action='store_true',
            help='只统计将生成和跳过的数量，不写入数据库',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        results = {}
        with transaction.atomic():
            for content_type, model in CONTENT_MODELS:
                existing_ids = set(
                    WorkbenchRevision.objects.filter(content_type=content_type)
                    .values_list('object_id', flat=True)
                )
                queryset = model.objects.order_by('pk')
                total = queryset.count()
                created = 0
                for instance in queryset.iterator(chunk_size=200):
                    if instance.pk in existing_ids:
                        continue
                    created += 1
                    if not dry_run:
                        ensure_baseline_revision(content_type, instance)
                results[content_type] = {
                    'total': total,
                    'created': created,
                    'skipped': total - created,
                }
            if dry_run:
                transaction.set_rollback(True)

        mode = '演练' if dry_run else '完成'
        self.stdout.write(self.style.SUCCESS(f'工作台基线回填{mode}'))
        for content_type, _model in CONTENT_MODELS:
            row = results[content_type]
            self.stdout.write(
                f'{content_type}: total={row["total"]} '
                f'created={row["created"]} skipped={row["skipped"]}'
            )
