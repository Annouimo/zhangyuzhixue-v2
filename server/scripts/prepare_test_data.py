"""
为 test_audit 准备测试数据：作业 + 他人公开组卷。

用法：
    python scripts/prepare_test_data.py          # 执行
    python scripts/prepare_test_data.py --dry    # 预览（不写数据）
"""
import os
import sys
from datetime import date

server_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, server_dir)
os.chdir(server_dir)
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'math_platform.settings')
os.environ['DJANGO_ALLOW_ASYNC_UNSAFE'] = 'true'

import django  # noqa: E402
django.setup()

from courses.models import (  # noqa: E402
    Assignment, AssignmentQuestion, ClassCourse,
    ClassCourseAssignment, ClassGroup, Course,
)
from accounts.models import Student  # noqa: E402
from interactions.models import CustomPaper, CustomPaperQuestion  # noqa: E402
from qbank.models import BaseQuestion  # noqa: E402


def main():
    dry_run = '--dry' in sys.argv

    ta = Student.objects.get(user__username='test_audit')
    zhang = Student.objects.get(user__username='stu_zhang')
    course = Course.objects.get(id=1)

    actions = []

    # 1. 班级
    group, _ = ClassGroup.objects.get_or_create(name='测试专用')
    if ta not in group.students.all():
        if not dry_run:
            group.students.add(ta)
        actions.append('ClassGroup "测试专用" + test_audit')

    # 2. 课程分配
    cc, created = ClassCourse.objects.get_or_create(class_group=group, course=course)
    if created:
        actions.append(f'ClassCourse id={cc.id}: {course.name} -> 测试专用')

    # 3. 作业（2份 x 6题，choice+fill+solution 混合）
    assignments = [
        ('一轮-测试作业A', [1, 2, 3, 11, 12, 16]),
        ('一轮-测试作业B', [4, 5, 6, 13, 14, 17]),
    ]
    for title, qids in assignments:
        desc = f'test_audit 专用 {title}'
        asst, ac = Assignment.objects.get_or_create(
            title=title, defaults={'course': course, 'description': desc})
        if ac:
            if not dry_run:
                for i, qid in enumerate(qids):
                    q = BaseQuestion.objects.get(id=qid)
                    AssignmentQuestion.objects.create(
                        assignment=asst, question=q, sort_order=i + 1)
                ClassCourseAssignment.objects.create(
                    class_course=cc, assignment=asst,
                    deadline=date(2026, 8, 31), is_active=True)
            msg = f'Assignment "{title}" ({len(qids)}题) + 发布'
            actions.append(msg)

    # 4. stu_zhang 公开组卷（2 choice + 2 fill + 2 solution）
    paper, pc = CustomPaper.objects.get_or_create(
        student=zhang, title='测试卷-来自stu_zhang',
        defaults={'description': '他人公开组卷', 'is_public': True})
    if pc:
        if not dry_run:
            for i, qid in enumerate([7, 8, 15, 18, 20, 21]):
                q = BaseQuestion.objects.get(id=qid)
                CustomPaperQuestion.objects.create(
                    paper=paper, question=q, sort_order=i + 1)
        actions.append('CustomPaper "测试卷-来自stu_zhang" (6题, is_public=True)')
    else:
        actions.append('CustomPaper "测试卷-来自stu_zhang" 已存在')

    mode = '预览' if dry_run else '执行'
    print(f'\n=== {mode} ===')
    for a in actions:
        print(f'  {a}')
    if not dry_run:
        print('\n数据准备完成')


if __name__ == '__main__':
    main()
