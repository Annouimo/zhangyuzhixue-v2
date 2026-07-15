"""讲义 API — 课程列表/章节目录/讲义内容"""
from drf_spectacular.utils import OpenApiResponse, extend_schema
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from courses.models import ClassCourse, Course, Document


def _ok(data=None, message='ok'):
    return Response({'code': 0, 'message': message, 'data': data})


@extend_schema(
    responses={200: OpenApiResponse(description='课程列表')},
)
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def lecture_courses_list(request):
    """课程列表 — 学生见自己班级的"""
    user = request.user

    if hasattr(user, 'student') and user.student.class_group_id:
        class_courses = ClassCourse.objects.filter(
            class_group_id=user.student.class_group_id
        ).select_related('course')
        courses = [cc.course for cc in class_courses]
    else:
        courses = []

    data = [
        {'id': c.id, 'name': c.name, 'description': c.description}
        for c in courses
    ]
    return _ok(data=data)


@extend_schema(
    responses={200: OpenApiResponse(description='指定课程的章节列表（含 page_count）')},
)
@api_view(['GET'])
@permission_classes([IsAuthenticated])
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
@permission_classes([IsAuthenticated])
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
