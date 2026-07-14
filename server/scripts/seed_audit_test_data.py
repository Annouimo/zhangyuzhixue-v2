"""为「审计测试」用户创建丰富的测试数据。
用法:  python scripts/seed_audit_test_data.py
"""
import os, sys, random
from datetime import date, timedelta

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'math_platform.settings')
os.environ['DJANGO_ALLOW_ASYNC_UNSAFE'] = 'true'

import django; django.setup()
from django.contrib.auth.models import User
from django.utils import timezone
from accounts.models import Student, UserLoginLog
from qbank.models import BaseQuestion, SubQuestion, SolutionMethod, SolutionStep, ChoiceExt
from courses.models import Assignment, AssignmentQuestion, Course, ClassGroup, ClassCourse, ClassCourseAssignment
from interactions.models import StudentSubmission, SubmissionDetail, StepFeedback, CardFeedback, QuestionRating, CustomPaper, CustomPaperQuestion
from system.models import PointsTransaction, StudentAchievement, AchievementDef

random.seed(42)
username = '审计测试'
password = 'test123'

# ── 1. 用户 ──
u, created = User.objects.get_or_create(username=username, defaults={'first_name': '审计测试'})
if created:
    u.set_password(password)
    u.save()
    Student.objects.create(user=u, student_id='TEST999', school='测试学校', gaokao_year=2026)
    print(f'✅ 创建用户 {username}')
else:
    u.first_name = '审计测试'; u.save()
    print(f'✅ 用户已存在 {username} (id={u.id})')

student = Student.objects.get(user=u)

# ── 2. 班级/课程/作业 ──
group, _ = ClassGroup.objects.get_or_create(name='审计测试班')
if student not in group.students.all():
    group.students.add(student)
course = Course.objects.first()
cc, _ = ClassCourse.objects.get_or_create(class_group=group, course=course)

# 创建 3 份混合题型作业
all_questions = list(BaseQuestion.objects.all())
choices = [q for q in all_questions if q.question_type == 'choice']
fills = [q for q in all_questions if q.question_type == 'fill']
solutions = [q for q in all_questions if q.question_type == 'solution']

assignment_specs = [
    ('一轮-审计测试A', choices[:4] + fills[:2] + solutions[:2]),
    ('一轮-审计测试B', choices[4:8] + fills[2:4] + solutions[2:4]),
    ('二轮-审计测试C', choices[8:12] + fills[4:6] + solutions[4:6]),
]
for title, qs in assignment_specs:
    asst, _ = Assignment.objects.get_or_create(title=title, defaults={'course': course, 'description': f'{username}专用{title}'})
    if AssignmentQuestion.objects.filter(assignment=asst).count() == 0:
        for i, q in enumerate(qs):
            AssignmentQuestion.objects.create(assignment=asst, question=q, sort_order=i+1)
        ClassCourseAssignment.objects.get_or_create(class_course=cc, assignment=asst, defaults={'deadline': date(2026, 9, 30), 'is_active': True})
        print(f'  ✅ 作业 {title} ({len(qs)}题)')
    else:
        print(f'  ⏩ 作业 {title} 已存在')

# ── 3. 登录日志（连续 30 天签到） ──
login_count = UserLoginLog.objects.filter(student=student).count()
if login_count < 30:
    UserLoginLog.objects.filter(student=student).delete()
    today = timezone.now().date()
    for i in range(30):
        d = today - timedelta(days=29 - i)
        UserLoginLog.objects.create(student=student, login_date=d, created_at=timezone.make_aware(timezone.datetime(d.year, d.month, d.day, 8, 0)))
    print(f'  ✅ 登录日志 30 天')
else:
    print(f'  ⏩ 登录日志已存在')

