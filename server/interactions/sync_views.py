"""
用户数据拉取视图 — 构建 user.db 临时文件供客户端下载替换

GET /api/v1/sync/user/pull/

认证：Bearer token（仅 student）
响应：{ download_url, checksum, size_bytes, data_version }
"""
import gzip
import hashlib
import os
import sqlite3
import tempfile
import time
import uuid

from django.conf import settings
from django.db.models import Prefetch
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated

from interactions.models import (
    CustomPaper,
    PaperCollect,
    PaperLike,
    PreferenceFilter,
    QuestionRating,
    StudentSubmission,
    SubmissionDetail,
)
from system.models import PointsTransaction, StudentAchievement


TEMP_DIR = os.path.join(settings.MEDIA_ROOT, 'tmp_user_db')
_TTL_SECONDS = 300  # 5 分钟


def _cleanup_old_files():
    """删除 TEMP_DIR 中超过 5 分钟的临时 .db.gz 文件。"""
    if not os.path.isdir(TEMP_DIR):
        return
    now = time.time()
    for fname in os.listdir(TEMP_DIR):
        fpath = os.path.join(TEMP_DIR, fname)
        if fname.endswith('.db.gz') and now - os.path.getmtime(fpath) > _TTL_SECONDS:
            try:
                os.unlink(fpath)
            except OSError:
                pass


# ── 响应工具 ──────────────────────────────────────────────────


def _ok(data=None):
    from rest_framework.response import Response
    return Response({'code': 0, 'message': 'ok', 'data': data})


def _err(code, detail, http_status=400):
    from rest_framework.response import Response
    return Response(
        {'code': code, 'message': detail, 'data': None},
        status=http_status,
    )


# ── Schema ────────────────────────────────────────────────────

# 服务端生成 user.db 使用的表结构版本。与客户端 AppDatabase.schemaVersion 对应，
# 当 USER_DB_SCHEMA 的建表语句发生变化时需要递增。
USER_DB_SCHEMA_VERSION = 1

USER_DB_SCHEMA = """
CREATE TABLE IF NOT EXISTS user_profile (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    real_name TEXT,
    student_id TEXT,
    avatar TEXT,
    school TEXT,
    gaokao_year TEXT,
    class_group_id INTEGER,
    phone TEXT,
    accessible_course_ids TEXT,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS user_login_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    login_date TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS points_transaction (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    amount REAL NOT NULL,
    transaction_type TEXT NOT NULL,
    source TEXT NOT NULL,
    source_object_id INTEGER,
    client_id INTEGER,
    description TEXT,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS student_achievement (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    achievement_code TEXT NOT NULL,
    progress INTEGER NOT NULL DEFAULT 0,
    is_unlocked INTEGER NOT NULL DEFAULT 0,
    unlocked_at TEXT,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS submission (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER,
    student_id INTEGER NOT NULL,
    assignment_id INTEGER,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS submission_detail (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER,
    submission_id INTEGER,
    question_id INTEGER NOT NULL,
    attempt_number INTEGER NOT NULL DEFAULT 1,
    status TEXT NOT NULL DEFAULT 'in_progress',
    answer_text TEXT,
    is_correct INTEGER,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS step_feedback (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER,
    submission_detail_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,
    sub_question_index INTEGER,
    method_id INTEGER,
    step_number INTEGER NOT NULL,
    status TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS card_feedback (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER,
    submission_detail_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,
    card_title TEXT NOT NULL,
    card_status TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS question_rating (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER,
    question_id INTEGER NOT NULL,
    difficulty_score INTEGER NOT NULL,
    calculation_score INTEGER NOT NULL,
    elegance_score INTEGER NOT NULL,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS custom_paper (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER,
    title TEXT NOT NULL,
    description TEXT,
    filter_snapshot TEXT,
    is_public INTEGER NOT NULL DEFAULT 0,
    view_count INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS custom_paper_question (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    paper_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,
    sort_order INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS paper_like (
    paper_id INTEGER NOT NULL PRIMARY KEY,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS paper_collect (
    paper_id INTEGER NOT NULL PRIMARY KEY,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS preference_filter (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    years TEXT NOT NULL,
    regions TEXT NOT NULL,
    concept_tags TEXT NOT NULL,
    types TEXT,
    knowledge_cards TEXT,
    question_types TEXT,
    diff_min REAL,
    diff_max REAL,
    calc_min REAL,
    calc_max REAL
);

CREATE TABLE IF NOT EXISTS sync_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT NOT NULL,
    operation_type TEXT NOT NULL,
    entity_id INTEGER NOT NULL,
    server_id INTEGER,
    payload TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    retry_count INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT
);
"""

# ── Dump 函数 ─────────────────────────────────────────────────


