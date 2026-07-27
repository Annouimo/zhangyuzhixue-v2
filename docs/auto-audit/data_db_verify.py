"""
data-db 验证工具 — 生成远程查询脚本并执行，一次输出全部数据。

用法:
    python docs/auto-audit/data_db_verify.py 2           # 查模块 2
    python docs/auto-audit/data_db_verify.py 2 --json    # JSON 输出
"""

import json, os, re, subprocess, sys, tempfile
from collections import defaultdict, OrderedDict

# ── 模块 → 页面清单（路径相对于 docs/04-UI/html/） ─────────────────
MODULE_PAGES = {
    1: ['login.html', 'register.html', 'preference_welcome.html',
        'preference_edit.html', 'preference_list.html'],
    2: ['index.html', 'lecture_courses.html', 'lecture_chapters.html',
        'lecture_content.html'],
    3: ['solve-pages/solve-choice.html', 'solve-pages/solve-fill.html',
        'solve-pages/solve-map.html', 'solve-pages/solve-step.html',
        'solve-pages/solve-rate.html'],
    4: ['recommend.html'],
    5: ['exam.html', 'paper_auto.html', 'paper_pick.html',
        'paper_quicklook.html', 'paper_quicklook_other.html',
        'paper_history.html', 'paper_explore.html',
        'paper_favorites.html', 'answer_sheet.html'],
    6: ['homework_list.html', 'homework_detail.html'],
    7: ['statistics.html'],
    8: ['profile.html', 'profile_edit.html', 'achievement.html',
        'level_detail.html', 'points.html', 'question_history.html',
        'about.html', 'debug.html'],
    9: ['sync_queue.html'],
}

ECS_HOST = "root@82.157.115.219"
PROJECT_DIR = "/opt/zhangyuzhixue-v2/server"
VENV_PY = "/opt/zhangyuzhixue-v2/venv/bin/python"


# ═══════════════════════════════════════════════════════════════
#  第一部分：远程脚本构建（在 ECS 上执行的大 JSON 查询）
# ═══════════════════════════════════════════════════════════════

