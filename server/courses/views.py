"""讲义、视频 API 与公开视频落地页。"""
import logging
import re

from django.http import HttpResponse, HttpResponseNotFound
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_GET, require_POST
from drf_spectacular.utils import OpenApiResponse, extend_schema
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response

from accounts.permissions import IsStudent

from courses.models import Course, Document, Video, VideoCategory


logger = logging.getLogger(__name__)
_SOURCE_PATTERN = re.compile(r'^[a-zA-Z0-9_-]{1,32}$')
_LINK_EVENTS = {'open_app', 'download'}


def _ok(data=None, message='ok'):
    return Response({'code': 0, 'message': message, 'data': data})


def _safe_source(request):
    source = request.GET.get('from', '') or request.POST.get('source', '')
    return source if _SOURCE_PATTERN.fullmatch(source) else 'direct'


@require_GET
def public_video_landing(request, video_id):
    video = Video.objects.filter(
        id=video_id, is_published=True,
    ).select_related('category').first()
    if video is None:
        return HttpResponseNotFound('视频不存在或已下架')
    links = video.videodocumentlink_set.select_related(
        'document__course',
    ).order_by('sort_order', 'id')
    source = _safe_source(request)
    logger.info('video_landing_view video_id=%s source=%s', video.id, source)
    return render(request, 'courses/video_landing.html', {
        'video': video,
        'lecture_links': links,
        'source': source,
        'canonical_url': request.build_absolute_uri(request.path),
    })


@csrf_exempt
@require_POST
def public_video_link_event(request, video_id):
    event = request.POST.get('event', '')
    if event not in _LINK_EVENTS or not Video.objects.filter(
        id=video_id, is_published=True,
    ).exists():
        return HttpResponse(status=400)
    logger.info(
        'video_link_event video_id=%s event=%s source=%s',
        video_id, event, _safe_source(request),
    )
    return HttpResponse(status=204)


@extend_schema(
    responses={200: OpenApiResponse(description='课程列表')},
)
@api_view(['GET'])
@permission_classes([IsStudent])
def lecture_courses_list(request):
    """讲义系列仅对学生端账号开放。"""
    courses = Course.objects.all().order_by('id')

    data = [
        {'id': c.id, 'name': c.name, 'description': c.description}
        for c in courses
    ]
    return _ok(data=data)


@extend_schema(
    responses={200: OpenApiResponse(description='指定课程的章节列表（含 page_count）')},
)
@api_view(['GET'])
@permission_classes([IsStudent])
def chapter_list(request, course_id):
    """指定课程章节目录"""
    documents = Document.objects.filter(
        course_id=course_id
    ).order_by('chapter')

    items = []
    for doc in documents:
        page_count = doc.md_content.count('<!-- pagebreak -->') + 1 if doc.md_content else 1
        items.append({
            'id': doc.id,
            'title': doc.title,
            'page_count': page_count,
        })

    course = Course.objects.filter(id=course_id).values('name').first()
    return _ok(data={
        'course_name': course['name'] if course else '',
        'items': items,
    })


@extend_schema(
    responses={200: OpenApiResponse(description='讲义原始 Markdown 内容')},
)
@api_view(['GET'])
@permission_classes([IsStudent])
def chapter_content(request, chapter_id):
    """讲义内容（md_content 原样返回）"""
    try:
        doc = Document.objects.get(id=chapter_id)
    except Document.DoesNotExist:
        return Response({'code': 40401, 'message': '讲义不存在', 'data': None},
                        status=404)

    related_videos = doc.videos.filter(is_published=True).select_related(
        'category',
    ).order_by('videodocumentlink__sort_order', 'sort_order', 'id')
    return _ok(data={
        'chapter_id': doc.id,
        'title': doc.title,
        'md_content': doc.md_content,
        'course_id': doc.course_id,
        'chapter': doc.chapter,
        'updated_at': doc.updated_at,
        'related_videos': [
            {
                'id': video.id,
                'title': video.title,
                'category_name': video.category.name,
                'relation_label': video.videodocumentlink_set.get(
                    document=doc,
                ).relation_label,
            }
            for video in related_videos
        ],
    })


@extend_schema(responses={200: OpenApiResponse(description='视频分类及目录')})
@api_view(['GET'])
@permission_classes([IsStudent])
def video_list(request):
    categories = VideoCategory.objects.prefetch_related('videos').order_by(
        'sort_order', 'id',
    )
    data = []
    for category in categories:
        videos = category.videos.filter(is_published=True).order_by(
            'sort_order', '-published_at', 'id',
        )
        data.append({
            'id': category.id,
            'name': category.name,
            'description': category.description,
            'videos': [
                {
                    'id': video.id,
                    'title': video.title,
                    'description': video.description,
                    'cover_url': video.cover_url,
                    'platform_name': video.platform_name,
                    'published_at': video.published_at,
                }
                for video in videos
            ],
        })
    return _ok(data=data)


@extend_schema(responses={200: OpenApiResponse(description='视频详情及相关讲义')})
@api_view(['GET'])
@permission_classes([IsStudent])
def video_detail(request, video_id):
    video = Video.objects.filter(
        id=video_id, is_published=True,
    ).select_related('category').first()
    if video is None:
        return Response(
            {'code': 40402, 'message': '视频不存在', 'data': None},
            status=404,
        )
    links = video.videodocumentlink_set.select_related(
        'document__course',
    ).order_by('sort_order', 'id')
    return _ok(data={
        'id': video.id,
        'title': video.title,
        'description': video.description,
        'cover_url': video.cover_url,
        'platform_name': video.platform_name,
        'video_url': video.video_url,
        'published_at': video.published_at,
        'category': {'id': video.category_id, 'name': video.category.name},
        'related_lectures': [
            {
                'chapter_id': link.document_id,
                'title': link.document.title,
                'course_name': link.document.course.name,
                'relation_label': link.relation_label,
            }
            for link in links
        ],
    })