def _fmt_dt(dt):
    """Django datetime → ISO 8601 string (or None)."""
    if dt is None:
        return None
    return dt.isoformat()


def _dump_user_profile(conn, student):
    user = student.user
    # 查询该学生班级可访问的 course_id 列表
    from courses.models import ClassCourseAssignment
    cids = list(ClassCourseAssignment.objects.filter(
        class_course__class_group_id=student.class_group_id,
        is_active=True,
    ).values_list(
        'class_course__course_id', flat=True,
    ).distinct().order_by('class_course__course_id'))
    course_ids_str = ','.join(str(c) for c in cids) if cids else None
    conn.execute(
        'INSERT OR REPLACE INTO user_profile '
        '(id, name, real_name, student_id, avatar, school, '
        'gaokao_year, class_group_id, phone, accessible_course_ids, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
            user.pk,
            user.username,
            user.first_name or None,
            student.student_id or None,
            student.avatar or None,
            student.school or None,
            str(student.gaokao_year) if student.gaokao_year else None,
            student.class_group_id,
            student.phone or None,
            course_ids_str,
            _fmt_dt(student.updated_at),
        ],
    )


def _dump_login_logs(conn, student):
    for log in student.login_logs.all():
        conn.execute(
            'INSERT OR IGNORE INTO user_login_log (login_date, created_at) '
            'VALUES (?, ?)',
            [_fmt_dt(log.login_date), _fmt_dt(log.created_at)],
        )


def _dump_points(conn, student):
    pts = PointsTransaction.objects.filter(student=student)
    rows = []
    for pt in pts:
        rows.append([
            pt.pk, pt.amount, pt.transaction_type, pt.source,
            pt.source_object_id, pt.client_id, pt.description or '',
            _fmt_dt(pt.created_at),
        ])
    if rows:
        conn.executemany(
            'INSERT INTO points_transaction (id, amount, transaction_type, '
            'source, source_object_id, client_id, description, created_at) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            rows,
        )


def _dump_achievements(conn, student):
    achievements = StudentAchievement.objects.filter(
        student=student
    ).select_related('achievement')
    rows = []
    for sa in achievements:
        rows.append([
            sa.pk, sa.achievement.code, sa.progress,
            1 if sa.is_unlocked else 0,
            _fmt_dt(sa.unlocked_at), _fmt_dt(sa.updated_at),
        ])
    if rows:
        conn.executemany(
            'INSERT INTO student_achievement '
            '(id, achievement_code, progress, is_unlocked, unlocked_at, updated_at) '
            'VALUES (?, ?, ?, ?, ?, ?)',
            rows,
        )


def _dump_submissions(conn, student):
    submissions = StudentSubmission.objects.filter(
        student=student
    ).prefetch_related(
        Prefetch('details', queryset=SubmissionDetail.objects.prefetch_related(
            'step_feedbacks',
            'card_feedbacks',
        )),
    )

    for sub in submissions:
        conn.execute(
            'INSERT INTO submission '
            '(id, server_id, student_id, assignment_id, created_at, updated_at) '
            'VALUES (?, ?, ?, ?, ?, ?)',
            [
                sub.pk, sub.pk, student.pk, sub.assignment_id,
                _fmt_dt(sub.created_at), _fmt_dt(sub.updated_at),
            ],
        )

        for detail in sub.details.all():
            conn.execute(
                'INSERT INTO submission_detail '
                '(id, server_id, submission_id, question_id, attempt_number, status, '
                'answer_text, is_correct, created_at, updated_at) '
                'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [
                    detail.pk, detail.pk, sub.pk, detail.question_id,
                    detail.attempt_number, detail.status,
                    detail.answer_text,
                    1 if detail.is_correct else 0 if detail.is_correct is not None else None,
                    _fmt_dt(detail.created_at), _fmt_dt(detail.updated_at),
                ],
            )

            for sf in detail.step_feedbacks.all():
                conn.execute(
                    'INSERT INTO step_feedback '
                    '(id, server_id, submission_detail_id, question_id, '
                    'sub_question_index, method_id, step_number, status, created_at) '
                    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
                    [
                        sf.pk, sf.pk, detail.pk, sf.question_id,
                        sf.sub_question_index, sf.method_id,
                        sf.step_number, sf.status, _fmt_dt(sf.created_at),
                    ],
                )

            for cf in detail.card_feedbacks.all():
                conn.execute(
                    'INSERT INTO card_feedback '
                    '(id, server_id, submission_detail_id, question_id, '
                    'card_title, card_status, created_at) '
                    'VALUES (?, ?, ?, ?, ?, ?, ?)',
                    [
                        cf.pk, cf.pk, detail.pk, cf.question_id,
                        cf.card_title, cf.card_status, _fmt_dt(cf.created_at),
                    ],
                )


