"""Seed LevelConfig and AchievementDef on ECS. Run: python manage.py runscript seed_levels"""
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
os.environ['DJANGO_SETTINGS_MODULE'] = 'math_platform.settings'

import django  # noqa: E402
django.setup()

from system.models import LevelConfig, AchievementDef  # noqa: E402

levels = [
    (1, 0, '青铜学徒', '🥉'),
    (2, 100, '白银新手', '🥈'),
    (3, 300, '黄金高手', '🥇'),
    (4, 600, '铂金达人', '💎'),
    (5, 1000, '钻石学霸', '🏆'),
    (6, 1500, '大师传奇', '👑'),
    (7, 2200, '数学宗师', '🌟'),
    (8, 3000, '巅峰王者', '🎯'),
]
for level, min_xp, title, emoji in levels:
    _, created = LevelConfig.objects.get_or_create(
        level=level, defaults={'min_xp': min_xp, 'title': title, 'icon_emoji': emoji})

achievements = [
    ('FIRST_LOGIN', '初次登录', '完成第一次登录', 'LOGIN', '🔥 登录', 1, 'LOGIN_STREAK', 1),
    ('LOGIN_7', '坚持一周', '累计签到7天', 'LOGIN', '🔥 登录', 2, 'LOGIN_STREAK', 7),
    ('LOGIN_30', '月度达人', '累计签到30天', 'LOGIN', '🔥 登录', 3, 'LOGIN_STREAK', 30),
    ('LOGIN_100', '百天冲刺', '累计签到100天', 'LOGIN', '🔥 登录', 4, 'LOGIN_STREAK', 100),
    ('PRACTICE_1', '开张有礼', '完成第1道题', 'PRACTICE', '✏️ 练习', 5, 'PRACTICE_COUNT', 1),
    ('PRACTICE_10', '小试牛刀', '完成10道题', 'PRACTICE', '✏️ 练习', 6, 'PRACTICE_COUNT', 10),
    ('PRACTICE_50', '渐入佳境', '完成50道题', 'PRACTICE', '✏️ 练习', 7, 'PRACTICE_COUNT', 50),
    ('PRACTICE_200', '刷题达人', '完成200道题', 'PRACTICE', '✏️ 练习', 8, 'PRACTICE_COUNT', 200),
    ('PRACTICE_500', '题海无涯', '完成500道题', 'PRACTICE', '✏️ 练习', 9, 'PRACTICE_COUNT', 500),
    ('RATING_1', '初试评分', '给第1道题评分', 'RATING', '⭐ 评分', 10, 'RATING_COUNT', 1),
    ('RATING_10', '评分达人', '给10道题评分', 'RATING', '⭐ 评分', 11, 'RATING_COUNT', 10),
    ('RATING_50', '资深评委', '给50道题评分', 'RATING', '⭐ 评分', 12, 'RATING_COUNT', 50),
]
for code, name, desc, cat, cl, order, trigger, threshold in achievements:
    AchievementDef.objects.get_or_create(
        code=code,
        defaults={
            'name': name,
            'description': desc,
            'category': cat,
            'category_label': cl,
            'display_order': order,
            'trigger_type': trigger,
            'threshold': threshold,
        })

level_count = LevelConfig.objects.count()
ach_count = AchievementDef.objects.count()
print(f'OK: LevelConfig={level_count}, AchievementDef={ach_count}')