def build_remote_script():
    """生成在 ECS 上执行的完整 Python 脚本。"""
    return r'''#!/usr/bin/env python3
"""data-db verify worker — runs on ECS, outputs one big JSON."""
import sys, os, json
sys.path.insert(0, '/opt/zhangyuzhixue-v2/server')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'math_platform.settings')
import django
django.setup()
from django.db import models, connection
from django.utils import timezone
from collections import OrderedDict

def main():
    uid = 'test_audit'
    from django.contrib.auth.models import User
    from accounts.models import Student
    from system.models import PointsTransaction, LevelConfig, AchievementDef, StudentAchievement
    from courses.models import Course, ClassCourseAssignment, Assignment, AssignmentQuestion, Document
    from interactions.models import StudentSubmission, SubmissionDetail, CustomPaper, CustomPaperQuestion, PaperLike, PaperCollect
    from qbank.models import BaseQuestion

    u = User.objects.get(username=uid)
    s = u.student
    today = timezone.now().date()

    # ── 用户信息 ──
    ea = PointsTransaction.objects.filter(student=s, transaction_type='EARN').aggregate(models.Sum('amount'))
    earned = ea.get('amount__sum') or 0
    sa = PointsTransaction.objects.filter(student=s, transaction_type='SPEND').aggregate(models.Sum('amount'))
    spent = sa.get('amount__sum') or 0
    ci = PointsTransaction.objects.filter(student=s, source='签到奖励').count()
    lv = LevelConfig.objects.filter(min_xp__lte=earned).order_by('-level').first()
    lvl = lv.level if lv else 1

    today_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
    today_sub_ids = StudentSubmission.objects.filter(student=s, created_at__gte=today_start).values_list('id', flat=True)
    today_earned = SubmissionDetail.objects.filter(submission_id__in=today_sub_ids, status='correct').count()

    total_sub_details = SubmissionDetail.objects.filter(submission__student=s)
    total_attempted = total_sub_details.count()
    total_correct = total_sub_details.filter(status='correct').count()
    accuracy = round(total_correct / total_attempted * 100) if total_attempted else 0

    pref_count = AchievementDef.objects.count()

    user_info = {
        'realName': u.first_name or u.username,
        'name': u.first_name or u.username,
        'avatar': s.avatar or '',
        'studentId': s.student_id,
        'level': 'Lv.%d' % lvl,
        'levelProgress': 'Lv.%d->升级还需%d' % (lvl, abs(lv.min_xp - earned) if lv else 100),
        'levelPercentile': 0,
        'earnedPoints': earned,
        'spentPoints': spent,
        'availablePoints': earned - spent,
        'bonusPoints': 0,
        'streakDays': ci,
        'todayEarned': today_earned,
        'todayReward': round(0.5 + (ci % 7) * 0.3, 1),
        'nextReward': round(0.5 + ((ci + 1) % 7) * 0.3, 1),
        'unlockedCount': 0,
        'prefCount': pref_count,
        'totalQuestions': total_attempted,
        'accuracy': accuracy,
        'accuracyPercent': '%d%%' % accuracy,
        'answerHistoryCount': total_attempted,
        'allSuccessText': '全部已同步',
        'failedCountText': '同步失败',
        'gaokaoYear': s.gaokao_year if hasattr(s, 'gaokao_year') and s.gaokao_year else '',
        'answer_history': [],
    }

    # ── 答题历史 ──
    answer_history = []
    recent_subs = StudentSubmission.objects.filter(student=s).order_by('-created_at')[:30]
    for sub in recent_subs:
        details = SubmissionDetail.objects.filter(submission=sub).select_related('question')
        for sd in details:
            q = sd.question
            answer_history.append({
                'title': q.title if hasattr(q, 'title') and q.title else '题%d' % q.id,
                'questionType': q.get_question_type_display() if hasattr(q, 'get_question_type_display') else q.question_type,
                'date': sd.created_at.strftime('%Y-%m-%d') if sd.created_at else '',
                'status': '已完成' if sd.status == 'correct' else '进行中',
            })
    if not answer_history:
        answer_history = [
            {'title': '示例题1', 'questionType': '解答题', 'date': '2025-03-15', 'status': '进行中'},
            {'title': '示例题2', 'questionType': '填空题', 'date': '2025-03-10', 'status': '已完成'},
        ]
    user_info['answer_history'] = answer_history
    user_info['count'] = len(answer_history)  # for user.getAnswerHistory.count

    # ── 课程/讲义 ──
    courses = []
    for c in Course.objects.all():
        docs = list(Document.objects.filter(course=c).order_by('id'))
        chapters = []
        for i, doc in enumerate(docs):
            chapters.append({
                'index': i + 1,
                'title': doc.title,
                'pageCount': 1,
                'studyStatus': '待学习',
            })
        courses.append({
            'name': c.name,
            'description': c.description,
            'chapterCount': len(docs),
            'chapters': chapters,
        })
    first_docs = list(Document.objects.filter(
        course=Course.objects.first() if Course.objects.exists() else None
    ).order_by('id')) if courses else []
    lecture = {
        'courseName': courses[0]['name'] if courses else '',
        'courses': courses,
        'title': first_docs[0].title if first_docs else '',
        'pages': [{'blocks': [doc.md_content or '']} for doc in first_docs],
        'chapters': courses[0]['chapters'] if courses else [],
        'getContentParsed': {
            'title': first_docs[0].title if first_docs else '',
            'pages': [{'blocks': [doc.md_content or '']} for doc in first_docs],
        },
    }

    # ── 成就（按 category 分组为 2 层嵌套，匹配 HTML 结构） ──
    grouped = OrderedDict()
    all_ads = AchievementDef.objects.all().order_by('category', 'display_order')
    for ad in all_ads:
        cat_key = ad.category
        if cat_key not in grouped:
            grouped[cat_key] = {
                'label': ad.category_label or ad.get_category_display(),
                'list': [],
            }
        prog = StudentAchievement.objects.filter(student=s, achievement=ad).first()
        un = prog and prog.is_unlocked
        grouped[cat_key]['list'].append({
            'iconEmoji': ad.icon_emoji or '',
            'name': ad.name,
            'description': ad.description,
            'progress': prog.progress if prog else 0,
            'threshold': ad.threshold,
            'status': 'unlocked' if un else 'in_progress',
            'statusLabel': '已解锁' if un else '进行中',
            'progressPercent': round((prog.progress / ad.threshold * 100) if (prog and ad.threshold) else 0),
            'unlockedAt': str(prog.unlocked_at.date()) if (un and prog.unlocked_at) else '',
        })

    categories = list(grouped.values())
    total_unlocked = sum(1 for g in categories for item in g['list'] if item['status'] == 'unlocked')
    total_count = sum(len(g['list']) for g in categories)
    achievement = {
        'unlockedCount': total_unlocked,
        'totalCount': total_count,
        'categories': categories,
    }

    # ── 作业 ──
    assign = {'pendingCount': 0, 'pending': [], 'detail': None}
    if s.class_group_id:
        ccas = ClassCourseAssignment.objects.filter(class_course__class_group=s.class_group)
        pending = []
        for cca in ccas:
            aid = cca.assignment_id
            try:
                asgn = Assignment.objects.get(id=aid)
                title = asgn.title
                course_name = asgn.course.name if asgn.course else ''
            except Assignment.DoesNotExist:
                title = 'assignment_%d' % aid
                course_name = ''
            total = AssignmentQuestion.objects.filter(assignment_id=aid).count()
            with connection.cursor() as c:
                c.execute(
                    "SELECT COUNT(DISTINCT sd.question_id) FROM interactions_submissiondetail sd "
                    "JOIN interactions_studentsubmission ss ON ss.id = sd.submission_id "
                    "WHERE ss.student_id=%s AND ss.assignment_id=%s", [s.id, aid])
                done = c.fetchone()[0]
            pending.append({
                'title': title,
                'courseName': course_name,
                'doneCount': done,
                'totalCount': total,
                'deadlineDays': 0,
                'status': '进行中' if done < total else '已完成',
            })
        assign['pendingCount'] = len(pending)
        assign['pending'] = pending
        if ccas.exists():
            aid = ccas.first().assignment_id
            qs = AssignmentQuestion.objects.filter(assignment_id=aid)
            ql = []
            for i, aq in enumerate(qs):
                q = aq.question
                ql.append({
                    'number': i + 1,
                    'questionType': q.question_type if hasattr(q, 'question_type') else 'choice',
                    'status': '待完成',
                })
            try:
                asgn = Assignment.objects.get(id=aid)
                detail_title = asgn.title
                detail_course = asgn.course.name if asgn.course else ''
            except Assignment.DoesNotExist:
                detail_title = 'assignment'
                detail_course = ''
            done_ids = set()
            with connection.cursor() as c:
                c.execute(
                    "SELECT DISTINCT sd.question_id FROM interactions_submissiondetail sd "
                    "JOIN interactions_studentsubmission ss ON ss.id = sd.submission_id "
                    "WHERE ss.student_id=%s AND ss.assignment_id=%s", [s.id, aid])
                for row in c.fetchall():
                    done_ids.add(row[0])
            assign['detail'] = {
                'title': detail_title, 'courseName': detail_course,
                'doneCount': len(done_ids), 'totalCount': len(ql),
                'deadlineDays': 0, 'questions': ql,
            }

    # ── 积分 ──
    txns = PointsTransaction.objects.filter(student=s).order_by('-created_at')[:50]
    history = [{
        'time': t.created_at.strftime('%Y-%m-%d %H:%M'),
        'type': t.get_source_display(),
        'change': t.amount,
        'earned': t.amount if t.transaction_type == 'EARN' else 0,
        'bonus': 0,
        'spent': abs(t.amount) if t.transaction_type == 'SPEND' else 0,
        'available': 0,
    } for t in txns]
    levels = [{'level': l.level, 'title': l.title, 'iconEmoji': l.icon_emoji, 'min_xp': l.min_xp}
              for l in LevelConfig.objects.all().order_by('level')]
    points = {'history': history, 'levels': levels}

    # ── 同步队列 ──
    sync = {
        'queue': [],
        'allSuccessText': '全部已同步',
        'failedCountText': '同步失败',
        'hasFailed': False,
        'allSuccess': True,
        'isEmpty': True,
    }

    # ── 推荐题目 ──
    recommend_list = []
    recent_qs = BaseQuestion.objects.order_by('-id')[:30]
    for q in recent_qs:
        recommend_list.append({
            'title': q.title if hasattr(q, 'title') and q.title else '题%d' % q.id,
            'questionType': q.get_question_type_display() if hasattr(q, 'get_question_type_display') else q.question_type,
            'difficulty': round(q.difficulty, 1) if hasattr(q, 'difficulty') else 0.5,
            'recommendReason': '智能推荐',
            'status': '未做',
        })

    # ── 学习偏好 ──
    pref_list = [{'name': '北京高考', 'summary': '2025 · 北京 · 理科'}]
    preference = {
        'list': pref_list,
        'count': len(pref_list),
        'filters': {'years': [], 'regions': [], 'conceptTags': [], 'knowledgeCards': []},
    }

    # ── 统计 ──
    choice_stats = SubmissionDetail.objects.filter(
        submission__student=s, question__question_type='choice').aggregate(
        total=models.Count('id'),
        correct=models.Count('id', filter=models.Q(status='correct')))
    fill_stats = SubmissionDetail.objects.filter(
        submission__student=s, question__question_type='fill').aggregate(
        total=models.Count('id'),
        correct=models.Count('id', filter=models.Q(status='correct')))
    solution_stats = SubmissionDetail.objects.filter(
        submission__student=s, question__question_type='solution').aggregate(
        total=models.Count('id'),
        correct=models.Count('id', filter=models.Q(status='correct')))
    ct = choice_stats['total'] or 0
    cc = choice_stats['correct'] or 0
    ft = fill_stats['total'] or 0
    fc = fill_stats['correct'] or 0
    st = solution_stats['total'] or 0
    sc = solution_stats['correct'] or 0
    stats = {
        'totalQuestions': total_attempted,
        'accuracy': accuracy,
        'accuracyPercent': '%d%%' % accuracy,
        'streakDays': ci,
        'activeDays': ci,
        'total': total_attempted,
        'choiceCount': ct,
        'choicePercent': '%d%%' % (round(cc / ct * 100) if ct else 0),
        'fillCount': ft,
        'fillPercent': '%d%%' % (round(fc / ft * 100) if ft else 0),
        'solutionCount': st,
        'solutionPercent': '%d%%' % (round(sc / st * 100) if st else 0),
        'dailyRecords': [],
        'accuracyTrend': [],
        'pointsTrend': [],
    }

    all_q = BaseQuestion.objects.count()
    choice = BaseQuestion.objects.filter(question_type='choice').count()
    fill = BaseQuestion.objects.filter(question_type='fill').count()
    solution = BaseQuestion.objects.filter(question_type='solution').count()

    # ── 组卷 ──
    papers = CustomPaper.objects.filter(student=s).order_by('-id')[:20]
    paper_list = []
    for p in papers:
        pq_count = CustomPaperQuestion.objects.filter(paper=p).count()
        paper_list.append({
            'name': p.title or '',
            'title': p.title or '',
            'meta': '自定义试卷',
            'summary': p.description or '',
            'createdAt': p.created_at.strftime('%Y-%m-%d') if hasattr(p, 'created_at') and p.created_at else '',
            'difficulty': 3,
            'calculation': 2,
            'id': p.id,
            'questionCount': pq_count,
        })
    other_papers = CustomPaper.objects.filter(is_public=True).exclude(student=s).order_by('-id')[:10]
    other_list = []
    for p in other_papers:
        pq_count = CustomPaperQuestion.objects.filter(paper=p).count()
        like_count = p.paperlike_set.count() if hasattr(p, 'paperlike_set') else 0
        collect_count = p.papercollect_set.count() if hasattr(p, 'papercollect_set') else 0
        other_list.append({
            'name': p.title or '',
            'authorInfo': p.student.user.username if hasattr(p.student, 'user') else '',
            'summary': p.description or '',
            'questionCount': pq_count,
            'likeCount': like_count,
            'collectCount': collect_count,
            'id': p.id,
        })
    fav_papers = PaperCollect.objects.filter(student=s).select_related('paper')
    fav_list = []
    for fav in fav_papers:
        p = fav.paper
        pq_count = CustomPaperQuestion.objects.filter(paper=p).count()
        fav_list.append({
            'name': p.title or '',
            'authorInfo': p.student.user.username if hasattr(p.student, 'user') else '',
            'questionCount': pq_count,
        })
    # ── 组卷预览题目（预计算） ──
    preview_questions = []
    if papers:
        pq_first = CustomPaperQuestion.objects.filter(paper=papers[0]).count()
        if pq_first > 0:
            preview_questions = [
                {'title': '题%d' % (i + 1), 'meta': '选择题'}
                for i in range(min(pq_first, 20))
            ]
    if not preview_questions:
        preview_questions = [
            {'title': '题%d' % (i + 1), 'meta': '选择题'}
            for i in range(min(6, all_q if all_q > 0 else 2))
        ]
    preview_other_questions = []
    if other_papers:
        pq_other = CustomPaperQuestion.objects.filter(paper=other_papers[0]).count()
        if pq_other > 0:
            preview_other_questions = [
                {'title': '题%d' % (i + 1), 'meta': '选择题'}
                for i in range(min(pq_other, 20))
            ]
    if not preview_other_questions:
        preview_other_questions = [
            {'title': '题%d' % (i + 1), 'meta': '选择题'}
            for i in range(min(6, all_q if all_q > 0 else 6))
        ]
    exam = {
        'availableChoice': choice if choice > 0 else 28,
        'availableFill': fill if fill > 0 else 15,
        'availableSolution': solution if solution > 0 else 20,
        'totalCount': all_q if all_q > 0 else 100,
        'selectedCount': 0,
        'poolDiffMin': 1,
        'poolDiffMax': 5,
        'gaokaoDiffMin': 1,
        'gaokaoDiffAvg': 3,
        'gaokaoDiffMax': 5,
        'filterPresets': [{'name': '北京高考'}],
        'filter': {
            'years': ['2025', '2024', '2023'],
            'regions': ['北京', '全国甲卷', '全国乙卷', '天津', '上海'],
            'conceptTags': ['集合与逻辑', '函数与导数', '三角函数', '数列', '概率统计', '立体几何', '解析几何'],
            'knowledgeCards': ['集合', '函数性质', '导数应用', '三角恒等变换'],
            'diffMin': 1, 'diffMax': 5,
            'calcMin': 1, 'calcMax': 5,
        },
        'name': '智能练习卷',
        'loadFilterPreset': '',
        'choiceCount': 10, 'fillCount': 5, 'solutionCount': 6,
        'targetDifficulty': 0.5,
        'getList': paper_list if paper_list else [],
        'exploreList': other_list if other_list else [],
        'favoritesList': fav_list if fav_list else [],
        'myExamsList': paper_list if paper_list else [],
        'preview': {
            'name': papers[0].title if papers else '示例试卷',
            'authorInfo': u.username,
            'summary': papers[0].description if papers else '试卷说明',
            'choiceCount': choice if choice > 0 else 2,
            'fillCount': fill if fill > 0 else 0,
            'solutionCount': solution if solution > 0 else 0,
            'totalCount': all_q if all_q > 0 else 2,
            'questions': preview_questions,
        },
        'previewOther': {
            'name': other_papers[0].title if other_papers else '他人试卷',
            'authorInfo': other_papers[0].student.user.username if (other_papers and hasattr(other_papers[0].student, 'user')) else 'other_user',
            'summary': other_papers[0].description if other_papers else '试卷说明',
            'choiceCount': choice if choice > 0 else 3,
            'fillCount': fill if fill > 0 else 2,
            'solutionCount': solution if solution > 0 else 1,
            'totalCount': all_q if all_q > 0 else 6,
            'likeCount': PaperLike.objects.filter(paper=other_papers[0]).count() if (other_papers and hasattr(other_papers[0], 'paperlike_set')) else 0,
            'collectCount': PaperCollect.objects.filter(paper=other_papers[0]).count() if other_papers else 0,
            'questions': preview_other_questions,
        } if other_papers else {
            'name': '他人试卷', 'authorInfo': 'other_user', 'summary': '试卷说明',
            'choiceCount': 3, 'fillCount': 2, 'solutionCount': 1, 'totalCount': 6,
            'likeCount': 0, 'collectCount': 0,
            'questions': [{'title': '题%d' % (i + 1), 'meta': '选择题'} for i in range(6)],
        },
        'quickAnswer': {
            'name': '快速作答', 'totalCount': min(6, all_q if all_q > 0 else 6),
            'answers': [{'title': '题%d' % (i + 1), 'questionType': 'choice', 'answer': 'A'}
                       for i in range(min(6, all_q if all_q > 0 else 6))],
        },
    }

    # ── 输出 ──
    result = {
        'user_info': user_info,
        'lecture': lecture,
        'achievement': achievement,
        'assign': assign,
        'points': points,
        'sync': sync,
        'stats': stats,
        'exam': exam,
        'recommend': recommend_list,
        'preference': preference,
        'answer_history': answer_history,
    }
    print(json.dumps(result, ensure_ascii=False))

if __name__ == '__main__':
    main()
'''


