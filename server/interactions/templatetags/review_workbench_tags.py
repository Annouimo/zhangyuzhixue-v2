from django import template
from django.db.models import BooleanField, Count, Q
from django.db.models.expressions import RawSQL

from interactions.models import ContentContribution


register = template.Library()


@register.simple_tag
def workbench_queue_counts():
    active = ContentContribution.objects.filter(
        status__in=[
            ContentContribution.Status.PENDING,
            ContentContribution.Status.RESUBMITTED,
            ContentContribution.Status.PROCESSING,
        ]
    ).annotate(
        has_proposed_question=RawSQL(
            """
            json_type((
                SELECT revision.normalized_payload
                FROM interactions_contributionrevision AS revision
                WHERE revision.contribution_id = interactions_contentcontribution.id
                ORDER BY revision.revision_number DESC
                LIMIT 1
            ), '$.proposed_question') IS NOT NULL
            """,
            params=(),
            output_field=BooleanField(),
        )
    )
    return active.aggregate(
        all=Count('pk'),
        new_question=Count(
            'pk', filter=Q(contribution_type='new_question')
        ),
        new_solution=Count(
            'pk', filter=Q(contribution_type='new_solution')
        ),
        content_change=Count(
            'pk', filter=Q(
                contribution_type='question_correction',
                has_proposed_question=True,
            )
        ),
        problem_report=Count(
            'pk', filter=Q(
                contribution_type='question_correction',
                has_proposed_question=False,
            )
        ),
    )
