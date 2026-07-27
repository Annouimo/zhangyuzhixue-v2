#!/usr/bin/env python3
"""章鱼智学 v2 — 关键业务数据恢复脚本。

从 dump_data.py 导出的 JSON 恢复到 SQLite 数据库（覆盖同名表）。
用法：
    python scripts/load_data.py --from /path/to/data_dumps/2026-07-11/

注意：只恢复 JSON 中存在的表；不存在的表保持原状。
      auth_user 的 password 字段为 Django PBKDF2 hash，直接写入即可生效。
"""

import argparse
import json
import os
import sqlite3
import sys

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_DB = os.path.join(PROJECT_DIR, 'db.sqlite3')

# (输出文件名, 表名)
# 顺序：先写入不依赖外键的表，再写入有外键的表
FILE_TABLE_MAP = [
    ('auth_users',                    'auth_user'),
    ('accounts_students',             'accounts_student'),
    ('accounts_invitation_codes',     'accounts_invitationcode'),
    ('accounts_user_login_logs',      'accounts_userloginlog'),
    ('system_config',                 'system_systemconfig'),
    ('system_level_config',           'system_levelconfig'),
    ('system_achievement_defs',       'system_achievementdef'),
    ('system_app_versions',           'system_appversion'),
    ('system_announcements',          'system_announcement'),
    ('points_transactions',           'system_pointstransaction'),
    ('student_achievements',          'system_studentachievement'),
    ('courses_courses',               'courses_course'),
    ('interactions_submissions',             'interactions_studentsubmission'),
    ('interactions_submission_details',      'interactions_submissiondetail'),
    ('interactions_step_feedbacks',          'interactions_stepfeedback'),
    ('interactions_card_feedbacks',          'interactions_cardfeedback'),
    ('interactions_question_ratings',        'interactions_questionrating'),
    ('interactions_custom_papers',           'interactions_custompaper'),
    ('interactions_custom_paper_questions',  'interactions_custompaperquestion'),
    ('interactions_paper_likes',             'interactions_paperlike'),
    ('interactions_paper_collects',          'interactions_papercollect'),
]


def load(json_dir: str, db_path: str) -> dict:
    """从 JSON 文件恢复到 SQLite。返回 {表名: 行数}。"""
    if not os.path.isdir(json_dir):
        print(f'❌ 目录不存在: {json_dir}')
        sys.exit(1)

    conn = sqlite3.connect(db_path)
    conn.execute('PRAGMA foreign_keys = OFF')  # 临时关闭外键检查

    result = {}

    for filename, table in FILE_TABLE_MAP:
        filepath = os.path.join(json_dir, f'{filename}.json')
        if not os.path.exists(filepath):
            print(f'  ⚠ 跳过（文件不存在）: {filename}.json')
            result[table] = 0
            continue

        with open(filepath, 'r', encoding='utf-8') as f:
            rows = json.load(f)

        if not rows:
            result[table] = 0
            continue

        # 获取列名（从第一条记录推断）
        columns = list(rows[0].keys())
        placeholders = ', '.join(['?' for _ in columns])
        col_names = ', '.join(f'"{c}"' for c in columns)

        # 清空旧数据
        conn.execute(f'DELETE FROM "{table}"')

        # 批量写入
        values = [[row.get(c) for c in columns] for row in rows]
        conn.executemany(
            f'INSERT INTO "{table}" ({col_names}) VALUES ({placeholders})',
            values,
        )
        conn.commit()

        result[table] = len(rows)
        print(f'  {filename:45s} → {table:40s} {len(rows):>5d} rows')

    conn.execute('PRAGMA foreign_keys = ON')
    conn.close()
    return result


def main():
    parser = argparse.ArgumentParser(description='从 JSON 恢复业务数据到 SQLite')
    parser.add_argument('--db', default=DEFAULT_DB, help='数据库路径（默认 db.sqlite3）')
    parser.add_argument('--from', dest='json_dir', required=True,
                        help='JSON 数据目录（如 data_dumps/2026-07-11/）')
    args = parser.parse_args()

    if not os.path.exists(args.db):
        print(f'❌ 数据库不存在: {args.db}')
        sys.exit(1)

    print(f'⏳ 恢复数据: {args.json_dir} → {args.db}')
    result = load(args.json_dir, args.db)

    total = sum(result.values())
    print()
    print(f'✅ 恢复完成: {len(result)} 张表, {total} 条记录')
    for table, count in sorted(result.items()):
        tag = ' ⚠️ 0 rows' if count == 0 else ''
        print(f'   {table:45s} {count:>5d} rows{tag}')


if __name__ == '__main__':
    main()