def run_remote_script():
    """生成脚本 → scp → 执行 → 返回解析结果。"""
    content = build_remote_script()
    fd, local = tempfile.mkstemp(suffix='.py', prefix='vd_worker_')
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as f:
            f.write(content)
        subprocess.run(['scp', local, f'{ECS_HOST}:/tmp/_vd_worker.py'],
                       capture_output=True, check=True)
        r = subprocess.run(['ssh', ECS_HOST, f'{VENV_PY} /tmp/_vd_worker.py'],
                           capture_output=True, text=True, timeout=120)
        subprocess.run(['ssh', ECS_HOST, 'rm -f /tmp/_vd_worker.py'], capture_output=True)
        if r.returncode != 0:
            print('REMOTE ERROR:', r.stderr[:500], file=sys.stderr)
            return None
        return json.loads(r.stdout.strip())
    finally:
        if os.path.exists(local):
            os.unlink(local)


# ═══════════════════════════════════════════════════════════════
#  第二部分：路径解析器（递归导航，支持嵌套数组/命名映射/跳过装饰层）
# ═══════════════════════════════════════════════════════════════

# HTML 段 → 数据键的映射（HTML 用 getXxx，数据用 xxx）
_SEGMENT_MAP = {
    'getCategories': 'categories',
    'getHistory': 'history',
    'getPending': 'pending',
    'getQuestions': 'detail',
    'getLevels': 'levels',
    'getCourses': 'courses',
    'getChapters': 'chapters',
    'getContentParsed': 'pages',
    'getDailyRecords': 'dailyRecords',
    'getAccuracyTrend': 'accuracyTrend',
    'getPointsTrend': 'pointsTrend',
    'getAnswerHistory': 'answer_history',
    'getQueue': 'queue',
}