def _dump_ratings(conn, student):
    ratings = QuestionRating.objects.filter(student=student)
    rows = []
    for r in ratings:
        rows.append([r.pk, r.pk, r.question_id, r.difficulty_score,
                     r.calculation_score, r.elegance_score, _fmt_dt(r.created_at)])
    if rows:
        conn.executemany(
            'INSERT INTO question_rating '
            '(id, server_id, question_id, '
            'difficulty_score, calculation_score, '
            'elegance_score, created_at) '
            'VALUES (?, ?, ?, ?, ?, ?, ?)',
            rows,
        )


def _dump_custom_papers(conn, student):
    papers = CustomPaper.objects.filter(student=student).prefetch_related('paper_questions')
    for p in papers:
        conn.execute(
            'INSERT INTO custom_paper '
            '(id, server_id, title, description, filter_snapshot, '
            'is_public, view_count, created_at, updated_at) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
                p.pk, p.pk, p.title, p.description or '',
                p.filter_snapshot if p.filter_snapshot else None,
                1 if p.is_public else 0, p.view_count,
                _fmt_dt(p.created_at), _fmt_dt(p.updated_at),
            ],
        )

        for pq in p.paper_questions.all():
            conn.execute(
                'INSERT INTO custom_paper_question '
                '(id, paper_id, question_id, sort_order) '
                'VALUES (?, ?, ?, ?)',
                [pq.pk, p.pk, pq.question_id, pq.sort_order],
            )


def _dump_likes(conn, student):
    likes = PaperLike.objects.filter(student=student)
    rows = []
    for like in likes:
        rows.append([like.paper_id, _fmt_dt(like.created_at)])
    if rows:
        conn.executemany(
            'INSERT OR IGNORE INTO paper_like (paper_id, created_at) VALUES (?, ?)',
            rows,
        )


def _dump_collects(conn, student):
    collects = PaperCollect.objects.filter(student=student)
    rows = []
    for collect in collects:
        rows.append([collect.paper_id, _fmt_dt(collect.created_at)])
    if rows:
        conn.executemany(
            'INSERT OR IGNORE INTO paper_collect (paper_id, created_at) VALUES (?, ?)',
            rows,
        )


def _dump_preferences(conn, student):
    for pref in PreferenceFilter.objects.filter(student=student):
        conn.execute(
            'INSERT INTO preference_filter '
            '(id, name, years, regions, concept_tags, types, '
            'knowledge_cards, question_types, '
            'diff_min, diff_max, calc_min, calc_max) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
                pref.pk, pref.name, pref.years, pref.regions,
                pref.concept_tags, pref.types,
                pref.knowledge_cards, pref.question_types,
                pref.diff_min, pref.diff_max,
                pref.calc_min, pref.calc_max,
            ],
        )


# ── View ──────────────────────────────────────────────────────


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def pull_user_db(request):
    """生成该学生的 user.db.gz，返回下载信息。"""
    student = getattr(request.user, 'student', None)
    if not student:
        return _err(40003, '仅学生可拉取用户数据')

    os.makedirs(TEMP_DIR, exist_ok=True)
    _cleanup_old_files()

    _tf_obj = tempfile.NamedTemporaryFile(suffix='.db', delete=False)
    db_path = _tf_obj.name
    _tf_obj.close()

    try:
        conn = sqlite3.connect(db_path)
        conn.executescript(USER_DB_SCHEMA)
        conn.execute('PRAGMA journal_mode=WAL')

        _dump_user_profile(conn, student)
        _dump_login_logs(conn, student)
        _dump_points(conn, student)
        _dump_achievements(conn, student)
        _dump_submissions(conn, student)
        _dump_ratings(conn, student)
        _dump_custom_papers(conn, student)
        _dump_likes(conn, student)
        _dump_collects(conn, student)
        _dump_preferences(conn, student)

        conn.commit()
        conn.close()

        # gzip
        with open(db_path, 'rb') as f:
            raw = f.read()
        gz_data = gzip.compress(raw)
        checksum = hashlib.sha256(gz_data).hexdigest()
        size = len(gz_data)

        # 保存到临时文件
        filename = f'user_{student.pk}_{uuid.uuid4().hex[:8]}.db.gz'
        dest = os.path.join(TEMP_DIR, filename)
        with open(dest, 'wb') as f:
            f.write(gz_data)

        download_url = request.build_absolute_uri(
            f'/media/tmp_user_db/{filename}'
        )

        return _ok(data={
            'download_url': download_url,
            'checksum': checksum,
            'size_bytes': size,
            'data_version': student.data_version,
        })

    finally:
        if db_path and os.path.exists(db_path):
            os.unlink(db_path)
