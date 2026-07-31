from functools import wraps

from django.contrib.auth import login, logout
from django.db.models import Count, Max, Prefetch
from django.http import HttpResponseForbidden
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from django.utils.http import url_has_allowed_host_and_scheme

from qbank.models import BaseQuestion, ConceptTag, ContentChangeLog, KnowledgeCard
from courses.models import Course, Document, Video
from system.models import DbVersion

from .forms import PortalAuthenticationForm, has_portal_access
from .lecture_rendering import render_lecture_markdown
from .models import BusinessArea, HandbookUpdate, PortalEntry, ProjectProfile


LEGACY_PAGE_REDIRECTS = {
    'product': 'software',
    'technology': 'software',
    'team': 'overview',
}


def portal_member_required(view_func):
    @wraps(view_func)
    def wrapped(request, *args, **kwargs):
        if not request.user.is_authenticated:
            login_url = reverse('internal_portal:login')
            return redirect(f'{login_url}?next={request.get_full_path()}')
        if not has_portal_access(request.user):
            return HttpResponseForbidden('当前账号没有访问项目中心的权限。')
        return view_func(request, *args, **kwargs)

    return wrapped


def _navigation_pages():
    return BusinessArea.objects.filter(is_visible=True).exclude(slug='overview')


def _shared_context():
    return {
        'profile': ProjectProfile.objects.first(),
        'navigation_areas': _navigation_pages(),
    }


def login_view(request):
    if has_portal_access(request.user):
        return redirect('internal_portal:index')

    form = PortalAuthenticationForm(request=request, data=request.POST or None)
    if request.method == 'POST' and form.is_valid():
        login(request, form.get_user())
        request.session.set_expiry(60 * 60 * 12)
        next_url = request.POST.get('next', '')
        if next_url and url_has_allowed_host_and_scheme(
            next_url, allowed_hosts={request.get_host()},
            require_https=request.is_secure(),
        ):
            return redirect(next_url)
        return redirect('internal_portal:index')

    return render(request, 'internal_portal/login.html', {
        'form': form,
        'next': request.GET.get('next', ''),
    })


def logout_view(request):
    if request.method == 'POST':
        logout(request)
        return redirect('internal_portal:login')
    return redirect('internal_portal:index')


def _page_context(page):
    context = _shared_context()
    context['area'] = page
    context['page_updated_at'] = page.updated_at
    sections = list(
        page.sections.filter(is_visible=True)
        .prefetch_related(Prefetch(
            'entries',
            queryset=PortalEntry.objects.filter(is_visible=True),
            to_attr='visible_entries',
        ))
    )
    for section in sections:
        section.has_entry_links = any(
            entry.url for entry in section.visible_entries
        )
    context['sections'] = sections
    if any(
        section.display_type == section.DisplayType.PROJECT_MAP
        for section in sections
    ):
        context['project_pages'] = _navigation_pages()
    if any(
        section.display_type == section.DisplayType.CHANGELOG
        for section in sections
    ):
        context['handbook_updates'] = HandbookUpdate.objects.all()
    if any(
        section.display_type == section.DisplayType.QUESTION_STATS
        for section in sections
    ):
        context['question_overview_groups'] = _question_overview()
    return context


@portal_member_required
def index(request):
    overview = get_object_or_404(BusinessArea, slug='overview', is_visible=True)
    context = _page_context(overview)
    return render(request, 'internal_portal/index.html', context)


def _question_overview():
    questions = BaseQuestion.objects.exclude(year=2099)
    type_counts = {
        row['question_type']: row['count']
        for row in questions.values('question_type').annotate(count=Count('id'))
    }
    return (
        ('题目数量', (
            ('题目总数', questions.count()),
            ('选择题', type_counts.get('choice', 0)),
            ('填空题', type_counts.get('fill', 0)),
            ('解答题', type_counts.get('solution', 0)),
        )),
        ('辅助内容', (
            ('概念标签', ConceptTag.objects.count()),
            ('知识卡片', KnowledgeCard.objects.count()),
        )),
    )


@portal_member_required
def page_detail(request, slug):
    if slug in LEGACY_PAGE_REDIRECTS:
        target = LEGACY_PAGE_REDIRECTS[slug]
        if target == 'overview':
            return redirect('internal_portal:index', permanent=True)
        return redirect('internal_portal:page-detail', slug=target, permanent=True)

    page = get_object_or_404(
        BusinessArea.objects.all(), slug=slug, is_visible=True,
    )
    if page.slug == 'overview':
        return redirect('internal_portal:index')
    context = _page_context(page)
    return render(request, 'internal_portal/page_detail.html', context)


def _lecture_context():
    context = _shared_context()
    context.update({'area': None, 'is_lecture_library': True})
    return context


@portal_member_required
def lecture_library(request, course_id=None):
    courses = Course.objects.annotate(
        document_count=Count('documents'),
        latest_document_at=Max('documents__updated_at'),
    ).order_by('name')
    selected_course = None
    documents = []
    if course_id is not None:
        selected_course = get_object_or_404(Course, pk=course_id)
        documents = list(
            selected_course.documents.order_by('chapter', 'pk')
        )
    context = _lecture_context()
    context.update({
        'courses': courses,
        'selected_course': selected_course,
        'documents': documents,
        'page_updated_at': (
            max((item.updated_at for item in documents), default=None)
            if selected_course else
            max((item.latest_document_at for item in courses), default=None)
        ),
    })
    return render(request, 'internal_portal/lecture_library.html', context)


@portal_member_required
def lecture_document(request, document_id):
    document = get_object_or_404(
        Document.objects.select_related('course'), pk=document_id,
    )
    documents = list(
        document.course.documents.order_by('chapter', 'pk')
    )
    index = next(i for i, item in enumerate(documents) if item.pk == document.pk)
    context = _lecture_context()
    context.update({
        'document': document,
        'documents': documents,
        'previous_document': documents[index - 1] if index else None,
        'next_document': (
            documents[index + 1] if index + 1 < len(documents) else None
        ),
        'rendered_content': render_lecture_markdown(document.md_content),
        'page_updated_at': document.updated_at,
    })
    return render(request, 'internal_portal/lecture_document.html', context)


@portal_member_required
def video_operations(request):
    videos = Video.objects.all()
    recent_changes = ContentChangeLog.objects.filter(
        object_type='video',
    ).select_related('actor')[:8]
    context = _shared_context()
    context.update({
        'area': None,
        'is_video_operations': True,
        'video_counts': {
            'total': videos.count(),
            'published': videos.filter(is_published=True).count(),
            'draft': videos.filter(is_published=False).count(),
        },
        'recent_video_changes': recent_changes,
        'courses_version': DbVersion.objects.filter(db_type='courses').first(),
        'page_updated_at': (
            recent_changes[0].created_at if recent_changes else None
        ),
    })
    return render(request, 'internal_portal/video_operations.html', context)