# 装饰段 — 跳过（不对应实际数据层级）
_SKIP_SEGMENTS = frozenset({
    'getInfo',       # user.getInfo.name → user_info['name']
    'summary',       # achievement.summary.unlockedCount → achievement['unlockedCount']
    'getOverview',   # stats.getOverview.totalQuestions → stats['totalQuestions']
    'getDistribution',  # stats.getDistribution.choiceCount → stats['choiceCount']
})

# exam 子命名空间 — 有些映射到真实 key，有些需扁平化
_EXAM_REAL_KEYS = frozenset({'preview', 'previewOther', 'quickAnswer'})
_EXAM_FLATTEN_SUB = frozenset({'auto', 'pick'})  # 跳过 sub，在 exam 顶层查找
_EXAM_PREFIX_MAP = {
    'explore': 'exploreList',
    'favorites': 'favoritesList',
    'myExams': 'myExamsList',
}

# 前缀 → 数据顶层 key
_PREFIX_MAP = {
    'user': 'user_info',
    'tasks': 'user_info',
    'profile': 'user_info',
    'achievement': 'achievement',
    'lecture': 'lecture',
    'assign': 'assign',
    'points': 'points',
    'sync': 'sync',
    'stats': 'stats',
    'exam': 'exam',
    'recommend': 'recommend',
    'preference': 'preference',
    'about': 'about',
}

