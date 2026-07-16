"""生成 app_version.dart + 同步 Inno Setup .iss 版本号
从 pubspec.yaml 读取真实版本号，只维护 shared 包中的单源版本文件。"""

import re, sys
from pathlib import Path


def read_version(app_dir: Path) -> str | None:
    pubspec = app_dir / 'pubspec.yaml'
    if not pubspec.exists():
        print(f'❌ 未找到: {pubspec}', file=sys.stderr)
        return None
    text = pubspec.read_text(encoding='utf-8')
    m = re.search(r'^version:\s*(\S+)', text, re.MULTILINE)
    if not m:
        print(f'❌ 未在 {pubspec} 中找到 version 字段', file=sys.stderr)
        return None
    return m.group(1)


def update_shared_app_version(root: Path, version: str) -> bool:
    """更新 shared 包中的 app_version.dart（单源版本文件）"""
    f = root / 'packages' / 'shared' / 'lib' / 'constants' / 'app_version.dart'
    f.parent.mkdir(parents=True, exist_ok=True)
    f.write_text(f"""/// App 版本号 — 从 pubspec.yaml 自动生成
///
/// 由 scripts/generate_version.py 自动覆盖。
/// 不要手动编辑。
class AppVersion {{
  AppVersion._();
  static const String version = '{version}';
  static const String buildEnv = 'release';
}}

/// App 版本号字符串（自动生成）
const appVersion = '{version}';

/// API 基础 URL（支持环境切换）
const appBaseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'https://zhangyuzhixue.top/api/v1');

/// 服务端根域名
const appServerOrigin =
    String.fromEnvironment('SERVER_ORIGIN', defaultValue: 'https://zhangyuzhixue.top');
""")
    print(f'✅ {f} 已生成，version={version}')
    return True


def update_iss_file(iss_path: Path, version: str) -> bool:
    if not iss_path.exists():
        print(f'⚠️  未找到 .iss 文件: {iss_path}', file=sys.stderr)
        return True  # 不视为错误
    text = iss_path.read_text(encoding='utf-8')
    new_text, n = re.subn(
        r'(#define MyAppVersion )".*?"',
        rf'\1"{version}"',
        text,
    )
    if n == 0:
        print(f'⚠️  未在 {iss_path} 中找到 MyAppVersion 定义')
        return False
    if n > 1:
        print(f'⚠️  {iss_path} 中发现 {n} 处 MyAppVersion，已全部更新')
    iss_path.write_text(new_text, encoding='utf-8')
    print(f'✅ {iss_path} 已同步 version={version}')
    return True


# ── 映射表：app 名 → .iss 文件路径 ──
ISSUES_DIR = Path(__file__).resolve().parent.parent / 'docs' / '07-工作流'
APP_ISS_MAP = {
    'flutter_app': ISSUES_DIR / 'build_script_student.iss',
    'teacher_app': ISSUES_DIR / 'build_script_teacher.iss',
}

if __name__ == '__main__':
    root = Path(__file__).resolve().parent.parent
    ok = True

    # 以 flutter_app 版本为基准更新 shared 包
    version = read_version(root / 'flutter_app')
    if version is None:
        ok = False
    else:
        if not update_shared_app_version(root, version):
            ok = False
        # 同步 .iss 文件（Windows Installer）
        for name in ('flutter_app', 'teacher_app'):
            iss = APP_ISS_MAP.get(name)
            if iss and not update_iss_file(iss, version):
                ok = False

    sys.exit(0 if ok else 1)
