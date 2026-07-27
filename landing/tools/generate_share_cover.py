from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
IMAGES = ROOT / "assets" / "images"
OUT = IMAGES / "share-cover.jpg"


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    name = "msyhbd.ttc" if bold else "msyh.ttc"
    return ImageFont.truetype(str(Path("C:/Windows/Fonts") / name), size)


canvas = Image.new("RGB", (1200, 630), "#f7fbff")
px = canvas.load()
for y in range(canvas.height):
    for x in range(canvas.width):
        t = x / canvas.width
        u = y / canvas.height
        px[x, y] = (
            round(247 - 19 * t - 5 * u),
            round(251 - 41 * t - 9 * u),
            round(255 - 3 * t - 14 * u),
        )

overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
draw = ImageDraw.Draw(overlay)

# A restrained mathematical field inspired by the revised poster system.
for x in range(700, 1240, 58):
    draw.line((x, 0, x - 310, 630), fill=(45, 185, 255, 24), width=2)
for y in range(40, 680, 58):
    draw.line((650, y, 1200, y - 80), fill=(25, 122, 238, 18), width=2)
draw.ellipse((820, 45, 1190, 415), outline=(255, 255, 255, 92), width=4)
draw.ellipse((915, 135, 1095, 315), outline=(41, 196, 255, 90), width=3)
draw.arc((690, 260, 1170, 740), 190, 330, fill=(255, 255, 255, 105), width=7)

curve = []
for x in range(680, 1201, 8):
    dx = (x - 940) / 230
    y = 390 - 92 * (dx * dx) + 22 * dx
    curve.append((x, y))
draw.line(curve, fill=(255, 255, 255, 150), width=5)

overlay = overlay.filter(ImageFilter.GaussianBlur(0.25))
canvas = Image.alpha_composite(canvas.convert("RGBA"), overlay)

icon = Image.open(IMAGES / "icon-app.png").convert("RGB")
icon = icon.resize((136, 136), Image.Resampling.LANCZOS)
mask = Image.new("L", icon.size, 0)
ImageDraw.Draw(mask).rounded_rectangle((0, 0, 135, 135), radius=28, fill=255)
shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
shadow_mask = Image.new("L", canvas.size, 0)
ImageDraw.Draw(shadow_mask).rounded_rectangle((70, 65, 206, 201), radius=28, fill=100)
shadow_mask = shadow_mask.filter(ImageFilter.GaussianBlur(16))
shadow.paste((0, 80, 170, 80), (0, 0), shadow_mask)
canvas = Image.alpha_composite(canvas, shadow)
canvas.paste(icon, (70, 65), mask)

draw = ImageDraw.Draw(canvas)
draw.text((232, 72), "章鱼智学", font=font(60, True), fill="#0b2143")
draw.text((235, 151), "个性化高考数学智能学习系统", font=font(27), fill="#14558f")
draw.rounded_rectangle((70, 248, 530, 322), radius=14, fill="#087cf0")
draw.text((96, 260), "专注高考数学，让学习更高效", font=font(31, True), fill="white")
draw.text((72, 372), "软件 · 课程 · 规划 · 学习过程分析", font=font(28), fill="#173f69")
draw.text((72, 421), "从清晰的知识体系出发，建立自己的学习路径", font=font(24), fill="#426485")
draw.line((72, 518, 546, 518), fill="#74c9fa", width=3)
draw.text((72, 539), "zhangyuzhixue.top", font=font(24, True), fill="#0a68c8")

canvas.convert("RGB").save(OUT, quality=90, optimize=True, progressive=True)
print(OUT)