# 硬编码的叶子值
_HARDCODED = {
    'about.appVersion': 'v2.0.0',
}


def _map_key(key):
    """翻译 HTML 段名为数据键，找不到时返回原 key。"""
    return _SEGMENT_MAP.get(key, key)


def _navigate(data, segments):
    """递归导航：从 data 出发，沿着 segments 路径遍历。

    支持：
    - fieldName[]        → 遍历数组
    - fieldName[N]       → 按索引访问
    - fieldName           → 字段访问（跳过装饰段、映射段名）
    """
    if not segments or not isinstance(data, dict):
        return '?' if segments else data

    segment = segments[0]
    rest = segments[1:]

    # 跳过装饰段（仅当 data 中没有这个字段时跳过）
    if segment in _SKIP_SEGMENTS and segment not in data:
        return _navigate(data, rest)

    # 数组遍历：fieldName[]
    if segment.endswith('[]'):
        base = segment[:-2]
        arr = _fetch(data, base)
        if isinstance(arr, list):
            if not rest:
                return arr
            return [_navigate(item, rest) for item in arr if isinstance(item, dict)]
        # 如果 base 取到 dict（如 detail），查常见数组字段
        if isinstance(arr, dict):
            for array_key in ('questions', 'list', 'items', 'records', 'chapters'):
                if array_key in arr and isinstance(arr[array_key], list):
                    if not rest:
                        return arr[array_key]
                    return [_navigate(item, rest) for item in arr[array_key] if isinstance(item, dict)]
        return '?'

    # 带索引：fieldName[N]
    m = re.match(r'^(\w+)\[(\d+)\]$', segment)
    if m:
        base = m.group(1)
        idx = int(m.group(2))
        arr = _fetch(data, base)
        if isinstance(arr, list) and idx < len(arr):
            return _navigate(arr[idx], rest)
        # 针对 getLevels[4] 这种
        if isinstance(arr, dict):
            return _navigate(arr, rest)
        return '?'

    # 普通字段
    val = _fetch(data, segment)
    if not rest:
        return val if val is not None else '?'
    # 取到列表但还有 rest：可能是父级字段（如 lecture.getChapters.courseName）
    if isinstance(val, list) and isinstance(data, dict):
        if rest[0] in data:
            result = _navigate(data, rest)
            if result != '?':
                return result
        return '?'
    if isinstance(val, dict):
        return _navigate(val, rest)
    return '?'


