#!/usr/bin/env python3
"""ECS 查询工具 — 封装 SSH + Django shell，返回结构化 JSON。

解决 PowerShell → SSH → bash → Python 四层引号嵌套问题。
所有命令均通过写入远程临时脚本执行，不在命令行拼 Python 代码。

用法:
    python ecs_query.py health                     # 一次查所有关键指标
    python ecs_query.py check-user <username>       # 用户+作业检查
    python ecs_query.py count <table_alias>         # 表行数（支持别名）
    python ecs_query.py sql <SQL>                   # 执行任意 SQL
    python ecs_query.py dbshell                     # 交互式数据库控制台
    python ecs_query.py models <model_name>         # 查模型字段定义
    python ecs_query.py files [path_pattern]        # 列服务器文件
    python ecs_query.py verify <模块号>              # 验证模块所有动态数据，缓存到 .verify_cache/
    python ecs_query.py page <模块号> <页面名.html>   # 从缓存读单个页面数据
    python ecs_query.py verify <模块号> --json        # 纯 JSON 输出（不缓存）
"""

import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import textwrap

# ── ECS 连接配置（确认后改） ─────────────────────────────────
ECS_HOST = "root@81.70.243.63"
PROJECT_DIR = "/opt/zhangyuzhixue-v2/server"
VENV_PY = "/opt/zhangyuzhixue-v2/venv/bin/python"
SETTINGS_MODULE = "math_platform.settings"
# ──────────────────────────────────────────────────────────────

TABLE_ALIASES = {
    "questions": "qbank_basequestion",
    "qbank": "qbank_basequestion",
    "question": "qbank_basequestion",
    "courses": "courses_course",
    "course": "courses_course",
    "configs": "system_systemconfig",
    "config": "system_systemconfig",
    "system_configs": "system_systemconfig",
    "assignments": "courses_assignment",
    "assignment": "courses_assignment",
    "homework": "courses_assignment",
    "users": "auth_user",
    "user": "auth_user",
    "auth_user": "auth_user",
    "lectures": "courses_course",  # lectures 不是一张表，用 courses 近似
}

LOGO = """\
╔══════════════════════════╗
║  章鱼智学 · ECS 查询工具  ║
╚══════════════════════════╝"""


# ── 远程执行 ─────────────────────────────────────────────


def _scp_script(local_path: str, remote_path: str):
    """scp 本地文件到 ECS。"""
    subprocess.run(
        ["scp", local_path, f"{ECS_HOST}:{remote_path}"],
        capture_output=True, check=True,
    )


def _ssh(cmd: str) -> subprocess.CompletedProcess:
    """在 ECS 上执行命令，返回 CompletedProcess。"""
    return subprocess.run(
        ["ssh", ECS_HOST, cmd],
        capture_output=True, text=True,
    )


