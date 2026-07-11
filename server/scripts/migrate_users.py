#!/usr/bin/env python3
"""章鱼智学 v2 — 用户数据迁移脚本（Phase 6.1 一次性迁移）。

从旧版 D:\\Hermes\\math_platform\\db.sqlite3 迁移用户到当前数据库。
迁移后旧版用户密码保持原有 hash，可直接登录。

用法：
    python scripts/migrate_users.py                    # 默认路径
    python scripts/migrate_users.py --old path/to/old/db.sqlite3

幂等：首次迁移后在 auth_user 写入标记行（id=0, username='__migrated__'），
      再次运行时检测到此行则跳过。
"""

import argparse
import os
import sqlite3
import sys

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_OLD_DB = os.path.join('D:\\', 'Hermes', 'math_platform', 'db.sqlite3')
DEFAULT_NEW_DB = os.path.join(PROJECT_DIR, 'db.sqlite3')

# 新版 Dev 用户 username（迁移时跳过这些老版中同名的用户）
DEV_USERNAMES = {'admin', 'teacher1', 'student1', 'student2', 'student3'}
# Dev 用户占用 ID 区间 1-99，旧版用户从 100 开始偏移
ID_OFFSET = 100


def _table_exists(conn, name):
    cur = conn.execute("SELECT name FROM sqlite_master WHERE type='table' AND name=?", (name,))
    return cur.fetchone() is not None


def _has_migration_marker(conn):
    """检查 auth_user 中是否有 '__migrated__' 标记行"""
    cur = conn.execute("SELECT 1 FROM auth_user WHERE username='__migrated__'")
    return cur.fetchone() is not None


def _write_migration_marker(conn):
    conn.execute(
        "INSERT OR IGNORE INTO auth_user "
        "(id, username, password, email, date_joined, "
        "is_superuser, is_staff, is_active) "
        "VALUES (0, '__migrated__', '', '', '1970-01-01 00:00:00', 0, 0, 0)"
    )


