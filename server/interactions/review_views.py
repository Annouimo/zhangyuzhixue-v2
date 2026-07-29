import json
from functools import wraps

from django.contrib import messages
from django.contrib.auth import login, logout
from django.core.paginator import Paginator
from django.db import transaction
from django.db.models import Q
from django.http import HttpResponseForbidden
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from django.utils import timezone
from django.utils.http import url_has_allowed_host_and_scheme

from accounts.roles import PUBLISH_CONTRIBUTION, is_content_reviewer

from .models import ContentContribution, ContributionReview
from .models import ContributionTagSuggestion
from .review_forms import ContributionReviewForm, ReviewerAuthenticationForm
from .review_services import (
    question_payload, resolve_tags, save_official_question, save_solution_method,
)


def reviewer_required(view_func):
    @wraps(view_func)
    def wrapped(request, *args, **kwargs):
        if not request.user.is_authenticated:
            login_url = reverse('review_workbench:login')
            return redirect(f'{login_url}?next={request.get_full_path()}')
        if not is_content_reviewer(request.user):
            return HttpResponseForbidden('当前账号没有内容审核权限。')
        return view_func(request, *args, **kwargs)
    return wrapped


def login_view(request):
    if is_content_reviewer(request.user):
        return redirect('review_workbench:queue')
    form = ReviewerAuthenticationForm(request=request, data=request.POST or None)
    if request.method == 'POST' and form.is_valid():
        login(request, form.get_user())
        request.session.set_expiry(60 * 60 * 12)
        next_url = request.POST.get('next', '')
        if next_url and url_has_allowed_host_and_scheme(
            next_url, allowed_hosts={request.get_host()},
            require_https=request.is_secure(),
        ):
            return redirect(next_url)
        return redirect('review_workbench:queue')
    return render(request, 'review_workbench/login.html', {
        'form': form, 'next': request.GET.get('next', ''),
    })


def logout_view(request):
    if request.method == 'POST':
        logout(request)
        return redirect('review_workbench:login')
    return redirect('review_workbench:queue')


@reviewer_required
def queue_view(request):
    status_filter = request.GET.get('status', '')
    type_filter = request.GET.get('type', '')
    query = request.GET.get('q', '').strip()[:100]
    mine_only = request.GET.get('mine') == '1'
    queryset = ContentContribution.objects.select_related(
        'student__user', 'question', 'reviewed_by'
    ).prefetch_related('revisions')
    if not status_filter:
        pass
    elif status_filter == 'active':
        queryset = queryset.filter(status__in=[
            ContentContribution.Status.PENDING,
            ContentContribution.Status.RESUBMITTED,
            ContentContribution.Status.PROCESSING,
        ])
    elif status_filter in ContentContribution.Status.values:
        queryset = queryset.filter(status=status_filter)
    else:
        status_filter = ''
    if type_filter in ContentContribution.ContributionType.values:
        queryset = queryset.filter(contribution_type=type_filter)
    else:
        type_filter = ''
    if mine_only:
        queryset = queryset.filter(reviewed_by=request.user)
    if query:
        queryset = queryset.filter(
            Q(student__user__username__icontains=query)
            | Q(question__stem__icontains=query)
            | Q(revisions__normalized_payload__icontains=query)
        ).distinct()
    queryset = queryset.order_by('-updated_at', '-pk')
    paginator = Paginator(queryset, 30)
    page = paginator.get_page(request.GET.get('page'))
    return render(request, 'review_workbench/queue.html', {
        'contributions': page.object_list,
        'page': page,
        'total_count': paginator.count,
        'status_filter': status_filter,
        'type_filter': type_filter,
        'query': query,
        'mine_only': mine_only,
        'status_choices': ContentContribution.Status.choices,
        'type_choices': ContentContribution.ContributionType.choices,
    })


def _initial_payload(contribution):
    if contribution.contribution_type == ContentContribution.ContributionType.NEW_QUESTION:
        revision = contribution.revisions.order_by('-revision_number').first()
        return revision.normalized_payload if revision else {}
    if contribution.contribution_type == ContentContribution.ContributionType.NEW_SOLUTION:
        revision = contribution.revisions.order_by('-revision_number').first()
        return revision.normalized_payload if revision else {}
    revision = contribution.revisions.order_by('-revision_number').first()
    if revision:
        proposed = revision.normalized_payload.get('proposed_question')
        if proposed:
            return proposed
    return question_payload(contribution.question)


def _original_correction_payload(contribution, revision):
    if not revision or not revision.question_snapshot:
        return question_payload(contribution.question)
    return revision.question_snapshot


def _detail_url(request, contribution_id):
    url = reverse('review_workbench:detail', args=[contribution_id])
    query = request.GET.urlencode()
    return f'{url}?{query}' if query else url


