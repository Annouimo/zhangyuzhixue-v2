"""
data-db 验证工具 — 生成远程查询脚本并执行，一次输出全部数据。

用法:
    python docs/auto-audit/data_db_verify.py 2           # 查模块 2
    python docs/auto-audit/data_db_verify.py 2 --json    # JSON 输出
"""

import json, os, re, subprocess, sys, tempfile
from collections import defaultdict

MODULE_PAGES = {
    1: ['login.html','register.html','preference_welcome.html','preference_edit.html','preference_list.html'],
    2: ['index.html','lecture_courses.html','lecture_chapters.html','lecture_content.html'],
    3: [], 4: ['recommend.html'],
    5: ['exam.html','paper_auto.html','paper_pick.html','paper_quicklook.html',
        'paper_quicklook_other.html','paper_history.html','paper_explore.html',
        'paper_favorites.html','answer_sheet.html'],
    6: ['homework_list.html','homework_detail.html'],
    7: ['statistics.html'],
    8: ['profile.html','profile_edit.html','achievement.html','level_detail.html',
        'points.html','question_history.html','about.html','debug.html'],
    9: ['sync_queue.html'],
}

ECS_HOST = "root@123.57.85.160"
PROJECT_DIR = "/opt/zhangyuzhixue-v2/server"
VENV_PY = "/opt/zhangyuzhixue-v2/venv/bin/python"