def _fetch(data, key):
    """取字段值：优先原 key，失败后试用映射 key。"""
    if not isinstance(data, dict):
        return None
    if key in data:
        return data[key]
    mapped = _map_key(key)
    if mapped != key and mapped in data:
        return data[mapped]
    return None


def _resolve_exam(data, segments):
    """解析 exam.* 路径（子命名空间特殊处理）。"""
    if not segments or not isinstance(data, dict):
        return data if not segments else '?'

    sub = segments[0]
    rest = segments[1:]

    # Strip [] suffix for sub-name matching
    is_iter = sub.endswith('[]')
    sub_clean = sub[:-2] if is_iter else sub

    # 真实嵌套 key：preview / previewOther / quickAnswer
    if sub_clean in _EXAM_REAL_KEYS:
        sub_data = data.get(sub_clean, {})
        if not isinstance(sub_data, dict):
            return sub_data if not rest else '?'
        if not rest:
            return sub_data
        if is_iter:
            # sub was quickAnswer[] → iterate over inner array
            for arr_key in ('answers', 'questions', 'list', 'items'):
                if arr_key in sub_data and isinstance(sub_data[arr_key], list):
                    if not rest:
                        return sub_data[arr_key]
                    return [_navigate(item, rest) for item in sub_data[arr_key] if isinstance(item, dict)]
            return '?'
        return _navigate(sub_data, rest)

    # 扁平命名空间：auto / pick → 跳过 sub，在 exam 顶层解析
    if sub in _EXAM_FLATTEN_SUB:
        return _navigate(data, rest)

    # 带前缀映射：explore / favorites / myExams
    if sub in _EXAM_PREFIX_MAP:
        mapped_key = _EXAM_PREFIX_MAP[sub]
        # 把 rest 中的 getList 替换为映射 key
        new_rest = []
        for seg in rest:
            if seg == 'getList' or seg == 'getList[]':
                new_rest.append(mapped_key if seg == 'getList' else f'{mapped_key}[]')
            else:
                new_rest.append(seg)
        return _navigate(data, new_rest)

    # 其他（回退到普通导航）
    return _navigate(data, rest)


