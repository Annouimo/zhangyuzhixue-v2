#!/usr/bin/env python3
"""章鱼智学 v2 — 关键业务数据导出脚本。
输出 JSON 到指定目录，供版本化管理（Gitee 独立仓库）。
用法：
    python scripts/dump_data.py --out /path/to/data-dump-dir
    python scripts/dump_data.py  # 默认输出到 server/data_dumps/{YYYY-MM-DD}/
"""

import argparse
import json
import os
import sqlite3
import sys
from datetime import datetime, timezone

# 项目根目录（脚本上一级）
PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_DB = os.path.join(PROJECT_DIR, 'db.sqlite3')

# (表名, 输出文件名, 排除字段列表)
TABLES = [
    ('auth_user',                     'auth_users',               ['password']),
    ('accounts_student',              'accounts_students',        []),
    ('accounts_teacher',              'accounts_teachers',        []),
    ('accounts_invitationcode',       'accounts_invitation_codes', []),
    ('accounts_userloginlog',         'accounts_user_login_logs',  []),
    ('system_systemconfig',           'system_config',            []),
    ('system_levelconfig',            'system_level_config',      []),
    ('system_achievementdef',         'system_achievement_defs',  []),
    ('system_appversion',             'system_app_versions',      []),
    ('system_announcement',           'system_announcements',     []),
    ('system_pointstransaction',      'points_transactions',      []),
    ('system_studentachievement',     'student_achievements',     []),
    ('courses_course',                'courses_courses',          []),
    ('courses_classgroup',            'courses_class_groups',     []),
    ('courses_classcourse',           'courses_class_courses',    []),
    ('courses_classcourseassignment', 'courses_class_course_assignments', []),
    ('courses_assignment',            'courses_assignments',      []),
    ('courses_assignmentquestion',    'courses_assignment_questions', []),
    ('interactions_studentsubmission',  'interactions_submissions',           []),
    ('interactions_submissiondetail',   'interactions_submission_details',    []),
    ('interactions_stepfeedback',       'interactions_step_feedbacks',        []),
    ('interactions_cardfeedback',       'interactions_card_feedbacks',        []),
    ('interactions_questionrating',     'interactions_question_ratings',      []),
    ('interactions_custompaper',        'interactions_custom_papers',         []),
    ('interactions_custompaperquestion', 'interactions_custom_paper_questions', []),
    ('interactions_paperlike',          'interactions_paper_likes',           []),
    ('interactions_papercollect',       'interactions_paper_collects',        []),
]


def dump(db_path: str, out_dir: str) -> dict:
    os.makedirs(out_dir, exist_ok=True)

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row

    meta = {
        'exported_at': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
        'project': 'zhangyuzhixue-v2',
        'tables': {},
    }

    for table, filename, exclude_cols in TABLES:
        # 检查表是否存在
        cur = conn.execute("SELECT name FROM sqlite_master WHERE type='table' AND name=?", (table,))
        if not cur.fetchone():
            meta['tables'][table] = {
                'count': 0, 'file': f'{filename}.json', 'status': 'table_not_found'
            }
            continue

        cur = conn.execute(f'SELECT * FROM "{table}"')
        rows = [dict(r) for r in cur.fetchall()]

        # 排除敏感字段
        for row in rows:
            for col in exclude_cols:
                row.pop(col, None)

        filepath = os.path.join(out_dir, f'{filename}.json')
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(rows, f, ensure_ascii=False, indent=2, default=str)

        meta['tables'][table] = {'count': len(rows), 'file': f'{filename}.json'}

    conn.close()

    # 写 _meta.json
    with open(os.path.join(out_dir, '_meta.json'), 'w', encoding='utf-8') as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)

    return meta


def main():
    parser = argparse.ArgumentParser(description='导出业务数据为 JSON')
    parser.add_argument('--db', default=DEFAULT_DB, help='数据库路径')
    parser.add_argument('--out', help='输出目录（默认 server/data_dumps/{YYYY-MM-DD}/）')
    args = parser.parse_args()

    if not os.path.exists(args.db):
        print(f'❌ 数据库不存在: {args.db}')
        sys.exit(1)

    if args.out:
        out_dir = args.out
    else:
        date_str = datetime.now(timezone.utc).strftime('%Y-%m-%d')
        out_dir = os.path.join(PROJECT_DIR, 'data_dumps', date_str)

    meta = dump(args.db, out_dir)
    total = sum(v['count'] for v in meta['tables'].values() if isinstance(v, dict))
    print(f'✅ 导出完成: {out_dir}')
    print(f'   共 {len(meta["tables"])} 张表, {total} 条记录')
    for t, info in sorted(meta['tables'].items()):
        status = info.get('status', '')
        tag = f' ⚠️ {status}' if status else ''
        print(f'   {t:45s} {info["count"]:>5d} rows{tag}')


if __name__ == '__main__':
    main()