# ── 4. 提交记录（50 题，覆盖三题型，含复访多 attempt） ──
existing_count = SubmissionDetail.objects.filter(submission__student=student).count()
if existing_count < 30:
    # 4a. 新建 submission header
    sub1, _ = StudentSubmission.objects.get_or_create(student=student, assignment=None, defaults={})
    sub2, _ = StudentSubmission.objects.get_or_create(student=student, assignment=None, defaults={})

    # 4b. 30 道选择题（各种状态）
    for i, q in enumerate(choices[:30]):
        created_at = timezone.now() - timedelta(days=random.randint(0, 29), hours=random.randint(0, 23))
        is_correct = random.choice([1, 0, 1, 1, 0])
        sub = sub1 if i < 15 else sub2
        detail, _ = SubmissionDetail.objects.get_or_create(
            submission=sub, question=q, attempt_number=1,
            defaults={
                'status': 'completed',
                'answer_text': random.choice(['A', 'B', 'C', 'D']),
                'is_correct': is_correct,
                'created_at': created_at, 'updated_at': created_at,
            })
        # 部分题有二次作答
        if i % 5 == 0:
            SubmissionDetail.objects.get_or_create(
                submission=sub, question=q, attempt_number=2,
                defaults={
                    'status': 'completed', 'answer_text': random.choice(['A', 'B', 'C', 'D']),
                    'is_correct': 1, 'created_at': created_at + timedelta(minutes=5),
                    'updated_at': created_at + timedelta(minutes=5),
                })
    print(f'  ✅ 选择题提交 30 题')

    # 4c. 15 道填空题
    for i, q in enumerate(fills[:15]):
        created_at = timezone.now() - timedelta(days=random.randint(0, 29), hours=random.randint(0, 23))
        sub = sub1 if i < 8 else sub2
        SubmissionDetail.objects.get_or_create(
            submission=sub, question=q, attempt_number=1,
            defaults={
                'status': 'completed',
                'answer_text': random.choice(['x=3', 'y=2', 'π/3', '(-∞,1]', '2√3']),
                'is_correct': random.choice([1, 1, 0]),
                'created_at': created_at, 'updated_at': created_at,
            })
    print(f'  ✅ 填空题提交 15 题')

    # 4d. 10 道解答题（含 step_feedback + card_feedback）
    for i, q in enumerate(solutions[:10]):
        created_at = timezone.now() - timedelta(days=random.randint(0, 29), hours=random.randint(0, 23))
        sub = sub1 if i < 5 else sub2
        detail, _ = SubmissionDetail.objects.get_or_create(
            submission=sub, question=q, attempt_number=1,
            defaults={
                'status': 'completed', 'answer_text': '解题过程...',
                'is_correct': random.choice([1, 0, 1]),
                'created_at': created_at, 'updated_at': created_at,
            })
        # 解题步骤反馈
        sub_questions = SubQuestion.objects.filter(question=q)
        for sq in sub_questions:
            methods = SolutionMethod.objects.filter(sub_question=sq)
            for m in methods:
                steps = SolutionStep.objects.filter(method=m).order_by('step_number')
                for s in steps[:random.randint(2, 4)]:  # 部分步骤有反馈
                    StepFeedback.objects.get_or_create(
                        submission_detail=detail, question=q, sub_question_index=sq.sort_order,
                        method_id=m.id, step_number=s.step_number,
                        defaults={'status': random.choice(['full_correct', 'partial_correct', 'wrong']),
                                  'created_at': created_at})
        # 部分题有卡片反馈
        if i % 3 == 0:
            CardFeedback.objects.get_or_create(
                submission_detail=detail, question=q, card_title='函数单调性',
                defaults={'card_status': random.choice(['mastered', 'understood']), 'created_at': created_at})
    print(f'  ✅ 解答题提交 10 题（含步骤/卡片反馈）')

    # 4e. 一道 in_progress 的题（模拟未完成）
    in_prog_q = solutions[0]
    SubmissionDetail.objects.get_or_create(
        submission=sub2, question=in_prog_q, attempt_number=3,
        defaults={'status': 'in_progress', 'created_at': timezone.now(), 'updated_at': timezone.now()})
    print(f'  ✅ 1 题进行中状态')
else:
    print(f'  ⏩ 提交记录已存在 ({existing_count})')

# ── 5. 评分（20 题） ──
rated = QuestionRating.objects.filter(student=student).count()
if rated < 20:
    for q in choices[:10] + fills[:5] + solutions[:5]:
        QuestionRating.objects.get_or_create(
            student=student, question=q,
            defaults={'difficulty_score': random.randint(3, 9), 'calculation_score': random.randint(2, 8),
                      'elegance_score': random.randint(1, 7)})
    print(f'  ✅ 评分 20 题')
else:
    print(f'  ⏩ 评分已存在 ({rated})')