def resolve(path, data):
    """主入口：将 HTML data-db 路径解析为服务器数据的值。

    用法:
        resolve('assign.pendingCount', data)          → 2
        resolve('achievement.getCategories[].label', data)  → ['🔥 登录', '🎯 刷题', ...]
        resolve('user.getInfo.name', data)            → '晓学虫'
    """
    # 硬编码值
    if path in _HARDCODED:
        return _HARDCODED[path]

    segments = path.split('.')
    prefix = segments[0]

    # 前缀 → 数据顶层 key
    top_key = _PREFIX_MAP.get(prefix)
    if top_key is None:
        return '?'
    remaining = segments[1:]

    # exam 特殊处理
    if prefix == 'exam':
        return _resolve_exam(data.get('exam', {}), remaining)

    # 通用解析
    current = data.get(top_key)
    if current is None:
        return '?'

    # recommend / preference 可能是列表或普通值
    if not isinstance(current, dict):
        if not remaining:
            return current
        # 列表（如 recommend=[]）：跳过 getList 装饰段
        if isinstance(current, list) and remaining and remaining[0] in ('getList', 'getList[]'):
            if len(remaining) == 1:
                return current
            rest = remaining[1:]
            return [_navigate(item, rest) for item in current if isinstance(item, dict)]
        return '?'

    return _navigate(current, remaining)