@reviewer_required
def detail_view(request, contribution_id):
    contribution = get_object_or_404(
        ContentContribution.objects.select_related(
            'student__user', 'question', 'target_sub_question',
            'reviewed_by', 'completed_question'
        ).prefetch_related(
            'revisions', 'reviews__actor', 'tag_selections__concept_tag',
            'tag_suggestions__suggested_parent',
            'completed_question__concept_tags',
        ),
        pk=contribution_id,
    )
    latest_revision = contribution.revisions.order_by('-revision_number').first()
    initial = {
        'content_json': json.dumps(
            _initial_payload(contribution), ensure_ascii=False, indent=2
        ),
        'tags': (
            contribution.completed_question.concept_tags.values_list(
                'pk', flat=True
            )
            if contribution.completed_question_id
            else contribution.tag_selections.values_list(
                'concept_tag_id', flat=True
            )
        ),
        'note': contribution.review_note,
        'version': contribution.updated_at.isoformat(),
    }
    form = ContributionReviewForm(
        request.POST or None,
        initial=initial,
        contribution_type=contribution.contribution_type,
    )
    is_terminal = contribution.status in {
        ContentContribution.Status.APPROVED_PENDING_RELEASE,
        ContentContribution.Status.COMPLETED,
        ContentContribution.Status.REJECTED,
        ContentContribution.Status.WITHDRAWN,
    }

    if request.method == 'POST' and not is_terminal:
        action = request.POST.get('action')
        if action in {'processing', 'needs_revision', 'rejected'}:
            note = request.POST.get('note', '').strip()[:2000]
            if action in {'needs_revision', 'rejected'} and not note:
                form.add_error('note', '打回修改或不采纳时必须填写审核意见。')
            else:
                try:
                    _apply_status_action(
                        request, contribution.pk, request.POST.get('version', ''),
                        action, note,
                    )
                except ValueError as exc:
                    form.add_error(None, str(exc))
                else:
                    messages.success(request, _success_message(action))
                    return redirect(_detail_url(request, contribution.pk))
        elif action == 'publish' and not request.user.has_perm(PUBLISH_CONTRIBUTION):
            return HttpResponseForbidden('当前账号没有正式录题权限。')
        elif action == 'publish' and form.is_valid():
            try:
                _apply_action(request, contribution.pk, form, action)
            except ValueError as exc:
                form.add_error(None, str(exc))
            else:
                messages.success(
                    request, '审核通过，正式题目已保存并等待下一版题库发布。'
                )
                return redirect(_detail_url(request, contribution.pk))

    detail_status_filter = request.GET.get('status', '')
    active_queryset = ContentContribution.objects.all()
    if detail_status_filter == 'active':
        active_queryset = active_queryset.filter(status__in=[
            ContentContribution.Status.PENDING,
            ContentContribution.Status.RESUBMITTED,
            ContentContribution.Status.PROCESSING,
        ])
    elif detail_status_filter in ContentContribution.Status.values:
        active_queryset = active_queryset.filter(status=detail_status_filter)
    detail_type_filter = request.GET.get('type', '')
    if detail_type_filter in ContentContribution.ContributionType.values:
        active_queryset = active_queryset.filter(
            contribution_type=detail_type_filter
        )
    if request.GET.get('mine') == '1':
        active_queryset = active_queryset.filter(reviewed_by=request.user)
    detail_query = request.GET.get('q', '').strip()[:100]
    if detail_query:
        active_queryset = active_queryset.filter(
            Q(student__user__username__icontains=detail_query)
            | Q(question__stem__icontains=detail_query)
            | Q(revisions__normalized_payload__icontains=detail_query)
        ).distinct()
    active_queryset = active_queryset.order_by('-updated_at', '-pk')
    active_ids = list(active_queryset.values_list('pk', flat=True))
    try:
        active_index = active_ids.index(contribution.pk)
    except ValueError:
        active_index = -1

    return render(request, 'review_workbench/detail.html', {
        'contribution': contribution,
        'latest_revision': latest_revision,
        'form': form,
        'is_terminal': is_terminal,
        'original_payload': _original_correction_payload(
            contribution, latest_revision
        ) if contribution.question_id else None,
        'previous_id': active_ids[active_index - 1] if active_index > 0 else None,
        'next_id': (
            active_ids[active_index + 1]
            if 0 <= active_index < len(active_ids) - 1 else None
        ),
    })


def _success_message(action):
    return {
        'processing': '已标记为处理中。',
        'needs_revision': '已打回修改，投稿人将看到审核意见。',
        'rejected': '已标记为不采纳。',
    }[action]


