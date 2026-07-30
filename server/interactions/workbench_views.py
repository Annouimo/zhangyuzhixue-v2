import json

from django.contrib import messages
from django.core.paginator import Paginator
from django.db import transaction
from django.db.models import Count
from django.http import HttpResponse, HttpResponseForbidden
from django.shortcuts import get_object_or_404, redirect, render

from accounts.roles import PUBLISH_CONTRIBUTION
from courses.models import Course, Document
from qbank.models import ContentChangeLog, WorkbenchRevision
from system.models import DbVersion

from .models import ContentContribution, ReviewerTrainingProgress
from .review_views import reviewer_required
from .training_data import (
    TRAINING_CASE_ID, TRAINING_EXPECTED, TRAINING_INITIAL_PAYLOAD,
)
from .workbench_forms import CourseWorkbenchForm, DocumentWorkbenchForm
from .workbench_release import build_candidate, publish
from .workbench_revisions import (
    CATEGORY_TYPES, ensure_baseline_revision, field_diffs, previous_revision,
    record_revision,
)


@reviewer_required
def home(request):
    statuses = ContentContribution.objects.values('status').annotate(count=Count('pk'))
    counts = {row['status']: row['count'] for row in statuses}
    progress = ReviewerTrainingProgress.objects.filter(
        reviewer=request.user
    ).first()
    return render(request, 'review_workbench/home.html', {
        'status_counts': counts,
        'versions': {item.db_type: item for item in DbVersion.objects.all()},
        'course_count': Course.objects.count(),
        'document_count': Document.objects.count(),
        'training_done': progress.completed_steps if progress else [],
    })


@reviewer_required
def course_list(request):
    return render(request, 'review_workbench/course_list.html', {
        'courses': Course.objects.annotate(document_count=Count('documents')).order_by('name'),
        'documents': Document.objects.select_related('course').order_by('course__name', 'chapter'),
    })


@reviewer_required
def course_edit(request, object_id=None):
    instance = get_object_or_404(Course, pk=object_id) if object_id else None
    form = CourseWorkbenchForm(request.POST or None, instance=instance)
    if request.method == 'POST' and form.is_valid():
        with transaction.atomic():
            action = 'create' if instance is None else 'update'
            if instance is not None:
                baseline_instance = Course.objects.select_for_update().get(
                    pk=instance.pk
                )
                ensure_baseline_revision('course', baseline_instance)
            saved = form.save()
            ContentChangeLog.objects.create(
                actor=request.user, object_type='course', object_id=saved.pk,
                object_label=saved.name, action=action,
                note=form.cleaned_data['note'],
            )
            record_revision(
                'course', saved, request.user, action, form.cleaned_data['note'],
            )
        messages.success(request, f'讲义系列“{saved.name}”已保存。')
        return redirect('review_workbench:course_edit', object_id=saved.pk)
    return render(request, 'review_workbench/lecture_editor.html', {
        'form': form, 'object': instance, 'kind': 'course',
    })


@reviewer_required
def document_edit(request, object_id=None):
    instance = get_object_or_404(Document, pk=object_id) if object_id else None
    form = DocumentWorkbenchForm(request.POST or None, instance=instance)
    if request.method == 'POST' and form.is_valid():
        with transaction.atomic():
            action = 'create' if instance is None else 'update'
            if instance is not None:
                baseline_instance = Document.objects.select_for_update().get(
                    pk=instance.pk
                )
                ensure_baseline_revision('document', baseline_instance)
            saved = form.save()
            ContentChangeLog.objects.create(
                actor=request.user, object_type='document', object_id=saved.pk,
                object_label=saved.title, action=action,
                note=form.cleaned_data['note'],
            )
            record_revision(
                'document', saved, request.user, action, form.cleaned_data['note'],
            )
        messages.success(request, f'讲义“{saved.title}”已保存，等待下一版发布。')
        return redirect('review_workbench:document_edit', object_id=saved.pk)
    return render(request, 'review_workbench/lecture_editor.html', {
        'form': form, 'object': instance, 'kind': 'document',
    })