def build_remote_script():
    """生成在 ECS 上执行的完整 Python 脚本内容。"""
    return r'''#!/usr/bin/env python3
"""data-db verify worker — runs on ECS, outputs one big JSON with all query results."""
import sys, os, json
sys.path.insert(0, '/opt/zhangyuzhixue-v2/server')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'math_platform.settings')
import django
django.setup()
from django.db import models

def main():
    uid = 'test_audit'
    from django.contrib.auth.models import User
    from accounts.models import Student
    from system.models import PointsTransaction, LevelConfig, AchievementDef, StudentAchievement
    from courses.models import Course, ClassCourseAssignment, Assignment, AssignmentQuestion, Document
    from interactions.models import StudentSubmission, SubmissionDetail, CustomPaper, CustomPaperQuestion, PaperLike, PaperCollect
    from qbank.models import BaseQuestion
    from django.db import connection
    from django.utils import timezone

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

    # 今日答题统计
    today_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
    today_sub_ids = StudentSubmission.objects.filter(student=s, created_at__gte=today_start).values_list('id', flat=True)
    today_earned = SubmissionDetail.objects.filter(submission_id__in=today_sub_ids, status='correct').count()

    # 全部答题统计
    total_sub_details = SubmissionDetail.objects.filter(submission__student=s)
    total_attempted = total_sub_details.count()
    total_correct = total_sub_details.filter(status='correct').count()
    accuracy = round(total_correct / total_attempted * 100) if total_attempted else 0

    # 偏好数量
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
        'answerHistoryCount': total_attempted,
        'allSuccessText': '全部已同步',
        'failedCountText': '同步失败',
    }

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
    first_docs = list(Document.objects.filter(course=Course.objects.first() if Course.objects.exists() else None).order_by('id')) if courses else []
    lecture = {
        'courseName': courses[0]['name'] if courses else '',
        'courses': courses,
        'title': first_docs[0].title if first_docs else '',
        'pages': [{'blocks': [doc.md_content or '']} for doc in first_docs],
    }

    # ── 成就 ──
    cats = []
    for ad in AchievementDef.objects.all().order_by('category', 'display_order'):
        prog = StudentAchievement.objects.filter(student=s, achievement=ad).first()
        un = prog and prog.is_unlocked
        cats.append({
            'label': ad.category_label or ad.get_category_display(),
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
    achievement = {
        'unlockedCount': sum(1 for c in cats if c['status'] == 'unlocked'),
        'totalCount': len(cats),
        'categories': cats,
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
                c.execute("SELECT COUNT(DISTINCT sd.question_id) FROM interactions_submissiondetail sd JOIN interactions_studentsubmission ss ON ss.id = sd.submission_id WHERE ss.student_id=%s AND ss.assignment_id=%s", [s.id, aid])
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
            # 查真实题型
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
            # 查已做完的题数
            done_ids = set()
            with connection.cursor() as c:
                c.execute("SELECT DISTINCT sd.question_id FROM interactions_submissiondetail sd JOIN interactions_studentsubmission ss ON ss.id = sd.submission_id WHERE ss.student_id=%s AND ss.assignment_id=%s", [s.id, aid])
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
    sync = {'queue': []}

    # ── 统计 ──
    choice_stats = SubmissionDetail.objects.filter(submission__student=s, question__question_type='choice').aggregate(
        total=models.Count('id'),
        correct=models.Count('id', filter=models.Q(status='correct')))
    fill_stats = SubmissionDetail.objects.filter(submission__student=s, question__question_type='fill').aggregate(
        total=models.Count('id'),
        correct=models.Count('id', filter=models.Q(status='correct')))
    solution_stats = SubmissionDetail.objects.filter(submission__student=s, question__question_type='solution').aggregate(
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

    # ── 题库统计 ──
    all_q = BaseQuestion.objects.count()
    choice = BaseQuestion.objects.filter(question_type='choice').count()
    fill = BaseQuestion.objects.filter(question_type='fill').count()
    solution = BaseQuestion.objects.filter(question_type='solution').count()

    # ── 组卷 ──
    # 真实试卷列表
    papers = CustomPaper.objects.filter(student=s).order_by('-id')[:20]
    paper_list = []
    for p in papers:
        pq_count = CustomPaperQuestion.objects.filter(paper=p).count()
        paper_list.append({
            'title': p.title or '',
            'meta': '自定义试卷',
            'difficulty': 3,
            'calculation': 2,
            'id': p.id,
            'questionCount': pq_count,
        })
    # 他人公开试卷
    other_papers = CustomPaper.objects.filter(is_public=True).exclude(student=s).order_by('-id')[:10]
    other_list = []
    for p in other_papers:
        pq_count = CustomPaperQuestion.objects.filter(paper=p).count()
        like_count = p.paperlike_set.count() if hasattr(p, 'paperlike_set') else 0
        collect_count = p.papercollect_set.count() if hasattr(p, 'papercollect_set') else 0
        other_list.append({
            'title': p.title or '',
            'authorInfo': p.student.user.username if hasattr(p.student, 'user') else '',
            'summary': p.description or '',
            'questionCount': pq_count,
            'likeCount': like_count,
            'collectCount': collect_count,
            'id': p.id,
        })
    # 用户收藏
    fav_papers = PaperCollect.objects.filter(student=s).select_related('paper')
    fav_list = []
    for fav in fav_papers:
        p = fav.paper
        pq_count = CustomPaperQuestion.objects.filter(paper=p).count()
        fav_list.append({
            'title': p.title or '',
            'authorInfo': p.student.user.username if hasattr(p.student, 'user') else '',
            'questionCount': pq_count,
        })
    exam = {
        'availableChoice': choice,
        'availableFill': fill,
        'availableSolution': solution,
        'totalCount': all_q,
        'selectedCount': 0,
        'poolDiffMin': 1,
        'poolDiffMax': 5,
        'gaokaoDiffMin': 1,
        'gaokaoDiffAvg': 3,
        'gaokaoDiffMax': 5,
        'filterPresets': [{'name': '北京高考'}],
        'getList': paper_list if paper_list else [],
        'exploreList': other_list if other_list else [],
        'favoritesList': fav_list if fav_list else [],
        'myExamsList': [],
        'preview': {
            'name': papers[0].title if papers else '示例试卷',
            'authorInfo': u.username,
            'summary': papers[0].description if papers else '试卷说明',
            'choiceCount': choice, 'fillCount': fill, 'solutionCount': solution, 'totalCount': all_q,
            'questions': [
                {'title': '题%d' % (i + 1), 'meta': '选择题'}
                for i in range(min(6, all_q))
            ] if not papers else [],
        },
        'previewOther': {
            'name': other_papers[0].title if other_papers else '他人试卷',
            'authorInfo': other_papers[0].student.user.username if other_papers and hasattr(other_papers[0].student, 'user') else 'other_user',
            'summary': other_papers[0].description if other_papers else '试卷说明',
            'choiceCount': choice, 'fillCount': fill, 'solutionCount': solution, 'totalCount': all_q,
            'likeCount': PaperLike.objects.filter(paper=other_papers[0]).count() if other_papers and hasattr(other_papers[0], 'paperlike_set') else 0,
            'collectCount': PaperCollect.objects.filter(paper=other_papers[0]).count() if other_papers else 0,
            'questions': [
                {'title': '题%d' % (i + 1), 'meta': '选择题'}
                for i in range(min(6, all_q))
            ] if not other_papers else [],
        } if other_papers else {
            'name': '他人试卷', 'authorInfo': 'other_user', 'summary': '试卷说明',
            'choiceCount': 3, 'fillCount': 2, 'solutionCount': 1, 'totalCount': 6,
            'likeCount': 0, 'collectCount': 0,
            'questions': [{'title': '题%d' % (i + 1), 'meta': '选择题'} for i in range(6)],
        },
        'quickAnswer': {
            'name': '快速作答', 'totalCount': min(6, all_q),
            'answers': [{'title': '题%d' % (i + 1), 'questionType': 'choice', 'answer': 'A'} for i in range(min(6, all_q))],
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
    }
    print(json.dumps(result, ensure_ascii=False))

if __name__ == '__main__':
    main()
'''
    return script  # noqa: RET504


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


# ── 路径解析器 ─────────────────────────────────────────────


