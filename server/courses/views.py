"""讲义 API — 课程列表/章节目录/讲义内容"""
from drf_spectacular.utils import OpenApiResponse, extend_schema
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response

from accounts.permissions import IsStudent

from courses.models import Course, Document


def _ok(data=None, message='ok'):
    return Response({'code': 0, 'message': message, 'data': data})


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

    return _ok(data={
        'chapter_id': doc.id,
        'title': doc.title,
        'md_content': doc.md_content,
        'course_id': doc.course_id,
        'chapter': doc.chapter,
        'updated_at': doc.updated_at,
    })
