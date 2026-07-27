"""生成 app_version.dart + 同步 Inno Setup .iss 版本号。

平台版本保持纯数字（兼容 iOS），公测渠道通过 pubspec 中的
release_channel / release_iteration 独立维护。
"""

import re, sys
from pathlib import Path


def read_release(app_dir: Path) -> dict[str, str] | None:
    pubspec = app_dir / 'pubspec.yaml'
    if not pubspec.exists():
        print(f'ERROR: pubspec not found: {pubspec}', file=sys.stderr)
        return None
    text = pubspec.read_text(encoding='utf-8')
    m = re.search(r'^version:\s*(\S+)', text, re.MULTILINE)
    if not m:
        print(f'ERROR: version field not found in {pubspec}', file=sys.stderr)
        return None
    raw_version = m.group(1)
    version_parts = raw_version.split('+', 1)
    version = version_parts[0]
    build_number = version_parts[1] if len(version_parts) == 2 else '1'

    def read_optional(name: str, default: str) -> str:
        match = re.search(rf'^{name}:\s*(\S+)', text, re.MULTILINE)
        return match.group(1) if match else default

    return {
        'raw_version': raw_version,
        'version': version,
        'build_number': build_number,
        'channel': read_optional('release_channel', 'release'),
        'iteration': read_optional('release_iteration', '0'),
    }


def update_shared_app_version(root: Path, release: dict[str, str]) -> bool:
    """更新 shared 包中的 app_version.dart（单源版本文件）"""
    f = root / 'packages' / 'shared' / 'lib' / 'constants' / 'app_version.dart'
    f.parent.mkdir(parents=True, exist_ok=True)
    version = release['version']
    build_number = release['build_number']
    channel = release['channel']
    iteration = release['iteration']
    channel_labels = {'alpha': 'Alpha', 'beta': 'Beta', 'rc': 'RC'}
    if channel == 'release':
        display_version = version
    else:
        label = channel_labels.get(channel, channel)
        display_version = f'{version}（公测版 {label} {iteration}）'

    f.write_text(f"""/// App 版本号 — 从 pubspec.yaml 自动生成
///
/// 由 scripts/generate_version.py 自动覆盖。
/// 不要手动编辑。
class AppVersion {{
  AppVersion._();
  static const String version = '{version}';
  static const int buildNumber = {build_number};
  static const String releaseChannel = '{channel}';
  static const int releaseIteration = {iteration};
  static const String displayVersion = '{display_version}';
}}

/// 面向用户显示的版本字符串（自动生成）
const appVersion = AppVersion.displayVersion;

/// API 基础 URL（支持环境切换）
const appBaseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'https://zhangyuzhixue.zhtec123.com/api/v1');

/// 服务端根域名
const appServerOrigin =
    String.fromEnvironment('SERVER_ORIGIN', defaultValue: 'https://zhangyuzhixue.zhtec123.com');
""", encoding='utf-8', newline='\n')
    print(f'OK: generated {f}, version={release["raw_version"]}, channel={channel}.{iteration}')
    return True


def update_iss_file(iss_path: Path, release: dict[str, str]) -> bool:
    if not iss_path.exists():
        print(f'WARN: .iss file not found: {iss_path}', file=sys.stderr)
        return True  # 不视为错误
    text = iss_path.read_text(encoding='utf-8')
    version = release['version']
    channel = release['channel']
    iteration = release['iteration']
    release_label = version if channel == 'release' else f'{version}-{channel}.{iteration}'
    new_text, n = re.subn(
        r'(#define MyAppVersion )".*?"',
        rf'\1"{version}"',
        text,
    )
    if n == 0:
        print(f'WARN: MyAppVersion definition not found in {iss_path}')
        return False
    if n > 1:
        print(f'WARN: found {n} MyAppVersion definitions in {iss_path}; updated all')
    output_name = '章鱼智学-教师端' if 'teacher' in iss_path.name else '章鱼智学'
    new_text = re.sub(
        r'^OutputBaseFilename=.*$',
        f'OutputBaseFilename={output_name}-{release_label}-windows',
        new_text,
        flags=re.MULTILINE,
    )
    iss_path.write_text(new_text, encoding='utf-8', newline='\n')
    print(f'OK: updated {iss_path}, version={version}, label={release_label}')
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
    release = read_release(root / 'flutter_app')
    teacher_release = read_release(root / 'teacher_app')
    if release is None or teacher_release is None:
        ok = False
    elif release != teacher_release:
        print('ERROR: student and teacher release versions differ', file=sys.stderr)
        print(f'   student={release}', file=sys.stderr)
        print(f'   teacher={teacher_release}', file=sys.stderr)
        ok = False
    else:
        if not update_shared_app_version(root, release):
            ok = False
        # 同步 .iss 文件（Windows Installer）
        for name in ('flutter_app', 'teacher_app'):
            iss = APP_ISS_MAP.get(name)
            if iss and not update_iss_file(iss, release):
                ok = False

    sys.exit(0 if ok else 1)
