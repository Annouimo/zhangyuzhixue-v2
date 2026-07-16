"""从 JPG 源图生成 App 图标 — 替换 Android mipmap + Windows .ico"""
import sys
from pathlib import Path
from PIL import Image

SRC = Path(r'C:\Users\Annouimo\Desktop\微信图片_20260708225603_305_364.jpg')
ROOT = Path(r'D:\Hermes\zhangyuzhixue_app_v2')

# Android mipmap: size → density folder
ANDROID_SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}
ANDROID_BASE = 'flutter_app/android/app/src/main/res'
TEACHER_ANDROID = 'teacher_app/android/app/src/main/res'

# Windows ICO sizes
ICO_SIZES = [16, 32, 48, 256]

def process():
    if not SRC.exists():
        print(f'❌ 源图不存在: {SRC}', file=sys.stderr)
        return False

    img = Image.open(SRC)
    print(f'📷 源图: {img.size}, {img.mode}')

    # 居中裁剪为正方形
    size = min(img.width, img.height)
    left = (img.width - size) // 2
    top = (img.height - size) // 2
    square = img.crop((left, top, left + size, top + size))
    print(f'✂️ 裁剪为正方形: {square.size}')

    # 转为 RGBA
    if square.mode != 'RGBA':
        square = square.convert('RGBA')

    # === Android mipmap（学生端）===
    for folder, px in ANDROID_SIZES.items():
        dst = ROOT / ANDROID_BASE / folder / 'ic_launcher.png'
        dst.parent.mkdir(parents=True, exist_ok=True)
        resized = square.resize((px, px), Image.LANCZOS)
        resized.save(dst)
        print(f'✅ {dst.parent.name}/ic_launcher.png  {px}×{px}')

    # === Android mipmap（教师端）===
    for folder, px in ANDROID_SIZES.items():
        dst = ROOT / TEACHER_ANDROID / folder / 'ic_launcher.png'
        dst.parent.mkdir(parents=True, exist_ok=True)
        resized = square.resize((px, px), Image.LANCZOS)
        resized.save(dst)
        print(f'✅ teacher/{dst.parent.name}/ic_launcher.png  {px}×{px}')

    # === Windows .ico（学生端 + 教师端）===
    for app in ('flutter_app', 'teacher_app'):
        dst = ROOT / app / 'windows/runner/resources/app_icon.ico'
        dst.parent.mkdir(parents=True, exist_ok=True)
        # 为每个 ICO 尺寸生成独立帧
        ico_frames = [square.resize((s, s), Image.LANCZOS) for s in ICO_SIZES]
        ico_frames[0].save(
            dst, format='ICO',
            sizes=[(s, s) for s in ICO_SIZES],
            append_images=ico_frames[1:],
        )
        print(f'✅ {app}/windows/runner/resources/app_icon.ico')

    return True

if __name__ == '__main__':
    sys.exit(0 if process() else 1)
