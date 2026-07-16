"""生成 app_version.dart — 从 pubspec.yaml 读取真实版本号"""
import re, sys
from pathlib import Path

def generate(app_dir: Path):
    pubspec = app_dir / 'pubspec.yaml'
    if not pubspec.exists():
        print(f'❌ 未找到: {pubspec}', file=sys.stderr)
        return False

    text = pubspec.read_text(encoding='utf-8')
    m = re.search(r'^version:\s*(\S+)', text, re.MULTILINE)
    if not m:
        print(f'❌ 未在 pubspec.yaml 中找到 version 字段', file=sys.stderr)
        return False

    version = m.group(1)
    out_dir = app_dir / 'lib' / 'constants'
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / 'app_version.dart'

    out_file.write_text(f"""/// App 版本号（自动生成 — 不要手动修改）
///
/// 来源: {pubspec.name} 中的 version 字段
/// 生成命令: python scripts/generate_version.py
const appVersion = '{version}';

/// API 基础 URL（支持环境切换）
const appBaseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'https://zhangyuzhixue.top/api/v1');

/// 服务端根域名
const appServerOrigin =
    String.fromEnvironment('SERVER_ORIGIN', defaultValue: 'https://zhangyuzhixue.top');
""")
    print(f'✅ {out_file} 已生成，version={version}')
    return True

if __name__ == '__main__':
    root = Path(__file__).resolve().parent.parent
    ok = True
    for name in ('flutter_app', 'teacher_app'):
        if not generate(root / name):
            ok = False
    sys.exit(0 if ok else 1)
