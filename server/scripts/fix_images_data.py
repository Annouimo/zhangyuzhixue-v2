"""
fix_images_data.py — 配图数据修复脚本

三步：
  1. 清空所有题目的 images 字段 + 从 stem 删除 <imgsrc=...> 标签
  2. 遍历 assets/questions/images/ 配图文件，按 (exam_type, year, region, number) 匹配重建
  3. 输出修复统计

用法：python server/scripts/fix_images_data.py
"""
import json, os, sys, re

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'math_platform.settings')
import django
django.setup()

from qbank.models import BaseQuestion

# ── 1. 扫描配图文件 ──
FLUTTER_ASSETS = r'D:\Hermes\zhangyuzhixue_app_v2\flutter_app\assets\questions\images'

image_map = {}  # (exam_type, year, region, number) → [file_paths]
for f in os.listdir(FLUTTER_ASSETS):
    if not f.endswith('.webp'):
        continue
    # Flat name: mock1_2023_haidian_q16.webp or gaokao_2020_q04.webp
    base = f.replace('.webp', '')
    for et in ('mock1', 'mock2', 'gaokao'):
        if base.startswith(et + '_'):
            rest = base[len(et)+1:]  # "2023_haidian_q16" or "2020_q04"
            if et == 'gaokao':
                # gaokao_2020_q04.webp → year=2020, region=北京, num=04
                year_str, qpart = rest.split('_', 1)
                region = '北京'
            else:
                # mock1_2023_haidian_q16.webp → year=2023, region=haidian, num=16
                parts = rest.split('_')
                year_str = parts[0]
                region = parts[1]
                qpart = '_'.join(parts[2:])  # q16 or q18-1
            year = int(year_str)
            qnum = qpart.replace('q', '')
            qnum_base = qnum.split('-')[0].lstrip('0') or '0'
            key = (et, year, region, qnum_base)
            image_map.setdefault(key, []).append(f)
            break

# Map flat filename exam_type back to DB exam_type (Chinese values)
ET_MAP = {'mock1': '一模', 'mock2': '二模', 'gaokao': '高考'}
image_map_db = {}
for (et, year, region, num), paths in image_map.items():
    db_et = ET_MAP.get(et, et)
    image_map_db[(db_et, year, region, num)] = paths
image_map = image_map_db

print(f'配图文件索引: {len(image_map)} 组, {sum(len(v) for v in image_map.values())} 文件')

# ── 2. 修复数据 ──
questions = BaseQuestion.objects.all()
total = questions.count()
img_tag_removed = 0
img_set = 0
img_cleared = 0

for q in questions:
    changed = False
    
    # 2a. 删除 stem 中的 <imgsrc=...> 标签
    old_stem = q.stem
    new_stem = re.sub(r'<imgsrc=\'[^\']*\'alt=\'[^\']*\'>\n?', '', old_stem)
    new_stem = re.sub(r'\n<imgsrc=\'[^\']*\'alt=\'[^\']*\'>', '', new_stem)
    new_stem = re.sub(r'<imgsrc=\'[^\']*\'alt=\'[^\']*\'>', '', new_stem)
    if new_stem != old_stem:
        q.stem = new_stem
        changed = True
        img_tag_removed += 1
    
    # 2b. 重建 images 字段
    key = (q.exam_type, q.year, q.region, q.number)
    matching = image_map.get(key, [])
    if matching:
        q.images = matching  # Django JSONField 存 Python 列表，自动序列化
        img_set += 1
    else:
        q.images = []  # Python 空列表，Django 序列化为 []
        img_cleared += 1
    
    changed = True  # always set images
    
    if changed:
        q.save(update_fields=['stem', 'images'])

# ── 3. 输出统计 ──
print(f'\n=== 修复完成 ===')
print(f'总题目数: {total}')
print(f'stem 中删除 <img> 标签: {img_tag_removed} 题')
print(f'配图字段已设置（匹配到配图文件）: {img_set} 题')
print(f'配图字段已清空（无配图文件）: {img_cleared} 题')

# 验证
print(f'\n=== 验证抽样 ===')
samples = BaseQuestion.objects.exclude(images=[]).order_by('?')[:5]
for q in samples:
    print(f'  Q{q.id} ({q.year} {q.exam_type} {q.region} #{q.number}): images={q.images}')
    if '<img' in q.stem:
        print(f'    ⚠ stem 仍有 <img> 残留!')

# 检查反斜杠
import django.db.models as M
bs_count = BaseQuestion.objects.filter(images__contains='\\').count()
print(f'\nimages 含反斜杠记录: {bs_count}')

# 检查高考配图
gk_count = BaseQuestion.objects.filter(
    exam_type='高考'
).exclude(images=[]).count()
print(f'高考题有配图: {gk_count}')

print('\n✅ 完成！现在可以运行 python server/scripts/build_assets.py 重建 assets.db')