def migrate(old_db: str, new_db: str) -> dict:
    """执行迁移，返回统计信息"""
    old = sqlite3.connect(old_db)
    new = sqlite3.connect(new_db)

    stats = {'auth_user': 0, 'accounts_student': 0, 'accounts_teacher': 0,
             'accounts_invitationcode': 0, 'skipped_dup': 0}

    # ── 幂等检查 ──
    if _table_exists(new, 'auth_user') and _has_migration_marker(new):
        print('⚠  检测到已迁移标记（__migrated__），跳过。如需重新迁移，先删除标记行。')
        old.close()
        new.close()
        return stats

    # ── 1. 迁移 auth_user ──
    print('┌─ 1. 迁移 auth_user')
    if not _table_exists(old, 'auth_user'):
        print('  ⚠ 旧版 auth_user 表不存在，跳过')
    else:
        old_users = old.execute(
            'SELECT id, username, password, email, date_joined, is_superuser, is_staff, is_active '
            'FROM auth_user ORDER BY id'
        ).fetchall()

        cols = ['id', 'username', 'password', 'email', 'date_joined',
                'is_superuser', 'is_staff', 'is_active']
        placeholders = ', '.join(['?' for _ in cols])
        col_names = ', '.join(f'"{c}"' for c in cols)

        for u in old_users:
            uid, username = u[0], u[1]
            # 跳过 Dev 重名用户
            if username in DEV_USERNAMES:
                print(f'  ⚠ 跳过 Dev 重名用户: {username} (id={uid})')
                stats['skipped_dup'] += 1
                continue

            # 检查新版是否已存在此 username
            existing = new.execute(
                "SELECT 1 FROM auth_user WHERE username=?", (username,)
            ).fetchone()
            if existing:
                print(f'  ⚠ 新版已有同名用户，跳过: {username}')
                stats['skipped_dup'] += 1
                continue

            # 写入新版 auth_user（保持旧 ID）
            new.execute(
                f'INSERT OR IGNORE INTO auth_user ({col_names}) VALUES ({placeholders})',
                (
                    uid,              # id
                    username,         # username
                    u[2],             # password — Django PBKDF2 hash，保持原样
                    u[3],             # email
                    u[4],             # date_joined
                    u[5] or 0,        # is_superuser
                    u[6] or 0,        # is_staff
                    u[7] or 1,        # is_active
                ),
            )
            stats['auth_user'] += 1

        new.commit()
        print(f'  → 迁移 {stats["auth_user"]} 个用户, 跳过 {stats["skipped_dup"]} 个重名')

    # ── 2. 迁移 accounts_student ──
    print('┌─ 2. 迁移 accounts_student')
    if not _table_exists(old, 'accounts_student'):
        print('  ⚠ 旧版 accounts_student 表不存在，跳过')
    else:
        old_students = old.execute(
            'SELECT id, user_id, student_id, school, gaokao_year, phone, '
            '       class_group_id, created_at, updated_at '
            'FROM accounts_student ORDER BY id'
        ).fetchall()

        for s in old_students:
            sid, uid = s[0], s[1]

            # 检查对应的 auth_user 是否已迁移
            user_exists = new.execute(
                "SELECT 1 FROM auth_user WHERE id=?", (uid,)
            ).fetchone()
            if not user_exists:
                print(f'  ⚠ 用户 id={uid} 不存在，跳过 student id={sid}')
                continue

            # student_id 留空 → LCG 自动生成。写入临时空值
            new.execute(
                'INSERT OR IGNORE INTO accounts_student '
                '(id, user_id, student_id, school, gaokao_year, phone, '
                'class_group_id, created_at, updated_at) '
                'VALUES (?, ?, '', ?, ?, ?, NULL, ?, ?)',
                (
                    sid, s[1], s[3], s[4], s[5], s[7], s[8],
                ),
            )
            stats['accounts_student'] += 1

        new.commit()
        print(f'  → 迁移 {stats["accounts_student"]} 个学生')

    # ── 3. 迁移 accounts_teacher ──
    print('┌─ 3. 迁移 accounts_teacher')
    if not _table_exists(old, 'accounts_teacher'):
        print('  ⚠ 旧版 accounts_teacher 表不存在，跳过')
    else:
        old_teachers = old.execute(
            'SELECT id, user_id, title, school, created_at, updated_at '
            'FROM accounts_teacher ORDER BY id'
        ).fetchall()

        for t in old_teachers:
            user_exists = new.execute(
                "SELECT 1 FROM auth_user WHERE id=?", (t[1],)
            ).fetchone()
            if not user_exists:
                print(f'  ⚠ 用户 id={t[1]} 不存在，跳过 teacher id={t[0]}')
                continue

            new.execute(
                'INSERT OR IGNORE INTO accounts_teacher '
                '(id, user_id, title, school, created_at, updated_at) '
                'VALUES (?, ?, ?, ?, ?, ?)',
                t,
            )
            stats['accounts_teacher'] += 1

        new.commit()
        print(f'  → 迁移 {stats["accounts_teacher"]} 个教师')

    # ── 4. 迁移 invitation_code（见 6.2，合并至此） ──
    print('┌─ 4. 迁移邀请码')
    # 旧版表名可能是 invitation_invitationcode 或 accounts_invitationcode
    old_ic_table = None
    for name in ['invitation_invitationcode', 'accounts_invitationcode']:
        if _table_exists(old, name):
            old_ic_table = name
            break

    if old_ic_table is None:
        print('  ⚠ 旧版邀请码表不存在，跳过')
    else:
        old_codes = old.execute(
            f'SELECT id, code, is_used, used_by_id, created_at FROM "{old_ic_table}" ORDER BY id'
        ).fetchall()

        for c in old_codes:
            new.execute(
                'INSERT OR IGNORE INTO accounts_invitationcode '
                '(id, code, is_used, used_by_id, created_at) '
                'VALUES (?, ?, ?, ?, ?)',
                c,
            )
            stats['accounts_invitationcode'] += 1

        new.commit()
        print(f'  → 迁移 {stats["accounts_invitationcode"]} 个邀请码')

    # ── 写入迁移标记（幂等） ──
    _write_migration_marker(new)
    new.commit()

    old.close()
    new.close()

    # ── 验证 ──
    print()
    print('─' * 50)
    print('验证：')
    verify_conn = sqlite3.connect(new_db)
    for table, label in [
        ('auth_user', '用户'),
        ('accounts_student', '学生'),
        ('accounts_teacher', '教师'),
        ('accounts_invitationcode', '邀请码'),
    ]:
        cnt = verify_conn.execute(f'SELECT COUNT(*) FROM "{table}"').fetchone()[0]
        print(f'  {label:8s}: {cnt}')
    verify_conn.close()

    return stats


def main():
    parser = argparse.ArgumentParser(description='从旧版数据库迁移用户到新版')
    parser.add_argument('--old', default=DEFAULT_OLD_DB, help='旧版数据库路径')
    parser.add_argument('--new', default=DEFAULT_NEW_DB, help='新版数据库路径')
    args = parser.parse_args()

    if not os.path.exists(args.old):
        print(f'❌ 旧版数据库不存在: {args.old}')
        print('   请确认路径后重试：python scripts/migrate_users.py --old <path>')
        sys.exit(1)
    if not os.path.exists(args.new):
        print(f'❌ 新版数据库不存在: {args.new}')
        sys.exit(1)

    print(f'⏳ 迁移用户: {args.old} → {args.new}')
    print()

    stats = migrate(args.old, args.new)

    if stats['auth_user'] == 0 and stats['accounts_invitationcode'] == 0:
        print()
        print('⚠  没有新数据被迁移（已有标记或旧版为空）')
    else:
        print()
        print('✅ 迁移完成')
        print(f'   用户: {stats["auth_user"]}')
        print(f'   学生: {stats["accounts_student"]}')
        print(f'   教师: {stats["accounts_teacher"]}')
        print(f'   邀请码: {stats["accounts_invitationcode"]}')
        print(f'   跳过的重名: {stats["skipped_dup"]}')


if __name__ == '__main__':
    main()