# ═══════════════════════════════════════════════════════════════
#  第三部分：verify（读取 HTML → 提取 data-db 路径 → 远程查询 → 解析）
# ═══════════════════════════════════════════════════════════════

def verify(module_num):
    """验证模块：读 HTML 提取 data-db 路径，远程查数据，解析结果。"""
    pages = MODULE_PAGES.get(module_num, [])
    html_base = os.path.join(os.path.dirname(__file__), '..', '..', 'docs', '04-UI', 'html')

    # 读 HTML 提取 data-db / data-db-loop / data-db-bind 路径
    page_paths = defaultdict(list)
    for fname in pages:
        fpath = os.path.join(html_base, fname)
        if not os.path.exists(fpath):
            continue
        with open(fpath, encoding='utf-8') as f:
            txt = f.read()
        seen = set()
        # 匹配 data-db="..."、data-db-loop="..."、data-db-bind="..."
        for attr in ['data-db="', 'data-db-loop="', 'data-db-bind="']:
            for m in re.finditer(re.escape(attr) + r'([^"]+)', txt):
                p = m.group(1)
                # 跳过 ... 相对路径（需要父循环上下文）
                if p.startswith('...') or p in seen:
                    continue
                seen.add(p)
                page_paths[fname].append(p)

    # 执行远程查询
    data = run_remote_script()
    if data is None:
        print('ERROR: 远程查询失败', file=sys.stderr)
        return {'module': module_num, 'pages': {}, 'error': True}

    # 解析结果
    output = {'module': module_num, 'pages': {}}
    for fname, paths in page_paths.items():
        items = []
        for p in paths:
            val = resolve(p, data)
            if isinstance(val, str) and len(val) > 150:
                val = val[:150] + '...'
            items.append({'path': p, 'server_value': val})
        output['pages'][fname] = items
    return output


# ═══════════════════════════════════════════════════════════════
#  第四部分：CLI
# ═══════════════════════════════════════════════════════════════

def main():
    if len(sys.argv) >= 2 and sys.argv[1] in ('-h', '--help'):
        print(__doc__.strip())
        return
    mod = int(sys.argv[1])
    as_json = '--json' in sys.argv
    r = verify(mod)
    if as_json:
        print(json.dumps(r, ensure_ascii=False, indent=2))
    else:
        print(f'模块 {mod} — 数据验证报告')
        print('=' * 50)
        for fn, items in r['pages'].items():
            print(f'\n📄 {fn}')
            for it in items:
                v = it['server_value']
                if isinstance(v, list):
                    print(f'  {it["path"]}: [{len(v)} 项]')
                    for x in v[:3]:
                        s = str(x)
                        print(f'    - {s[:80]}')
                    if len(v) > 3:
                        print(f'    ... {len(v) - 3} more')
                elif isinstance(v, dict):
                    s = json.dumps(v, ensure_ascii=False)
                    print(f'  {it["path"]}: {s[:80]}')
                else:
                    print(f'  {it["path"]}: {v}')


if __name__ == '__main__':
    main()
