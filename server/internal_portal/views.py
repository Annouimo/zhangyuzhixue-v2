from functools import wraps

from django.contrib.auth import login, logout
from django.http import HttpResponseForbidden
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from django.utils.http import url_has_allowed_host_and_scheme

from .forms import PortalAuthenticationForm, has_portal_access
from .models import BusinessArea, ProjectProfile, TeamMember


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
        .prefetch_related('owners', 'entries')
    )
    context['members'] = TeamMember.objects.filter(is_active=True)
    return render(request, 'internal_portal/index.html', context)


@portal_member_required
def area_detail(request, slug):
    context = _shared_context()
    context['area'] = get_object_or_404(
        BusinessArea.objects.prefetch_related('owners'),
        slug=slug,
        is_visible=True,
    )
    context['entries'] = (
        context['area'].entries.filter(is_visible=True)
        .prefetch_related('owners')
    )
    if slug == 'team':
        context['members'] = TeamMember.objects.filter(is_active=True)
    return render(request, 'internal_portal/area_detail.html', context)