@reviewer_required
def revision_list(request, category):
    if category not in CATEGORY_TYPES:
        return HttpResponseForbidden('未知内容分类。')
    label, content_types = CATEGORY_TYPES[category]
    queryset = WorkbenchRevision.objects.filter(
        content_type__in=content_types,
    ).select_related('actor')
    page = Paginator(queryset, 40).get_page(request.GET.get('page'))
    return render(request, 'review_workbench/revision_list.html', {
        'category': category,
        'category_label': label,
        'revisions': page.object_list,
        'page': page,
    })


@reviewer_required
def revision_diff(request, category, revision_id):
    if category not in CATEGORY_TYPES:
        return HttpResponseForbidden('未知内容分类。')
    label, content_types = CATEGORY_TYPES[category]
    revision = get_object_or_404(
        WorkbenchRevision.objects.select_related('actor'),
        pk=revision_id, content_type__in=content_types,
    )
    previous = previous_revision(revision)
    return render(request, 'review_workbench/revision_diff.html', {
        'category': category,
        'category_label': label,
        'revision': revision,
        'previous': previous,
        'field_diffs': field_diffs(previous, revision),
    })


@reviewer_required
def releases(request):
    result = None
    if request.method == 'POST':
        db_type = request.POST.get('db_type', '')
        action = request.POST.get('action', '')
        if action not in {'candidate', 'publish'}:
            return HttpResponseForbidden('未知发布操作。')
        if action == 'publish' and not request.user.has_perm(PUBLISH_CONTRIBUTION):
            return HttpResponseForbidden('当前账号没有内容发布权限。')
        try:
            result = publish(db_type) if action == 'publish' else build_candidate(db_type)
        except Exception as error:
            messages.error(request, f'操作失败：{error}')
        else:
            verb = '发布' if action == 'publish' else '候选构建'
            messages.success(request, f'{verb}成功：v{result["data_version"]}')
    return render(request, 'review_workbench/releases.html', {
        'versions': {item.db_type: item for item in DbVersion.objects.all()},
        'result': result,
        'can_publish': request.user.has_perm(PUBLISH_CONTRIBUTION),
    })


TRAINING_STEPS = (
    'submit', 'claim', 'return', 'resubmit',
    'approve', 'candidate', 'release', 'verify',
)


@reviewer_required
def training(request):
    progress, _ = ReviewerTrainingProgress.objects.get_or_create(
        reviewer=request.user
    )
    done = progress.completed_steps
    if request.method == 'POST':
        step = request.POST.get('step')
        if step == 'reset':
            done = []
        elif step in TRAINING_STEPS:
            index = TRAINING_STEPS.index(step)
            if index == 0 or TRAINING_STEPS[index - 1] in done:
                done = list(dict.fromkeys([*done, step]))
        progress.completed_steps = done
        progress.save(update_fields=['completed_steps', 'updated_at'])
        return redirect('review_workbench:training')
    steps = [
        {'key': key, 'enabled': index == 0 or TRAINING_STEPS[index - 1] in done}
        for index, key in enumerate(TRAINING_STEPS)
    ]
    return render(request, 'review_workbench/training.html', {
        'steps': steps, 'done': done,
        'case_id': TRAINING_CASE_ID,
        'initial_json': json.dumps(
            TRAINING_INITIAL_PAYLOAD, ensure_ascii=False, indent=2
        ),
        'expected': TRAINING_EXPECTED,
    })


@reviewer_required
def training_json(request):
    body = json.dumps(TRAINING_INITIAL_PAYLOAD, ensure_ascii=False, indent=2)
    response = HttpResponse(body + '\n', content_type='application/json; charset=utf-8')
    response['Content-Disposition'] = (
        f'attachment; filename="reviewer-training-{TRAINING_CASE_ID}.json"'
    )
    return response
