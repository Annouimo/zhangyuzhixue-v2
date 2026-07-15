"""示例修复脚本 — 只读验证 run_fix 框架可用"""
import sqlite3

def fix(conn):
    """什么都不改，只返回数据库状态"""
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM qbank_basequestion")
    q_count = cur.fetchone()[0]
    return {
        'fixed': 0,
        'tables': ['qbank_basequestion'],
        'info': f'题库共 {q_count} 题',
    }

def verify(conn):
    """验证数据库可连接，基础表存在"""
    required_tables = [
        'qbank_basequestion',
        'qbank_subquestion',
        'qbank_choiceext',
        'qbank_solutionstep',
        'system_dbversion',
    ]
    cur = conn.cursor()
    for table in required_tables:
        cnt = cur.execute(
            "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name=?",
            (table,)
        ).fetchone()[0]
        if cnt == 0:
            print(f'  ❌ 缺少表: {table}')
            return False
    print(f'  ✅ 所有基础表存在')
    return True