@transaction.atomic
def _apply_status_action(request, contribution_id, version, action, note):
    contribution = ContentContribution.objects.select_for_update().get(
        pk=contribution_id
    )
    if version != contribution.updated_at.isoformat():
        raise ValueError('该投稿已被其他人更新，请刷新页面后重新处理。')
    if contribution.status in {
        ContentContribution.Status.APPROVED_PENDING_RELEASE,
        ContentContribution.Status.COMPLETED,
        ContentContribution.Status.REJECTED,
        ContentContribution.Status.WITHDRAWN,
    }:
        raise ValueError('该投稿已经结束，不能再次处理。')
    statuses = {
        'processing': ContentContribution.Status.PROCESSING,
        'needs_revision': ContentContribution.Status.NEEDS_REVISION,
        'rejected': ContentContribution.Status.REJECTED,
    }
    contribution.status = statuses[action]
    contribution.review_note = note
    contribution.reviewed_by = request.user
    contribution.reviewed_at = timezone.now()
    contribution.save()
    ContributionReview.objects.create(
        contribution=contribution, actor=request.user, action=action, note=note
    )


@transaction.atomic
def _apply_action(request, contribution_id, form, action):
    contribution = ContentContribution.objects.select_for_update().select_related(
        'question', 'target_sub_question'
    ).get(pk=contribution_id)
    if form.cleaned_data['version'] != contribution.updated_at.isoformat():
        raise ValueError('该投稿已被其他人更新，请刷新页面后重新处理。')
    if contribution.status in {
        ContentContribution.Status.APPROVED_PENDING_RELEASE,
        ContentContribution.Status.COMPLETED,
        ContentContribution.Status.REJECTED,
        ContentContribution.Status.WITHDRAWN,
    }:
        raise ValueError('该投稿已经结束，不能再次处理。')

    if action == 'publish':
        approved_ids = []
        pending_suggestions = contribution.tag_suggestions.filter(
            status=ContributionTagSuggestion.Status.PENDING
        )
        for suggestion in pending_suggestions:
            decision = request.POST.get(f'suggestion_decision_{suggestion.pk}')
            if decision == 'create':
                approved_ids.append(str(suggestion.pk))
            elif decision == 'reject':
                suggestion.status = ContributionTagSuggestion.Status.REJECTED
                suggestion.reviewer_note = '审核员未采纳此标签建议'
                suggestion.save(update_fields=['status', 'reviewer_note'])
            else:
                raise ValueError(f'请处理新标签建议“{suggestion.suggested_name}”。')
        selected_tags = form.cleaned_data['tags']
        if not selected_tags and contribution.question_id:
            selected_tags = contribution.question.concept_tags.all()
        tags = resolve_tags(contribution, selected_tags, approved_ids)
        if (
            contribution.contribution_type
            != ContentContribution.ContributionType.NEW_SOLUTION
            and not tags
        ):
            raise ValueError('录入正式题库前至少需要一个标签。')
        is_correction = contribution.contribution_type == (
            ContentContribution.ContributionType.QUESTION_CORRECTION
        )
        is_solution = contribution.contribution_type == (
            ContentContribution.ContributionType.NEW_SOLUTION
        )
        if is_solution:
            if not contribution.target_sub_question_id:
                raise ValueError('解法投稿缺少目标小题。')
            method = save_solution_method(
                contribution.target_sub_question,
                form.cleaned_data['content_json'],
                content_origin=contribution.content_origin,
                contributor=contribution.student,
            )
            question = contribution.question
            contribution.completed_solution_method = method
        else:
            target = contribution.question if is_correction else None
            content = form.cleaned_data['content_json']
            if is_correction:
                latest = contribution.revisions.order_by('-revision_number').first()
                base_updated_at = (
                    latest.normalized_payload.get('base_updated_at')
                    if latest else None
                )
                if (
                    base_updated_at
                    and base_updated_at != contribution.question.updated_at.isoformat()
                ):
                    raise ValueError('正式题目已发生变化，请重新比较后再应用纠错。')
            question = save_official_question(
                content,
                tags,
                question=target,
                content_origin=(
                    content.get('content_origin', contribution.question.content_origin)
                    if is_correction else contribution.content_origin
                ),
                contributor=None if is_correction else contribution.student,
                replace_methods=bool(
                    any(item.get('solution_methods') for item in content['sub_questions'])
                ),
            )
        contribution.completed_question = question
        contribution.status = ContentContribution.Status.APPROVED_PENDING_RELEASE
        review_action = ContributionReview.Action.COMPLETED
    else:
        raise ValueError('未知的审核操作。')

    contribution.review_note = form.cleaned_data['note'].strip()
    contribution.reviewed_by = request.user
    contribution.reviewed_at = timezone.now()
    contribution.save()
    ContributionReview.objects.create(
        contribution=contribution,
        actor=request.user,
        action=review_action,
        note=contribution.review_note,
    )