# ── 6. 积分流水（全种类覆盖） ──
pts_count = PointsTransaction.objects.filter(student=student).count()
if pts_count < 50:
    PointsTransaction.objects.filter(student=student).delete()
    today = timezone.now()
    for day in range(30):
        # 每日签到
        PointsTransaction.objects.create(student=student, amount=random.choice([3, 5, 8]),
            transaction_type='EARN', source='LOGIN_BONUS',
            created_at=today - timedelta(days=day),
            description=f'签到奖励 (第{day+1}天)')
        # 随机做题奖励
        if random.random() > 0.3:
            PointsTransaction.objects.create(student=student, amount=random.choice([2, 3, 5]),
                transaction_type='EARN', source='PRACTICE_REWARD',
                created_at=today - timedelta(days=day, hours=random.randint(1, 12)),
                description='做题奖励')
        # 随机完成任务
        if random.random() > 0.6:
            PointsTransaction.objects.create(student=student, amount=random.choice([5, 10, 15]),
                transaction_type='EARN', source='TASK_REWARD',
                created_at=today - timedelta(days=day, hours=random.randint(1, 12)),
                description=f'完成任务奖励')
    # 新人赠送
    PointsTransaction.objects.create(student=student, amount=100,
        transaction_type='EARN', source='SIGNUP_BONUS',
        created_at=today - timedelta(days=60), description='新人注册赠送积分')
    # 退出评价
    PointsTransaction.objects.create(student=student, amount=5,
        transaction_type='EARN', source='REVIEW_REWARD',
        created_at=today - timedelta(days=3), description='退出页面评价奖励')
    # 组卷消费
    PointsTransaction.objects.create(student=student, amount=-20,
        transaction_type='SPEND', source='PAPER_PURCHASE',
        created_at=today - timedelta(days=7), description='组卷消费')
    PointsTransaction.objects.create(student=student, amount=-10,
        transaction_type='SPEND', source='PAPER_PURCHASE',
        created_at=today - timedelta(days=14), description='组卷消费')
    print(f'  ✅ 积分流水 ~60 条（全 6 种 source 覆盖）')
else:
    print(f'  ⏩ 积分已存在 ({pts_count})')

# ── 7. 组卷（公开+私密） ──
paper_count = CustomPaper.objects.filter(student=student).count()
if paper_count < 4:
    papers = [
        ('函数专题练习', True, choices[:5] + fills[:3]),
        ('高考模拟卷-A', True, choices[4:10] + fills[3:6] + solutions[:2]),
        ('导数压轴精选', False, solutions[:8]),
        ('错题重练', False, choices[10:15] + fills[6:8]),
    ]
    for title, is_pub, qs in papers:
        p = CustomPaper.objects.create(student=student, title=title,
            description=f'{username}的{title}', is_public=is_pub, view_count=random.randint(0, 50))
        for i, q in enumerate(qs):
            CustomPaperQuestion.objects.create(paper=p, question=q, sort_order=i+1)
        print(f'  ✅ 组卷 {title} ({"公开" if is_pub else "私密"}, {len(qs)}题)')
else:
    print(f'  ⏩ 组卷已存在 ({paper_count})')

# ── 8. 成就进度 ──
ach_count = StudentAchievement.objects.filter(student=student).count()
if ach_count < 5:
    defs = AchievementDef.objects.all()
    for d in defs[:5]:
        StudentAchievement.objects.get_or_create(
            student=student, achievement=d,
            defaults={'progress': random.randint(1, d.threshold or 10),
                      'is_unlocked': random.choice([True, False]),
                      'unlocked_at': timezone.now() - timedelta(days=random.randint(1, 30)) if random.random() > 0.5 else None})
    print(f'  ✅ 成就进度 5 条')
else:
    print(f'  ⏩ 成就已存在 ({ach_count})')

# ── 汇总 ──
print(f'\n{"="*60}')
print(f'  📋 {username} 测试数据汇总')
print(f'  👤 用户: {username} / {password}')
print(f'  📝 提交: {SubmissionDetail.objects.filter(submission__student=student).count()} 条')
print(f'  ✅ 完成: {SubmissionDetail.objects.filter(submission__student=student, status="completed").count()} 条')
print(f'  🏗️ 进行中: {SubmissionDetail.objects.filter(submission__student=student, status="in_progress").count()} 条')
print(f'  ⭐ 评分: {QuestionRating.objects.filter(student=student).count()} 条')
print(f'  💰 积分: {PointsTransaction.objects.filter(student=student).count()} 条')
print(f'  📊 组卷: {CustomPaper.objects.filter(student=student).count()} 个')
print(f'  🔥 签到: {UserLoginLog.objects.filter(student=student).count()} 天')
print(f'  🏆 成就: {StudentAchievement.objects.filter(student=student).count()} 条')
print(f'  📖 作业: {Assignment.objects.filter(course=course).count()} 份')
print(f'{"="*60}')
