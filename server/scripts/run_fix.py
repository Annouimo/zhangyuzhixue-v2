#!/usr/bin/env python3
"""
章鱼智学 v2 — 数据库修复执行器

安全地在服务器上执行数据修复脚本，自动备份 + 执行 + 验证。

用法：
    # 本地执行（测试模式，不备份）：
    python scripts/run_fix.py strip_sq_artifacts --local

    # 服务器执行（生产模式，自动备份）：
    scp scripts/fixes/fix_*.py root@host:/tmp/fixes/
    scp scripts/run_fix.py root@host:/tmp/
    ssh root@host "python3 /tmp/run_fix.py strip_sq_artifacts --project /opt/zhangyuzhixue-v2/server"

    或单文件模式：
    ssh root@host "python3 /tmp/run_fix.py /tmp/my_fix.py --project /opt/zhangyuzhixue-v2/server"

修复脚本规范：
    scripts/fixes/fix_xxx.py 每个文件必须暴露两个函数：
        def fix(conn) -> dict:   # {'fixed': int, 'tables': [str]}
        def verify(conn) -> bool  # True = 通过

    conn 是 sqlite3.Connection，调用方传入，修复脚本不管理连接生命周期。
"""
import os
import sys
import gzip
import shutil
import sqlite3
import importlib.util
from datetime import datetime


# ── 路径推断 ──────────────────────────────────────────────

def _resolve_project_dir():
    """优先级: 环境变量 > __file__ 推测"""
    env_dir = os.environ.get('RUN_FIX_PROJECT')
    if env_dir:
        return env_dir
    here = os.path.dirname(os.path.abspath(__file__))
    if os.path.basename(here) == 'scripts':
        return os.path.normpath(os.path.join(here, '..'))
    return None


def _parse_args():
    args = sys.argv[1:]
    project_dir = _resolve_project_dir()
    module_name = None
    is_local = False

    i = 0
    while i < len(args):
        if args[i] == '--project' and i + 1 < len(args):
            project_dir = args[i + 1]
            i += 2
        elif args[i] == '--local':
            is_local = True
            i += 1
        else:
            module_name = args[i]
            i += 1

    return module_name, project_dir, is_local


# ── 备份 ─────────────────────────────────────────────────

def backup(db_path, backup_dir):
    """gzip 备份当前数据库"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    os.makedirs(backup_dir, exist_ok=True)
    bak_path = os.path.join(backup_dir, f'db.{timestamp}.sqlite3.gz')
    with open(db_path, 'rb') as f_in, gzip.open(bak_path, 'wb') as f_out:
        shutil.copyfileobj(f_in, f_out)
    size = os.path.getsize(bak_path)
    print(f'  ✅ 备份: {bak_path} ({size:,} bytes)')
    return bak_path


# ── 加载修复脚本 ─────────────────────────────────────────

def load_fix(fixes_dir, module_name):
    """加载修复脚本模块"""
    fix_path = os.path.join(fixes_dir, f'{module_name}.py')
    if not os.path.exists(fix_path):
        if os.path.exists(module_name):
            fix_path = module_name
        else:
            print(f'  ❌ 找不到修复脚本: {module_name}')
            print(f'     查找路径: {fix_path}')
            sys.exit(1)

    spec = importlib.util.spec_from_file_location('fix_module', fix_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)

    for required in ['fix', 'verify']:
        if not hasattr(mod, required):
            print(f'  ❌ 修复脚本缺少 {required}() 函数')
            sys.exit(1)

    return mod


# ── 校验 ─────────────────────────────────────────────────

def validate(mod):
    """可选预校验"""
    if hasattr(mod, 'validate'):
        print('  🔍 预校验...')
        ok, msg = mod.validate()
        if not ok:
            print(f'  ❌ 预校验未通过: {msg}')
            sys.exit(1)
        print(f'  ✅ 预校验通过: {msg}')
    else:
        print('  ⏭️  无预校验')


# ── 主流程 ──────────────────────────────────────────────

def main():
    module_name, project_dir, is_local = _parse_args()

    if not module_name or module_name.startswith('--'):
        print(__doc__)
        sys.exit(1)

    if not project_dir:
        print('  ❌ 无法自动推断项目目录')
        print('     请指定 --project /opt/zhangyuzhixue-v2/server')
        print('     或设置环境变量 RUN_FIX_PROJECT')
        sys.exit(1)

    db_path = os.path.join(project_dir, 'db.sqlite3')
    fixes_dir = os.path.join(project_dir, 'scripts', 'fixes')
    backup_dir = '/var/backups/zhangyuzhixue-v2/db/manual'

    print('=' * 50)
    print('章鱼智学 — 数据库修复执行器')
    print(f'  修复脚本: {module_name}')
    print(f'  模式: {"本地(测试)" if is_local else "生产"}')
    print(f'  数据库: {db_path}')
    print('=' * 50)

    if not os.path.exists(db_path):
        print(f'  ❌ 数据库不存在: {db_path}')
        sys.exit(1)

    # 1. 备份
    if not is_local:
        print('\n┌─ 备份数据库')
        backup(db_path, backup_dir)
    else:
        print('\n⏭️  本地模式，跳过备份')

    # 2. 加载
    print('\n┌─ 加载修复脚本')
    mod = load_fix(fixes_dir, module_name)

    # 3. 预校验
    print('\n┌─ 预校验')
    validate(mod)

    # 4. 执行修复
    print('\n┌─ 执行修复')
    conn = sqlite3.connect(db_path)
    conn.execute('PRAGMA journal_mode=OFF;')
    conn.execute('PRAGMA synchronous=OFF;')

    try:
        result = mod.fix(conn)
        conn.commit()
        fixed = result.get('fixed', 0)
        tables = result.get('tables', [])
        print(f'  ✅ 修复完成: {fixed} 行已修改')
        if tables:
            print(f'  📋 涉及表: {", ".join(tables)}')
    except Exception as e:
        conn.rollback()
        print(f'  ❌ 修复失败: {e}')
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        conn.close()

    # 5. 验证
    print('\n┌─ 验证')
    conn2 = sqlite3.connect(db_path)
    try:
        ok = mod.verify(conn2)
        if ok:
            print('  ✅ 验证通过')
        else:
            print('  ❌ 验证未通过')
            sys.exit(1)
    except Exception as e:
        print(f'  ❌ 验证异常: {e}')
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        conn2.close()

    print('\n' + '=' * 50)
    print(' ✅ 全部完成')
    print('=' * 50)


if __name__ == '__main__':
    main()
