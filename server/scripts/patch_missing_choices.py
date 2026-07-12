"""
补全30道选择题的选项（从旧版DB提取）。

旧版选项格式：
- 东城（10题）：A．xxx  B．xxx（全角顿号，双换行）
- 西城（10题）：A.xxx  B.xxx（英文句点，单换行）
- 朝阳（10题）：A.xxx  B.xxx（英文句点，单换行）

用法：
    python scripts/patch_missing_choices.py          # 执行
    python scripts/patch_missing_choices.py --dry    # 预览
"""
import os
import sys
import sqlite3
import json

server_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, server_dir)
os.chdir(server_dir)
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'math_platform.settings')
os.environ['DJANGO_ALLOW_ASYNC_UNSAFE'] = 'true'

import django  # noqa: E402
django.setup()

from qbank.models import BaseQuestion, ChoiceExt  # noqa: E402


def extract_options(question_text: str) -> dict | None:
    """从 question_text 中提取 A/B/C/D 选项，支持两种格式"""
    if not question_text:
        return None
    labels = ['A', 'B', 'C', 'D']
    opts = {}
    lines = question_text.split('\n')
    current_label = None
    for line in lines:
        ls = line.strip()
        if not ls:
            continue
        matched = False
        for lb in labels:
            # 格式1: A．xxx （全角顿号）
            # 格式2: A.xxx  （英文句点）
            for sep in ['．', '.']:
                prefix = f'{lb}{sep}'
                if ls.startswith(prefix):
                    opts[lb] = ls[len(prefix):].strip()
                    current_label = lb
                    matched = True
                    break
            if matched:
                break
        if not matched and current_label and lb in labels:
            # 续行：`A．$(-2,1)$` 下一行可能是空白，不需要续
            pass
    # 必须有至少3个选项才算有效
    if len(opts) >= 3:
        return opts
    return None


def main():
    dry_run = '--dry' in sys.argv

    # 找出无选项的选择题
    no_choice = BaseQuestion.objects.filter(question_type='choice').exclude(
        pk__in=ChoiceExt.objects.values_list('question_id', flat=True))
    print(f'需补齐: {no_choice.count()} 题')

    old_db = r'D:\Hermes\math_platform\db.sqlite3'
    if not os.path.exists(old_db):
        print(f'❌ 旧版DB不存在: {old_db}')
        return

    old = sqlite3.connect(old_db)
    success = 0

    for q in no_choice:
        old_q = old.execute(
            'SELECT id, question_text, answer_text FROM questions_question '
            'WHERE year=? AND exam=? AND district=? AND question_number=? AND question_type=?',
            (q.year, q.exam_type, q.region, q.number, '选择题')
        ).fetchone()

        if not old_q:
            print(f'  [{q.id}] {q.year} {q.exam_type} {q.region} Q{q.number} → 旧版未找到，跳过')
            continue

        opts = extract_options(old_q[1] or '')
        if not opts:
            print(f'  [{q.id}] {q.year} {q.exam_type} {q.region} Q{q.number} → 提取失败')
            # 输出样本便于调试
            print(f'    qt[:300]: {(old_q[1] or "")[:300]}')
            continue

        if dry_run:
            print(f'  [{q.id}] ✅ {json.dumps(opts, ensure_ascii=False)[:100]}')
        else:
            ChoiceExt.objects.create(question=q, options=opts)
            print(f'  [{q.id}] ✅ 已创建 ChoiceExt')
        success += 1

    old.close()
    print(f'\n共 {no_choice.count()} 题，{"预览" if dry_run else "补齐"} {success} 题')


if __name__ == '__main__':
    main()
