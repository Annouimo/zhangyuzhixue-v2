"""讲义 API — 课程列表/章节目录/讲义内容"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from courses.models import ClassCourse, Course, Document


def _ok(data=None, message='ok'):
    return Response({'code': 0, 'message': message, 'data': data})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def lecture_courses_list(request):
    """课程列表 — 教师见全部，学生见自己班级的"""
    user = request.user

    if hasattr(user, 'teacher'):
        # 教师：全部课程
        courses = Course.objects.all()
    elif hasattr(user, 'student') and user.student.class_group_id:
        # 学生：班级绑定课程
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


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def chapter_list(request, course_id):
    """指定课程章节目录"""
    documents = Document.objects.filter(
        course_id=course_id
    ).values('id', 'chapter', 'title').distinct().order_by('chapter')

    data = [
        {
            'id': doc['id'],
            'chapter': doc['chapter'],
            'title': doc['title'],
        }
        for doc in documents
    ]
    return _ok(data=data)


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
        'id': doc.id,
        'course_id': doc.course_id,
        'chapter': doc.chapter,
        'title': doc.title,
        'content': doc.md_content,
        'updated_at': doc.updated_at,
    })
