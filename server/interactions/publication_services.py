import gzip
import shutil
import sqlite3
import tempfile
from pathlib import Path

from django.db import transaction

from .models import ContentContribution, ContributionReview


def question_ids_in_bundle(bundle_path):
    """Return question ids that are actually present in a qbank bundle."""
    bundle_path = Path(bundle_path)
    with tempfile.TemporaryDirectory(prefix='qbank-publication-') as temp_dir:
        database_path = Path(temp_dir) / 'qbank.db'
        with gzip.open(bundle_path, 'rb') as source, database_path.open('wb') as target:
            shutil.copyfileobj(source, target)
        connection = sqlite3.connect(
            f'file:{database_path.as_posix()}?mode=ro', uri=True
        )
        try:
            return {
                int(row[0])
                for row in connection.execute('SELECT id FROM question')
            }
        finally:
            connection.close()


@transaction.atomic
def confirm_qbank_publication(bundle_path, data_version):
    """Mark only contributions whose official question exists in the bundle."""
    question_ids = question_ids_in_bundle(bundle_path)
    candidates = ContentContribution.objects.select_for_update().filter(
        status=ContentContribution.Status.APPROVED_PENDING_RELEASE,
        published_qbank_version__isnull=True,
    )
    contribution_ids = [
        contribution.pk
        for contribution in candidates.only('pk', 'completed_question_id')
        if contribution.completed_question_id in question_ids
    ]
    queryset = ContentContribution.objects.filter(pk__in=contribution_ids)
    queryset.update(
        status=ContentContribution.Status.COMPLETED,
        published_qbank_version=data_version,
    )
    ContributionReview.objects.bulk_create([
        ContributionReview(
            contribution_id=contribution_id,
            action=ContributionReview.Action.PUBLISHED,
            note=f'首次发布至题库 v{data_version}',
        )
        for contribution_id in contribution_ids
    ])
    return len(contribution_ids)


@transaction.atomic
def rollback_qbank_publication(data_version):
    """Undo contributions first published by a rolled-back qbank version."""
    queryset = ContentContribution.objects.select_for_update().filter(
        status=ContentContribution.Status.COMPLETED,
        published_qbank_version=data_version,
    )
    contribution_ids = list(queryset.values_list('pk', flat=True))
    queryset.update(
        status=ContentContribution.Status.APPROVED_PENDING_RELEASE,
        published_qbank_version=None,
    )
    ContributionReview.objects.bulk_create([
        ContributionReview(
            contribution_id=contribution_id,
            action=ContributionReview.Action.PUBLICATION_ROLLED_BACK,
            note=f'题库 v{data_version} 已回滚，等待重新发布',
        )
        for contribution_id in contribution_ids
    ])
    return len(contribution_ids)