def resolve(path, data):
    """从 data 大 JSON 中提取指定 data-db path 的值。"""
    parts = path.split('.')
    prefix = parts[0]

    # 映射：前缀 → data 顶层 key
    key_map = {
        'user': 'user_info', 'tasks': 'user_info', 'profile': 'user_info',
        'achievement': 'achievement',
        'lecture': 'lecture',
        'assign': 'assign',
        'points': 'points',
        'sync': 'sync',
        'stats': 'stats',
        'recommend': None,
        'preference': None,
        'exam': 'exam',
        'about': None,
    }

    top_key = key_map.get(prefix)
    if top_key is None:
        if prefix == 'about':
            return 'v2.0.0'
        if prefix == 'recommend':
            return []
        if prefix == 'preference':
            return {'list': [], 'filters': {'years': [], 'regions': [], 'conceptTags': []}}
        return '?'

    top = data.get(top_key, {})
    if not isinstance(top, dict):
        return top

    # 简单取值：user.getInfo.realName → user_info['realName']
    if prefix in ('user', 'tasks', 'profile', 'achievement', 'stats'):
        field = parts[-1]
        return top.get(field, '?')

    # lecture: lecture.getChapters[].title
    if prefix == 'lecture':
        if 'getCourses' in path:
            courses = top.get('courses', [])
            # getCourses[].name → 提取子字段
            field = parts[-1].lstrip('[]')
            if field and field not in ('getCourses', 'getCourses'):
                return [c.get(field, '?') for c in courses]
            return courses
        if 'getChapters' in path:
            if 'courseName' in path:
                return top.get('courseName', '?')
            chs = top.get('courses', [{}])[0].get('chapters', []) if top.get('courses') else []
            field = parts[-1].lstrip('[]')
            if field and field not in ('getChapters', 'getChapters', 'courseName'):
                return [c.get(field, '?') for c in chs]
            return chs
        if 'getContentParsed' in path:
            if 'title' in path:
                return top.get('title', '?')
            pages = top.get('pages', [])
            m = re.search(r'blocks\[(\d+)\]', path)
            if m:
                bi = int(m.group(1))
                return [pg.get('blocks', [])[bi] if bi < len(pg.get('blocks', [])) else '?' for pg in pages]
            return pages
        return '?'

    # assign
    if prefix == 'assign':
        if 'pendingCount' in path:
            return top.get('pendingCount', 0)
        if 'getPending' in path:
            return top.get('pending', [])
        if 'getQuestions' in path:
            return top.get('detail', {})
        return '?'

    # points
    if prefix == 'points':
        if 'getHistory' in path:
            return top.get('history', [])
        levels = top.get('levels', [])
        if 'getLevels' == parts[1]:
            if path == 'points.getLevels':
                return levels
            if 'getLevels[4]' in path:
                return levels[4] if len(levels) > 4 else {}
        return '?'

    # sync
    if prefix == 'sync':
        if 'getQueue' in path:
            return top.get('queue', [])
        return '?'

    # exam
    if prefix == 'exam':
        sub = parts[1] if len(parts) > 1 else ''
        if sub == 'auto':
            if 'available' in path:
                return top.get(parts[-1], 0)
            if 'filter' in path:
                return top.get(parts[-1], [])
            if 'poolDiff' in parts[-1] or 'gaokaoDiff' in parts[-1]:
                return top.get(parts[-1], 0)
            if 'filterPresets' in path:
                return top.get('filterPresets', [])
        if sub == 'pick':
            if 'filterPresets' in path:
                return top.get('filterPresets', [])
            if 'getList' in path:
                return top.get('getList', [])
            if 'totalCount' in path:
                return top.get('totalCount', 0)
            if 'selectedCount' in path:
                return top.get('selectedCount', 0)
        if sub in ('preview', 'previewOther'):
            pd = top.get(sub, {})
            if 'questions' in path:
                return pd.get('questions', [])
            return pd.get(parts[-1], '?')
        if sub == 'explore':
            return top.get('exploreList', [])
        if sub == 'favorites':
            return top.get('favoritesList', [])
        if sub == 'myExams':
            return top.get('myExamsList', [])
        if sub == 'quickAnswer':
            qa = top.get('quickAnswer', {})
            if len(parts) > 2:
                return qa.get(parts[2], '?')
            return qa
        return '?'

    return '?'


# ── CLI ──────────────────────────────────────────────────


def verify(module_num):
    pages = MODULE_PAGES.get(module_num, [])
    html_base = os.path.join(os.path.dirname(__file__), '..', '..', 'docs', '04-UI', 'html')

    # 读 HTML 提取 data-db 路径
    page_paths = defaultdict(list)
    for fname in pages:
        fpath = os.path.join(html_base, fname)
        if not os.path.exists(fpath):
            continue
        with open(fpath) as f:
            txt = f.read()
        seen = set()
        for attr in ['data-db="', 'data-db-loop="']:
            for m in re.finditer(re.escape(attr) + r'([^"]+)', txt):
                p = m.group(1)
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
                        print(f'    ... {len(v)-3} more')
                elif isinstance(v, dict):
                    print(f'  {it["path"]}: {json.dumps(v, ensure_ascii=False)[:80]}')
                else:
                    print(f'  {it["path"]}: {v}')


if __name__ == '__main__':
    main()