def _run_py(python_code: str) -> dict:
    """将 Python 代码写入 ECS 临时脚本并执行，返回 JSON 输出。

    自动注入 sys.path、DJANGO_SETTINGS_MODULE、django.setup()。
    远程脚本执行完毕后自动清理。
    """
    preamble = textwrap.dedent(f"""\
    import sys, json
    sys.path.insert(0, '{PROJECT_DIR}')
    import os
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', '{SETTINGS_MODULE}')
    import django
    django.setup()
    """)
    full_code = preamble + python_code

    fd, local_path = tempfile.mkstemp(
        suffix=".py", prefix="ecs_q_", dir=os.path.join(tempfile.gettempdir(), ""),
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(full_code)

        remote_path = "/tmp/_ecs_query_temp.py"
        _scp_script(local_path, remote_path)
        result = _ssh(f"{VENV_PY} {remote_path}")
        _ssh(f"rm -f {remote_path}")  # 清理远程临时文件

        if result.returncode != 0:
            err = result.stderr.strip()
            return {"ok": False, "error": err or "unknown error"}

        output = result.stdout.strip()
        if not output:
            return {"ok": True, "result": None}
        try:
            return json.loads(output)
        except json.JSONDecodeError:
            return {"ok": True, "result": output}
    finally:
        os.unlink(local_path)


def _raw_sql(sql: str) -> dict:
    """执行原始 SQL，返回 {ok, rows, count}。"""
    code = textwrap.dedent("""\
    from django.db import connection
    q = {sql!r}
    with connection.cursor() as c:
        c.execute(q)
        if q.strip().upper().startswith("SELECT"):
            rows = c.fetchall()
            cols = [desc[0] for desc in c.description]
            # datetime 对象 JSON 不直接支持，转 ISO 字符串
            rows = [[v.isoformat() if hasattr(v, 'isoformat') else v for v in r] for r in rows]
            print(json.dumps({"ok": True, "columns": cols, "rows": [list(r) for r in rows], "count": len(rows)},
                             ensure_ascii=False))
        else:
            print(json.dumps({"ok": True, "affected": c.rowcount}, ensure_ascii=False))
    """)
    code = code.replace("{sql!r}", repr(sql))
    return _run_py(code)


# ── 各命令实现 ──────────────────────────────────────────


def cmd_health() -> dict:
    """检查所有关键指标。"""
    code = textwrap.dedent("""\
    from qbank.models import BaseQuestion
    from courses.models import Course, Assignment
    from system.models import SystemConfig
    from django.contrib.auth.models import User
    from accounts.models import Student
    u = User.objects.filter(username='test_audit').first()
    sid = u.student.id if u and hasattr(u, 'student') else None
    if sid:
        s = Student.objects.get(pk=sid)
        hw_count = Assignment.objects.filter(
            class_course_assignments__class_course__class_group=s.class_group
        ).distinct().count() if s.class_group_id else 0
    else:
        hw_count = 0
    result = {
        "test_audit": {
            "exists": u is not None,
            "student_id": sid,
        },
        "questions": BaseQuestion.objects.count(),
        "courses": Course.objects.count(),
        "configs": SystemConfig.objects.count(),
        "assignments_for_test_audit": hw_count,
    }
    print(json.dumps(result, ensure_ascii=False))
    """)
    return _run_py(code)


def cmd_check_user(username: str) -> dict:
    """检查用户详情。"""
    safe_name = json.dumps(username)
    code = textwrap.dedent(f"""\
    from django.contrib.auth.models import User
    from courses.models import Assignment
    from accounts.models import Student
    u = User.objects.filter(username={safe_name}).first()
    if not u:
        print(json.dumps({{"exists": False}}, ensure_ascii=False))
    else:
        has_student = hasattr(u, 'student')
        sid = u.student.id if has_student else None
        hw = 0
        if has_student and sid:
            s = Student.objects.get(pk=sid)
            if s.class_group_id:
                hw = Assignment.objects.filter(
                    class_course_assignments__class_course__class_group=s.class_group
                ).distinct().count()
        print(json.dumps({{
            "exists": True,
            "id": u.id,
            "username": u.username,
            "has_student": has_student,
            "student_id": sid,
            "homework_count": hw,
        }}, ensure_ascii=False))
    """)
    return _run_py(code)


def cmd_count(table_alias: str) -> dict:
    """查表行数（支持别名）。"""
    table = TABLE_ALIASES.get(table_alias, table_alias)
    code = textwrap.dedent("""\
    from django.db import connection
    tbl = {table!r}
    with connection.cursor() as c:
        c.execute("SELECT COUNT(*) FROM " + tbl)
        row = c.fetchone()
        print(json.dumps({"table": tbl, "count": row[0]}, ensure_ascii=False))
    """)
    code = code.replace("{table!r}", repr(table))
    return _run_py(code)


def cmd_sql(sql: str) -> dict:
    """执行 SQL（读写均可，注意安全）。"""
    return _raw_sql(sql)


def cmd_dbshell():
    """交互式数据库控制台。"""
    cmd = [
        "ssh", "-t", ECS_HOST,
        f"cd {PROJECT_DIR} && {VENV_PY} manage.py dbshell",
    ]
    subprocess.run(cmd)
    return {"ok": True}


def cmd_models(model_name: str) -> dict:
    """查模型字段定义。"""
    safe_name = json.dumps(model_name)
    code = textwrap.dedent(f"""\
    import importlib, inspect
    from django.apps import apps
    models_found = [m for m in apps.get_models() if m.__name__.lower() == {safe_name}.lower()]
    if not models_found:
        print(json.dumps({{"ok": False, "error": f"Model '{model_name}' not found"}},
                         ensure_ascii=False))
    else:
        m = models_found[0]
        fields = [{{"name": f.name, "type": f.get_internal_type(),
                    "null": f.null, "db_column": f.db_column or f.column}}
                  for f in m._meta.fields]
        print(json.dumps({{
            "ok": True,
            "model": m.__name__,
            "table": m._meta.db_table,
            "fields": fields,
            "field_count": len(fields),
        }}, ensure_ascii=False))
    """)
    return _run_py(code)


def cmd_files(pattern: str = "*") -> dict:
    """列服务器上的文件。"""
    safe_pat = json.dumps(pattern)
    code = textwrap.dedent(f"""\
    import subprocess as sp, json
    r = sp.run(["find", {json.dumps(PROJECT_DIR)}, "-name", {safe_pat}, "-not", "-path", "*/venv/*"],
               capture_output=True, text=True, timeout=10)
    files = [ln.strip() for ln in r.stdout.strip().split(chr(10)) if ln.strip()]
    import os
    details = []
    for f in files:
        try:
            sz = os.path.getsize(f)
            details.append({{"path": f, "size": sz}})
        except:
            details.append({{"path": f, "size": -1}})
    print(json.dumps({{"ok": True, "files": details, "count": len(details)}}, ensure_ascii=False))
    """)
    return _run_py(code)


# ── CLI 入口 ──────────────────────────────────────────────


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__.strip())
        return

    cmd = sys.argv[1]
    as_json = "--json" in sys.argv
    if not as_json:
        print(LOGO)

    try:
        if cmd == "health":
            result = cmd_health()
        elif cmd == "check-user":
            username = sys.argv[2] if len(sys.argv) > 2 else "test_audit"
            result = cmd_check_user(username)
        elif cmd == "count":
            if len(sys.argv) < 3:
                print("用法: python ecs_query.py count <table_alias>")
                print("别名:", ", ".join(sorted(TABLE_ALIASES)))
                return
            result = cmd_count(sys.argv[2])
        elif cmd == "sql":
            sql = " ".join(sys.argv[2:])
            if not sql:
                print("用法: python ecs_query.py sql <SQL query>")
                return
            result = cmd_sql(sql)
        elif cmd == "dbshell":
            cmd_dbshell()
            return
        elif cmd == "models":
            name = sys.argv[2] if len(sys.argv) > 2 else ""
            if not name:
                print("用法: python ecs_query.py models <model_name>")
                return
            result = cmd_models(name)
        elif cmd == "files":
            pattern = sys.argv[2] if len(sys.argv) > 2 else "*"
            result = cmd_files(pattern)
        elif cmd == "verify":
            if len(sys.argv) < 3:
                print("用法: python ecs_query.py verify <模块号>")
                return
            mod = int(sys.argv[2])
            as_json = "--json" in sys.argv
            from data_db_verify import verify
            result = verify(mod)
            # 写入缓存文件
            cache_dir = os.path.join(os.path.dirname(__file__), ".verify_cache")
            os.makedirs(cache_dir, exist_ok=True)
            cache_path = os.path.join(cache_dir, f"module_{mod}.json")
            with open(cache_path, "w", encoding="utf-8") as f:
                json.dump(result, f, ensure_ascii=False, indent=2)
            if as_json:
                print(json.dumps(result, ensure_ascii=False, indent=2))
                return
            # 终端摘要
            print(f"模块 {mod} — 数据验证报告 (已缓存: {cache_path})")
            print('=' * 50)
            for fn, items in result["pages"].items():
                print(f'\n📄 {fn}')
                for it in items:
                    v = it["server_value"]
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
            return
        elif cmd == "page":
            if len(sys.argv) < 4:
                print("用法: python ecs_query.py page <模块号> <页面名.html>")
                return
            mod = int(sys.argv[2])
            page_name = sys.argv[3]
            cache_dir = os.path.join(os.path.dirname(__file__), ".verify_cache")
            cache_path = os.path.join(cache_dir, f"module_{mod}.json")
            if not os.path.exists(cache_path):
                print(f"缓存不存在，先运行: python ecs_query.py verify {mod}")
                return
            with open(cache_path) as f:
                data = json.load(f)
            pages = data.get("pages", {})
            if page_name not in pages:
                names = ", ".join(pages.keys())
                print(f"页面 '{page_name}' 不在缓存中。可用页面: {names}")
                return
            items = pages[page_name]
            for it in items:
                v = it["server_value"]
                if isinstance(v, list):
                    print(f'{it["path"]}: [{len(v)} 项]')
                    for x in v[:3]:
                        s = str(x)
                        print(f'  - {s[:120]}')
                    if len(v) > 3:
                        print(f'  ... {len(v)-3} more')
                elif isinstance(v, dict):
                    s = json.dumps(v, ensure_ascii=False)
                    print(f'{it["path"]}: {s[:120]}')
                else:
                    print(f'{it["path"]}: {v}')
            return
        else:
            print(f"未知命令: {cmd}")
            print(__doc__.strip())
            return

        print(json.dumps(result, ensure_ascii=False, indent=2))

    except subprocess.CalledProcessError as e:
        print(json.dumps({"ok": False, "error": f"SSH 失败: {e.stderr or e}"},
                         ensure_ascii=False, indent=2))
        sys.exit(1)
    except Exception as e:
        print(json.dumps({"ok": False, "error": str(e)},
                         ensure_ascii=False, indent=2))
        sys.exit(1)


if __name__ == "__main__":
    main()
