from functools import wraps

from django.contrib.auth import login, logout
from django.db.models import Count
from django.http import HttpResponseForbidden
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from django.utils.http import url_has_allowed_host_and_scheme

from qbank.models import BaseQuestion, ConceptTag, KnowledgeCard

from .forms import PortalAuthenticationForm, has_portal_access
from .git_history import get_portal_history
from .models import BusinessArea, ProjectProfile


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
    context['sections'] = (
        page.sections.filter(is_visible=True)
        .prefetch_related('entries')
    )
    return context


@portal_member_required
def index(request):
    overview = get_object_or_404(BusinessArea, slug='overview', is_visible=True)
    context = _page_context(overview)
    context['project_pages'] = _navigation_pages()
    context['git_history'] = get_portal_history()
    return render(request, 'internal_portal/index.html', context)


def _question_overview():
    questions = BaseQuestion.objects.exclude(year=2099)
    type_counts = {
        row['question_type']: row['count']
        for row in questions.values('question_type').annotate(count=Count('id'))
    }
    return (
        ('题目总数', questions.count()),
        ('选择题', type_counts.get('choice', 0)),
        ('填空题', type_counts.get('fill', 0)),
        ('解答题', type_counts.get('solution', 0)),
        ('概念标签', ConceptTag.objects.count()),
        ('知识卡片', KnowledgeCard.objects.count()),
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
    if slug == 'software':
        context['question_overview'] = _question_overview()
    return render(request, 'internal_portal/page_detail.html', context)
