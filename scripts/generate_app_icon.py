"""生成章鱼智学 App 图标草稿（所有平台规格）"""
import math
import os
from PIL import Image, ImageDraw

PRIMARY = (20, 136, 247)    # #1488F7
WHITE = (255, 255, 255)
LIGHT = (234, 244, 255)     # #EAF4FF

OUT_DIR = r"D:\Hermes\zhangyuzhixue_app_v2\flutter_app"

# ── Android mipmap 规格 ──
ANDROID_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

# ── iOS 规格（文件名必须精确匹配 Contents.json）──
IOS_SIZES = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}

# ── macOS 规格 ──
MACOS_SIZES = {
    "app_icon_16": 16,
    "app_icon_32": 32,
    "app_icon_64": 64,
    "app_icon_128": 128,
    "app_icon_256": 256,
    "app_icon_512": 512,
    "app_icon_1024": 1024,
}

def draw_icon(size, corner_ratio=0.18):
    """绘制章鱼智学图标，size=最终像素"""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    r = int(size * corner_ratio)
    pad = int(size * 0.06)  # 安全边距

    # 1. 绘制圆角矩形背景
    draw.rounded_rectangle(
        [pad, pad, size - pad, size - pad],
        radius=r,
        fill=PRIMARY,
    )

    # 2. 绘制白色章鱼
    cx, cy = size // 2, size // 2
    s = size / 1024  # 缩放因子

    head_r = 160 * s
    eye_r = 18 * s
    pupil_r = 9 * s

    # 章鱼头（椭圆，稍扁）
    head_left = cx - head_r
    head_top = cy - head_r * 0.85
    head_right = cx + head_r
    head_bottom = cy + head_r * 0.75
    draw.ellipse([head_left, head_top, head_right, head_bottom], fill=WHITE)

    # 眼睛
    for ex in [-1, 1]:
        eye_cx = cx + ex * 52 * s
        eye_cy = int(cy - 18 * s)
        draw.ellipse(
            [eye_cx - eye_r, eye_cy - eye_r, eye_cx + eye_r, eye_cy + eye_r],
            fill=PRIMARY,
        )
        # 瞳孔（高光小白点）
        draw.ellipse(
            [eye_cx - pupil_r, eye_cy - pupil_r, eye_cx + pupil_r, eye_cy + pupil_r],
            fill=WHITE,
        )

    # 触手（左右各4条，从头部下方向外弧线然后收拢）
    tentacle_count = 8
    tentacle_start_y = int(cy + 65 * s)  # 从头部下方开始
    tentacle_length = 260 * s
    tentacle_width = 12 * s

    for i in range(tentacle_count):
        angle_offset = (i / tentacle_count) * math.pi
        # 触手角度：从 -75° 到 75°（相对于正下方）
        angle = -math.pi * 0.85 + (i / (tentacle_count - 1)) * (math.pi * 1.7)
        
        # 使用三次贝塞尔曲线绘制触手
        # P0: 起点（头部下方边缘）
        start_x = cx + math.sin(angle) * 80 * s
        start_y = tentacle_start_y
        
        # 中间控制点：向外扩散然后向下
        mid_angle = angle * 0.6
        cp1_x = cx + math.sin(angle) * (tentacle_length * 0.4)
        cp1_y = start_y + tentacle_length * 0.15
        
        cp2_x = cx + math.sin(angle) * (tentacle_length * 0.7)
        cp2_y = start_y + tentacle_length * 0.5
        
        # P3: 终点（触手尖端向内收）
        end_x = cx + math.sin(angle) * (tentacle_length * 0.25)
        end_y = start_y + tentacle_length * 0.9
        
        # 绘制触手（用粗线模拟）
        points = []
        for t in [j / 20 for j in range(21)]:
            # 三次贝塞尔
            bx = (1-t)**3 * start_x + 3*(1-t)**2*t * cp1_x + 3*(1-t)*t**2 * cp2_x + t**3 * end_x
            by = (1-t)**3 * start_y + 3*(1-t)**2*t * cp1_y + 3*(1-t)*t**2 * cp2_y + t**3 * end_y
            points.append((bx, by))
        
        # 用多段线绘制
        if len(points) > 1:
            draw.line(points, fill=WHITE, width=max(1, int(tentacle_width)))
            # 在尖端画一个小圆点作为圆头
            draw.ellipse(
                [end_x - tentacle_width//2, end_y - tentacle_width//2,
                 end_x + tentacle_width//2, end_y + tentacle_width//2],
                fill=WHITE,
            )

    # 3. 在触手下方画一个小书本或"学"字装饰
    # 改用简单的书本：两页重叠
    book_w = 70 * s
    book_h = 60 * s
    book_x = cx - book_w // 2
    book_y = int(cy + 160 * s)
    
    # 左页
    draw.rounded_rectangle(
        [book_x, book_y, book_x + book_w//2, book_y + book_h],
        radius=4*s, fill=WHITE,
    )
    # 右页
    draw.rounded_rectangle(
        [book_x + book_w//2 - 4*s, book_y, book_x + book_w, book_y + book_h],
        radius=4*s, fill=WHITE,
    )

    return img


def resize_keep(img, size):
    """等比缩放（使用 LANCZOS）"""
    return img.resize((size, size), Image.LANCZOS)


def _generate_for_app(master, app_label, base_dir):
    """为一个 Flutter App 生成所有平台图标"""
    # ── Android ──
    android_base = f"{base_dir}\\android\\app\\src\\main\\res"
    if os.path.isdir(android_base):
        for folder, px in ANDROID_SIZES.items():
            path = f"{android_base}\\{folder}\\ic_launcher.png"
            resize_keep(master, px).save(path)
            print(f"  ✓ {app_label} android {path} ({px}x{px})")

    # ── Windows ──
    ico_sizes = [32, 48, 64, 128, 256]
    ico_images = [resize_keep(master, s) for s in ico_sizes]
    ico_path = f"{base_dir}\\windows\\runner\\resources\\app_icon.ico"
    if os.path.isfile(ico_path) or os.path.isdir(os.path.dirname(ico_path)):
        ico_first = ico_images[0]
        ico_rest = ico_images[1:]
        ico_first.save(ico_path, format="ICO", sizes=[(s, s) for s in ico_sizes],
                       append_images=ico_rest)
        print(f"  ✓ {app_label} windows {ico_path}")

    # ── macOS ──
    macos_base = f"{base_dir}\\macos\\Runner\\Assets.xcassets\\AppIcon.appiconset"
    if os.path.isdir(macos_base):
        for name, px in MACOS_SIZES.items():
            path = f"{macos_base}\\{name}.png"
            resize_keep(master, px).save(path)
            print(f"  ✓ {app_label} macos {path} ({px}x{px})")

    # ── iOS ──
    ios_base = f"{base_dir}\\ios\\Runner\\Assets.xcassets\\AppIcon.appiconset"
    if os.path.isdir(ios_base):
        for name, px in IOS_SIZES.items():
            path = f"{ios_base}\\{name}"
            resize_keep(master, px).save(path)
            print(f"  ✓ {app_label} ios {path} ({px}x{px})")


if __name__ == "__main__":
    master = draw_icon(1024)
    
    print("=== 学生端 (flutter_app) ===")
    _generate_for_app(master, "student", r"D:\\Hermes\\zhangyuzhixue_app_v2\\flutter_app")
    
    print("\n=== 教师端 (teacher_app) ===")
    _generate_for_app(master, "teacher", r"D:\\Hermes\\zhangyuzhixue_app_v2\\teacher_app")
    
    print("\n✅ 全部图标已生成！")
