"""创建 test_audit 用户的组卷测试数据。
用法 (本地测试):  python scripts/seed_test_papers.py
     (ECS 部署):  scp 脚本到服务器后运行
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'math_platform.settings')

import django  # noqa: E402
django.setup()

from django.contrib.auth.models import User  # noqa: E402
from accounts.models import Student  # noqa: E402
from interactions.models import (CustomPaper, CustomPaperQuestion)  # noqa: E402
from qbank.models import BaseQuestion  # noqa: E402


def main():
    try:
        user = User.objects.get(username='test_audit')
        student = Student.objects.get(user=user)
    except (User.DoesNotExist, Student.DoesNotExist):
        print("❌ test_audit 用户不存在，请先运行 create_test_audit_user.py")
        return

    # 检查是否已有数据
    existing = CustomPaper.objects.filter(student=student).count()
    if existing > 0:
        print(f"⚠️ test_audit 已有 {existing} 个组卷，跳过创建")
        return

    questions = list(BaseQuestion.objects.all())
    if not questions:
        print("❌ 题库为空")
        return

    print(f"题库: {len(questions)} 题")
    print(f"学生: {student} (id={student.pk})")

    papers_data = [
        {
            'title': '导数冲刺 20 题',
            'description': '精选导数专项练习，覆盖高考常见题型',
            'is_public': True,
            'question_indices': [0, 1, 2, 3, 4],
        },
        {
            'title': '三角函数专项训练',
            'description': '三角函数综合练习，含恒等变换与图像性质',
            'is_public': True,
            'question_indices': [5, 6, 7, 8, 9],
        },
        {
            'title': '期末冲刺卷',
            'description': '综合模拟测试',
            'is_public': False,
            'question_indices': [10, 11, 12, 13, 14],
        },
    ]

    for pd in papers_data:
        paper = CustomPaper.objects.create(
            student=student,
            title=pd['title'],
            description=pd['description'],
            is_public=pd['is_public'],
            view_count=0,
        )
        for i, qi in enumerate(pd['question_indices']):
            q = questions[qi % len(questions)]
            CustomPaperQuestion.objects.create(
                paper=paper,
                question=q,
                sort_order=i + 1,
            )
        print(f"  ✅ 创建组卷: {pd['title']} "
              f"({len(pd['question_indices'])}题, "
              f"{'公开' if pd['is_public'] else '私密'})")

    print(f"\n✅ 共创建 {len(papers_data)} 个组卷")
    print(f"   其中公开组卷: {sum(1 for p in papers_data if p['is_public'])} 个")


if __name__ == '__main__':
    main()
