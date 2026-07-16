"""从已有图标生成全平台 App 图标 + splash logo（源图不存在时 fallback）"""
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(r'D:\Hermes\zhangyuzhixue_app_v2')

# 源图候选
SRC_CANDIDATES = [
    Path(r'C:\Users\Annouimo\Desktop\微信图片_20260708225603_305_364.jpg'),
    ROOT / 'flutter_app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
]

# Android mipmap
ANDROID_SIZES = {'mipmap-mdpi': 48, 'mipmap-hdpi': 72, 'mipmap-xhdpi': 96,
                 'mipmap-xxhdpi': 144, 'mipmap-xxxhdpi': 192}
ANDROID_RES = 'flutter_app/android/app/src/main/res'
TEACHER_RES = 'teacher_app/android/app/src/main/res'

# Windows ICO
ICO_SIZES = [16, 32, 48, 256]

# iOS
IOS_ICONS = [
    ('Icon-App-20x20@2x.png', 40), ('Icon-App-20x20@3x.png', 60),
    ('Icon-App-29x29@1x.png', 29), ('Icon-App-29x29@2x.png', 58), ('Icon-App-29x29@3x.png', 87),
    ('Icon-App-40x40@1x.png', 40), ('Icon-App-40x40@2x.png', 80), ('Icon-App-40x40@3x.png', 120),
    ('Icon-App-60x60@2x.png', 120), ('Icon-App-60x60@3x.png', 180),
    ('Icon-App-76x76@1x.png', 76), ('Icon-App-76x76@2x.png', 152),
    ('Icon-App-83.5x83.5@2x.png', 167), ('Icon-App-1024x1024@1x.png', 1024),
]
IOS_DIR = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'

# macOS
MACOS_ICONS = [
    ('app_icon_16.png', 16), ('app_icon_32.png', 32), ('app_icon_64.png', 64),
    ('app_icon_128.png', 128), ('app_icon_256.png', 256),
    ('app_icon_512.png', 512), ('app_icon_1024.png', 1024),
]
MACOS_DIR = 'macos/Runner/Assets.xcassets/AppIcon.appiconset'


def _load_square() -> Image.Image:
    for p in SRC_CANDIDATES:
        if p.exists():
            img = Image.open(p)
            print(f'📷 源图: {p.name}  {img.size}')
            sz = min(img.width, img.height)
            l, t = (img.width - sz) // 2, (img.height - sz) // 2
            sq = img.crop((l, t, l + sz, t + sz))
            return sq.convert('RGBA') if sq.mode != 'RGBA' else sq
    print('❌ 无可用源图', file=sys.stderr)
    sys.exit(1)


def process():
    square = _load_square()
    print(f'✂️ 正方形: {square.size}')

    # === Android mipmap ===
    for app, res_base in [('flutter_app', ANDROID_RES), ('teacher_app', TEACHER_RES)]:
        for folder, px in ANDROID_SIZES.items():
            dst = ROOT / app / res_base / folder / 'ic_launcher.png'
            dst.parent.mkdir(parents=True, exist_ok=True)
            square.resize((px, px), Image.LANCZOS).save(dst)
        print(f'✅ {app}: Android mipmap ×{len(ANDROID_SIZES)}')

    # === Windows .ico ===
    for app in ('flutter_app', 'teacher_app'):
        dst = ROOT / app / 'windows/runner/resources/app_icon.ico'
        dst.parent.mkdir(parents=True, exist_ok=True)
        frames = [square.resize((s, s), Image.LANCZOS) for s in ICO_SIZES]
        frames[0].save(dst, format='ICO', sizes=[(s, s) for s in ICO_SIZES],
                       append_images=frames[1:])
        print(f'✅ {app}: Windows .ico')

    # === iOS AppIcon ===
    for app in ('flutter_app', 'teacher_app'):
        d = ROOT / app / IOS_DIR
        d.mkdir(parents=True, exist_ok=True)
        for name, px in IOS_ICONS:
            square.resize((px, px), Image.LANCZOS).save(d / name)
        print(f'✅ {app}: iOS AppIcon ×{len(IOS_ICONS)}')

    # === macOS AppIcon（仅学生端）===
    if (ROOT / 'flutter_app' / MACOS_DIR).parent.exists():
        d = ROOT / 'flutter_app' / MACOS_DIR
        d.mkdir(parents=True, exist_ok=True)
        for name, px in MACOS_ICONS:
            square.resize((px, px), Image.LANCZOS).save(d / name)
        print(f'✅ flutter_app: macOS AppIcon ×{len(MACOS_ICONS)}')

    # === Android splash logo ===
    for app, res_base in [('flutter_app', ANDROID_RES), ('teacher_app', TEACHER_RES)]:
        dst = ROOT / app / res_base / 'drawable' / 'splash_logo.png'
        dst.parent.mkdir(parents=True, exist_ok=True)
        square.resize((256, 256), Image.LANCZOS).save(dst)
        print(f'✅ {app}: splash_logo.png 256×256')

    return True


if __name__ == '__main__':
    sys.exit(0 if process() else 1)
