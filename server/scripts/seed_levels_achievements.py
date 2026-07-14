"""Seed LevelConfig and AchievementDef on ECS. Run: python manage.py runscript seed_levels"""
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
os.environ['DJANGO_SETTINGS_MODULE'] = 'math_platform.settings'

import django  # noqa: E402
django.setup()

from system.models import LevelConfig, AchievementDef  # noqa: E402

# 15 级等级体系 — 对齐 HTML 原型 level_detail.html（0~650xp）
levels = [
    (1, 0.0, '青铜学徒', '🥉'),
    (2, 0.3, '青铜新手', '🥉'),
    (3, 0.6, '青铜达人', '🥉'),
    (4, 1.1, '白银学徒', '🥈'),
    (5, 1.7, '白银新手', '🥈'),
    (6, 2.5, '白银达人', '🥈'),
    (7, 3.6, '白银高手', '🥈'),
    (8, 5.1, '黄金学徒', '🥇'),
    (9, 7.1, '黄金新手', '🥇'),
    (10, 10.1, '黄金达人', '🥇'),
    (11, 14.6, '黄金高手', '🥇'),
    (12, 20.1, '铂金达人', '💎'),
    (13, 27.1, '钻石学霸', '🏆'),
    (14, 36.1, '大师传奇', '👑'),
    (15, 48.1, '巅峰王者', '🎯'),
]
for level, min_xp, title, emoji in levels:
    LevelConfig.objects.update_or_create(
        level=level, defaults={'min_xp': min_xp, 'title': title, 'icon_emoji': emoji})

achievements = [
    # 🔥 登录 — LOGIN
    ('FIRST_LOGIN', '开启旅程', '初次登录', 'LOGIN', '🔥 登录', 1, 'LOGIN_STREAK', 1, '🌱'),
    ('LOGIN_7', '一周佳话', '连续登录 7 天', 'LOGIN', '🔥 登录', 2, 'LOGIN_STREAK', 7, '⭐'),
    ('LOGIN_30', '满月全勤', '连续登录 30 天', 'LOGIN', '🔥 登录', 3, 'LOGIN_STREAK', 30, '🌟'),
    ('LOGIN_100', '百日筑基', '累计登录 100 天', 'LOGIN', '🔥 登录', 4, 'LOGIN_STREAK', 100, '🏆'),

    # 🎯 刷题 — PRACTICE
    ('PRACTICE_1', '破零', '完成第 1 题', 'PRACTICE', '🎯 刷题', 5, 'PRACTICE_COUNT', 1, '🎯'),
    ('PRACTICE_10', '小试牛刀', '完成 10 题', 'PRACTICE', '🎯 刷题', 6, 'PRACTICE_COUNT', 10, '🗡️'),
    ('PRACTICE_100', '百题斩', '完成 100 题', 'PRACTICE', '🎯 刷题', 7, 'PRACTICE_COUNT', 100, '🏅'),
    ('PRACTICE_500', '刷题王', '完成 500 题', 'PRACTICE', '🎯 刷题', 8, 'PRACTICE_COUNT', 500, '👑'),
    ('PRACTICE_1000', '千题不败', '完成 1000 题', 'PRACTICE', '🎯 刷题', 9, 'PRACTICE_COUNT', 1000, '💎'),

    # 💪 毅力 — STREAK
    ('STREAK_7', '持之以恒', '连续 7 天有做题记录', 'STREAK', '💪 毅力', 10, 'PRACTICE_STREAK', 7, '🔗'),
    ('STREAK_30', '月不间断', '连续 30 天有做题记录', 'STREAK', '💪 毅力', 11, 'PRACTICE_STREAK', 30, '📅'),

    # 🏆 精确度 — ACCURACY
    ('ACC_50', '初露锋芒', '累计正确率≥50%（需至少10题）', 'ACCURACY', '🏆 精确度', 12, 'ACCURACY_RATE', 50, '🎯'),
    ('ACC_70', '稳扎稳打', '累计正确率≥70%（需至少10题）', 'ACCURACY', '🏆 精确度', 13, 'ACCURACY_RATE', 70, '🎯'),
    ('ACC_90', '接近完美', '累计正确率≥90%（需至少10题）', 'ACCURACY', '🏆 精确度', 14, 'ACCURACY_RATE', 90, '🎯'),
    ('STREAK_CORRECT_5', '势如破竹', '连续对5题', 'ACCURACY', '🏆 精确度', 15, 'CONSECUTIVE_CORRECT', 5, '⚡'),
    ('STREAK_CORRECT_10', '十连斩', '连续对10题', 'ACCURACY', '🏆 精确度', 16, 'CONSECUTIVE_CORRECT', 10, '💥'),

    # 📝 组卷 — PAPER
    ('PAPER_1', '出题人', '创建第 1 张组卷', 'PAPER', '📝 组卷', 17, 'PAPER_COUNT', 1, '📝'),
    ('PAPER_5', '组卷达人', '创建 5 张组卷', 'PAPER', '📝 组卷', 18, 'PAPER_COUNT', 5, '✍️'),
    ('PAPER_10', '组卷大神', '创建 10 张组卷', 'PAPER', '📝 组卷', 19, 'PAPER_COUNT', 10, '👑'),

    # 🖊️ 评价 — RATING
    ('RATING_1', '鉴赏家', '首次为题目评分', 'RATING', '🖊️ 评价', 20, 'RATING_COUNT', 1, '🖊️'),
    ('RATING_10', '品题大师', '评分 10 次', 'RATING', '🖊️ 评价', 21, 'RATING_COUNT', 10, '✨'),
    ('RATING_50', '资深评委', '评分 50 次', 'RATING', '🖊️ 评价', 22, 'RATING_COUNT', 50, '🏅'),
]
# 当前种子中定义的 codes 集合
current_codes = {a[0] for a in achievements}

# 清理不在当前种子中的旧成就定义（如旧版 PRACTICE_50、PRACTICE_200）
old_codes = set(AchievementDef.objects.values_list('code', flat=True)) - current_codes
if old_codes:
    deleted, _ = AchievementDef.objects.filter(code__in=old_codes).delete()
    print(f'Deleted {deleted} old achievements: {sorted(old_codes)}')

for code, name, desc, cat, cl, order, trigger, threshold, emoji in achievements:
    AchievementDef.objects.update_or_create(
        code=code,
        defaults={
            'name': name,
            'description': desc,
            'category': cat,
            'category_label': cl,
            'display_order': order,
            'trigger_type': trigger,
            'threshold': threshold,
            'icon_emoji': emoji,
        })

level_count = LevelConfig.objects.count()
ach_count = AchievementDef.objects.count()
print(f'OK: LevelConfig={level_count}, AchievementDef={ach_count}')
