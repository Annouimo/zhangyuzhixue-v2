#!/usr/bin/env python3
"""章鱼智学 v2 — 从 JSON 备份恢复业务数据。
用法：
    python scripts/load_data.py --from /path/to/data_dumps/2026-07-11/
"""

import argparse
import json
import os
import sqlite3
import sys

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_DB = os.path.join(PROJECT_DIR, 'db.sqlite3')

# (表名, JSON 文件名)
TABLES = [
    ('auth_user',                     'auth_users'),
    ('accounts_student',              'accounts_students'),
    ('accounts_teacher',              'accounts_teachers'),
    ('accounts_invitationcode',       'accounts_invitation_codes'),
    ('accounts_userloginlog',         'accounts_user_login_logs'),
    ('system_systemconfig',           'system_config'),
    ('system_levelconfig',            'system_level_config'),
    ('system_achievementdef',         'system_achievement_defs'),
    ('system_appversion',             'system_app_versions'),
    ('system_announcement',           'system_announcements'),
    ('system_pointstransaction',      'points_transactions'),
    ('system_studentachievement',     'student_achievements'),
    ('courses_course',                'courses_courses'),
    ('courses_classgroup',            'courses_class_groups'),
    ('courses_classcourse',           'courses_class_courses'),
    ('courses_classcourseassignment', 'courses_class_course_assignments'),
    ('courses_assignment',            'courses_assignments'),
    ('courses_assignmentquestion',    'courses_assignment_questions'),
    ('interactions_studentsubmission',  'interactions_submissions'),
    ('interactions_submissiondetail',   'interactions_submission_details'),
    ('interactions_stepfeedback',       'interactions_step_feedbacks'),
    ('interactions_cardfeedback',       'interactions_card_feedbacks'),
    ('interactions_questionrating',     'interactions_question_ratings'),
    ('interactions_custompaper',        'interactions_custom_papers'),
    ('interactions_custompaperquestion', 'interactions_custom_paper_questions'),
    ('interactions_paperlike',          'interactions_paper_likes'),
    ('interactions_papercollect',       'interactions_paper_collects'),
]


def load(db_path: str, data_dir: str, dry_run: bool = False):
    if not os.path.isdir(data_dir):
        print(f'❌ 数据目录不存在: {data_dir}')
        sys.exit(1)

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    total_inserted = 0

    for table, filename in TABLES:
        filepath = os.path.join(data_dir, f'{filename}.json')
        if not os.path.exists(filepath):
            print(f'  ⚠️ {table}: {filename}.json 不存在，跳过')
            continue

        with open(filepath, 'r', encoding='utf-8') as f:
            rows = json.load(f)

        if not rows:
            print(f'  {table}: 空数据，跳过')
            continue

        if dry_run:
            print(f'  {table}: 将插入 {len(rows)} 行（dry-run）')
            total_inserted += len(rows)
            continue

        # 逐行 INSERT OR IGNORE（主键冲突时跳过，容错已存在数据）
        inserted = 0
        skipped = 0
        for row in rows:
            cols = ', '.join(f'"{k}"' for k in row.keys())
            placeholders = ', '.join('?' for _ in row)
            values = tuple(row.values())
            try:
                conn.execute(
                    f'INSERT OR IGNORE INTO "{table}" ({cols}) VALUES ({placeholders})',
                    values
                )
                if conn.total_changes:
                    inserted += 1
                else:
                    skipped += 1
            except Exception as e:
                print(f'  ⚠️ {table}: 行 {row.get("id","?")} 插入失败: {e}')
                skipped += 1

        conn.commit()
        total_inserted += inserted
        status = f'{inserted} 插入'
        if skipped:
            status += f', {skipped} 跳过'
        print(f'  ✅ {table}: {status}')

    conn.close()
    print(f'\n总计: {total_inserted} 行 {"(dry-run)" if dry_run else "已恢复"}')


def main():
    parser = argparse.ArgumentParser(description='从 JSON 备份恢复业务数据')
    parser.add_argument('--db', default=DEFAULT_DB, help='数据库路径')
    parser.add_argument('--from', dest='from_dir', required=True, help='data_dumps/ 路径（含日期目录）')
    parser.add_argument('--dry-run', action='store_true', help='仅预览，不实际写入')
    args = parser.parse_args()

    if not os.path.exists(args.db):
        print(f'❌ 数据库不存在: {args.db}')
        sys.exit(1)

    print(f'恢复来源: {args.from_dir}')
    print(f'目标数据库: {args.db}')
    if args.dry_run:
        print('[DRY-RUN 模式] 不会实际写入数据库')
    print()

    load(args.db, args.from_dir, dry_run=args.dry_run)


if __name__ == '__main__':
    main()
