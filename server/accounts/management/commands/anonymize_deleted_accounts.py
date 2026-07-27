from django.core.management.base import BaseCommand
from django.utils import timezone

from accounts.models import AccountDeletionRequest
from accounts.services.account_lifecycle import anonymize_due_accounts


class Command(BaseCommand):
    help = '匿名化已超过 7 天冷静期的注销账号'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run', action='store_true',
            help='仅显示待处理数量，不修改数据',
        )

    def handle(self, *args, **options):
        now = timezone.now()
        due_count = AccountDeletionRequest.objects.filter(
            status=AccountDeletionRequest.Status.PENDING,
            scheduled_for__lte=now,
        ).count()
        if options['dry_run']:
            self.stdout.write(f'{due_count} account(s) due for anonymization')
            return
        processed = anonymize_due_accounts(now=now)
        self.stdout.write(self.style.SUCCESS(
            f'Anonymized {processed} account(s)',
        ))
