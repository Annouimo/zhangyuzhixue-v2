"""从已有图标生成全平台 App 图标 + splash logo（源图不存在时 fallback）"""
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(r'D:\Hermes\zhangyuzhixue_app_v2')

# 源图候选
SRC_CANDIDATES = [
    ROOT / 'docs/00-整体情况/icon_final_1024.png',
    ROOT / 'docs/00-整体情况/icon_final.png',
    Path(r'C:\Users\Annouimo\Desktop\微信图片_20260708225603_305_364.jpg'),
    ROOT / 'flutter_app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
]

# Splash logo 源图（透明白底 Logo，放在品牌蓝背景上）
SPLASH_SOURCE = ROOT / 'docs/00-整体情况/logo_mark_reverse_2048.png'

# Android mipmap: density folder → px
ANDROID_SIZES = {'mipmap-mdpi': 48, 'mipmap-hdpi': 72, 'mipmap-xhdpi': 96,
                 'mipmap-xxhdpi': 144, 'mipmap-xxxhdpi': 192}
ANDROID_MIPMAP = 'android/app/src/main/res'
TEACHER_MIPMAP = 'android/app/src/main/res'

# Windows ICO
ICO_SIZES = [16, 32, 48, 256]
WINDOWS_ICO = 'windows/runner/resources/app_icon.ico'

# iOS: (filename, pixel_size)
IOS_ICONS = [
    ('Icon-App-20x20@2x.png', 40), ('Icon-App-20x20@3x.png', 60),
    ('Icon-App-29x29@1x.png', 29), ('Icon-App-29x29@2x.png', 58), ('Icon-App-29x29@3x.png', 87),
    ('Icon-App-40x40@1x.png', 40), ('Icon-App-40x40@2x.png', 80), ('Icon-App-40x40@3x.png', 120),
    ('Icon-App-60x60@2x.png', 120), ('Icon-App-60x60@3x.png', 180),
    ('Icon-App-76x76@1x.png', 76), ('Icon-App-76x76@2x.png', 152),
    ('Icon-App-83.5x83.5@2x.png', 167), ('Icon-App-1024x1024@1x.png', 1024),
]
IOS_DIR = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'

# macOS: (filename, pixel_size)
MACOS_ICONS = [
    ('app_icon_16.png', 16), ('app_icon_32.png', 32), ('app_icon_64.png', 64),
    ('app_icon_128.png', 128), ('app_icon_256.png', 256),
    ('app_icon_512.png', 512), ('app_icon_1024.png', 1024),
]
MACOS_DIR = 'macos/Runner/Assets.xcassets/AppIcon.appiconset'

# Splash logo
SPLASH_LOGO = 'android/app/src/main/res/drawable/splash_logo.png'


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


def _save(path: Path, img: Image.Image, px: int, label: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.resize((px, px), Image.LANCZOS).save(path)
    print(f'✅ {label}')


def process():
    square = _load_square()
    print(f'✂️ 正方形: {square.size}')

    apps = ['flutter_app', 'teacher_app']

    for app in apps:
        mipmap_base = ROOT / app / ANDROID_MIPMAP
        for folder, px in ANDROID_SIZES.items():
            _save(mipmap_base / folder / 'ic_launcher.png', square, px,
                  f'{app}: {folder}/ic_launcher.png')
        print(f'  → Android mipmap ×{len(ANDROID_SIZES)} 完成')

    for app in apps:
        ico_path = ROOT / app / WINDOWS_ICO
        ico_path.parent.mkdir(parents=True, exist_ok=True)
        # Pillow 的 ICO 多帧保存不可靠，手动构造多分辨率 ICO
        import struct, io
        ico_sizes = ICO_SIZES  # [16, 32, 48, 256]
        frames_data = []
        for s in ico_sizes:
            buf = io.BytesIO()
            square.resize((s, s), Image.LANCZOS).save(buf, format='PNG')
            frames_data.append(buf.getvalue())
        # ICO header: reserved(2) + type(2) + count(2)
        header = struct.pack('<HHH', 0, 1, len(frames_data))
        # Directory entries + image data
        offset = 6 + 16 * len(frames_data)  # header + all dir entries
        dir_entries = b''
        image_data = b''
        for i, s in enumerate(ico_sizes):
            data = frames_data[i]
            # Windows ICO directory entry: w(1) h(1) colors(1) reserved(1) planes(2) bpp(2) size(4) offset(4)
            w = 0 if s >= 256 else s  # 0 means 256 for w/h in ICO spec
            h = 0 if s >= 256 else s
            entry = struct.pack('<BBBBHHII', w, h, 0, 0, 1, 32, len(data), offset)
            dir_entries += entry
            image_data += data
            offset += len(data)
        ico_path.write_bytes(header + dir_entries + image_data)
        print(f'✅ {app}: app_icon.ico ({len(frames_data)} frames)')

    for app in apps:
        ios_dir = ROOT / app / IOS_DIR
        ios_dir.mkdir(parents=True, exist_ok=True)
        for name, px in IOS_ICONS:
            _save(ios_dir / name, square, px,
                  f'{app}: iOS/{name}')
        print(f'  → iOS AppIcon ×{len(IOS_ICONS)} 完成')

    # macOS 仅学生端
    macos_dir = ROOT / 'flutter_app' / MACOS_DIR
    if macos_dir.parent.exists():
        macos_dir.mkdir(parents=True, exist_ok=True)
        for name, px in MACOS_ICONS:
            _save(macos_dir / name, square, px,
                  f'flutter_app: macOS/{name}')
        print(f'  → macOS AppIcon ×{len(MACOS_ICONS)} 完成')

    splash_sq = Image.open(SPLASH_SOURCE).convert('RGBA')
    sz = min(splash_sq.width, splash_sq.height)
    l, t = (splash_sq.width - sz) // 2, (splash_sq.height - sz) // 2
    splash_sq = splash_sq.crop((l, t, l + sz, t + sz))
    for app in apps:
        _save(ROOT / app / SPLASH_LOGO, splash_sq, 256,
              f'{app}: splash_logo.png')

    return True


if __name__ == '__main__':
    sys.exit(0 if process() else 1)
