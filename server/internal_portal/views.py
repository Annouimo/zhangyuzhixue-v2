from functools import wraps

from django.contrib.auth import login, logout
from django.http import HttpResponseForbidden
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from django.utils.http import url_has_allowed_host_and_scheme

from .forms import PortalAuthenticationForm, has_portal_access
from .models import BusinessArea, PortalEntry, ProjectProfile, TeamMember


ENTRY_TYPE_ORDER = ('download', 'product', 'media', 'tool', 'document', 'service')


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


def _shared_context():
    return {
        'profile': ProjectProfile.objects.first(),
        'navigation_areas': BusinessArea.objects.filter(is_visible=True),
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


@portal_member_required
def index(request):
    context = _shared_context()
    context['areas'] = (
        BusinessArea.objects.filter(is_visible=True)
        .prefetch_related('entries')
    )
    context['members'] = TeamMember.objects.filter(is_active=True)
    quick_entry_names = (
        '学生端 Android', '学生端 Windows', '学生端 iOS',
        'Gitee 主仓库', 'Django 管理后台', '设计文档索引',
    )
    quick_entries = PortalEntry.objects.filter(
        is_visible=True, name__in=quick_entry_names,
    )
    quick_entry_map = {entry.name: entry for entry in quick_entries}
    context['quick_entries'] = [
        quick_entry_map[name] for name in quick_entry_names
        if name in quick_entry_map
    ]
    return render(request, 'internal_portal/index.html', context)


@portal_member_required
def area_detail(request, slug):
    context = _shared_context()
    context['area'] = get_object_or_404(
        BusinessArea.objects.all(),
        slug=slug,
        is_visible=True,
    )
    entries = list(
        context['area'].entries.filter(is_visible=True)
    )
    entry_groups = []
    for entry_type in ENTRY_TYPE_ORDER:
        grouped_entries = [
            entry for entry in entries if entry.entry_type == entry_type
        ]
        if grouped_entries:
            entry_groups.append({
                'label': grouped_entries[0].get_entry_type_display(),
                'entries': grouped_entries,
                'show_status': any(
                    entry.status != 'active' for entry in grouped_entries
                ),
            })
    context['entry_groups'] = entry_groups
    if slug == 'team':
        context['members'] = TeamMember.objects.filter(is_active=True)
    return render(request, 'internal_portal/area_detail.html', context)
