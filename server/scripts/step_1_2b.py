"""
Phase 1.2b — 题目主表迁移（按试卷重新分配 ID）

排序规则:
  year:       升序 2020→2026
  exam_type:  一模(1)→二模(2)→高考(3)
  district:   东城(1)→西城(2)→朝阳(3)→海淀(4)→北京(5)
  题号:       升序 1→21

字段映射与产出见文件头部完整说明。
"""
import csv
import json
import os
import sqlite3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'math_platform.settings')
import django
django.setup()

from qbank.models import BaseQuestion

OLD_DB = Path(r'D:\Hermes\math_platform\db.sqlite3')
AUDIT_DIR = Path(__file__).resolve().parent.parent / 'migration_audit'
AUDIT_DIR.mkdir(parents=True, exist_ok=True)

EXAM_ORDER = {'一模': 1, '二模': 2, '高考': 3}
DISTRICT_ORDER = {'东城': 1, '西城': 2, '朝阳': 3, '海淀': 4, '北京': 5}
QTYPE_MAP = {'选择题': 'choice', '填空题': 'fill', '解答题': 'solution'}


def sort_key(r):
    return (r[1] or 0, EXAM_ORDER.get(r[2], 9), DISTRICT_ORDER.get(r[3], 9), r[4] or 0)


def dump_old(conn):
    cur = conn.cursor()
    cur.execute("""
        SELECT id, year, exam, district, question_number, question_type,
               difficulty, workload, score, question_text, answer_text,
               answer_source, visibility, created_at, updated_at
        FROM questions_question
        WHERE year != 2099
        ORDER BY id
    """)
    rows = cur.fetchall()
    print(f"旧版题目 (排除 year=2099): {len(rows)} 条")

    cols = ['id', 'year', 'exam', 'district', 'question_number',
            'question_type', 'difficulty', 'workload', 'score',
            'question_text', 'answer_text', 'answer_source',
            'visibility', 'created_at', 'updated_at']
    with open(AUDIT_DIR / 'old_questions.csv', 'w', newline='',
              encoding='utf-8-sig') as f:
        csv.writer(f).writerow(cols); csv.writer(f).writerows(rows)
    print(f"old_questions.csv: {len(rows)} 行")

    rows.sort(key=sort_key)
    return rows


def run_migrate(rows):
    BaseQuestion.objects.all().delete()
    id_map, answer_map = {}, {}
    for r in rows:
        q = BaseQuestion.objects.create(
            year=r[1], exam_type=r[2] or '', region=r[3] or '',
            number=str(r[4]) if r[4] else '',
            question_type=QTYPE_MAP.get(r[5], 'choice'),
            difficulty=r[6], calculation=r[7], default_score=r[8],
            stem=r[9] or '', images=[],
        )
        id_map[r[0]] = q.id
        answer_map[r[0]] = r[10] or ''
    print(f"BaseQuestion 总数: {BaseQuestion.objects.count()}")
    return id_map, answer_map


def dump_new(rows, id_map, answer_map):
    new_rows, mapping_rows = [], []
    for r in rows:
        oid = r[0]; nid = id_map.get(oid)
        if nid is None: continue
        q = BaseQuestion.objects.get(id=nid)
        new_rows.append([q.id, q.year, q.exam_type, q.region, q.number,
                         q.question_type, q.difficulty, q.calculation,
                         q.default_score, q.stem[:200]])
        mapping_rows.append([oid, nid, r[5], q.question_type,
                             r[1], q.year, r[2], q.exam_type,
                             r[3], q.region, r[4], q.number,
                             r[6], q.difficulty, r[7], q.calculation,
                             (r[10] or '')[:80]])

    with open(AUDIT_DIR / 'new_questions.csv', 'w', newline='',
              encoding='utf-8-sig') as f:
        csv.writer(f).writerow(['id', 'year', 'exam_type', 'region', 'number',
                                'question_type', 'difficulty', 'calculation',
                                'default_score', 'stem_preview'])
        csv.writer(f).writerows(new_rows)
    print(f"new_questions.csv: {len(new_rows)} 行")

    mc = ['old_id', 'new_id', 'old_question_type', 'new_question_type',
          'old_year', 'new_year', 'old_exam', 'new_exam_type',
          'old_district', 'new_region', 'old_number', 'new_number',
          'old_difficulty', 'new_difficulty', 'old_workload', 'new_calculation',
          'old_answer_text']
    with open(AUDIT_DIR / 'question_field_mapping.csv', 'w', newline='',
              encoding='utf-8-sig') as f:
        csv.writer(f).writerow(mc); csv.writer(f).writerows(mapping_rows)
    print(f"question_field_mapping.csv: {len(mapping_rows)} 行")

    (AUDIT_DIR / 'old_id_to_new_map.json').write_text(
        json.dumps(id_map, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f"old_id_to_new_map.json: {len(id_map)} 条")
    (AUDIT_DIR / 'answer_text_map.json').write_text(
        json.dumps(answer_map, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f"answer_text_map.json: {len(answer_map)} 条")

    # 用 enumerate 正确计算 ID 分配
    alloc = ["新 id 分配明细", "=" * 50, ""]
    prev_key, start_id, start_idx = None, None, None
    for i, r in enumerate(rows):
        key = (r[1], r[2], r[3])
        nid = id_map[r[0]]
        if key != prev_key:
            if prev_key is not None:
                end_id = id_map[rows[i-1][0]]
                alloc.append(f"  {prev_key[0]} {prev_key[1]} {prev_key[2]}: "
                             f"id {start_id}-{end_id} ({end_id - start_id + 1}题)")
            prev_key, start_id, start_idx = key, nid, i
    # 最后一份
    if prev_key:
        end_id = id_map[rows[-1][0]]
        alloc.append(f"  {prev_key[0]} {prev_key[1]} {prev_key[2]}: "
                     f"id {start_id}-{end_id} ({end_id - start_id + 1}题)")
    (AUDIT_DIR / 'id_allocation.txt').write_text('\n'.join(alloc), encoding='utf-8')
    print("id_allocation.txt: 已生成")


def write_stats(rows, id_map):
    lines = [
        "=" * 50, "Phase 1.2b 迁移统计", "=" * 50, "",
        f"旧版题目 (排除 2099):   {len(rows)}",
        f"新版 BaseQuestion:     {BaseQuestion.objects.count()}",
        "排序规则: year↑ 一模→二模→高考 东城→西城→朝阳→海淀→北京 题号↑",
        f"id 映射:               {len(id_map)} 条", "",
        "审核文件:",
        f"  {AUDIT_DIR / 'id_allocation.txt'}",
        f"  {AUDIT_DIR / 'old_questions.csv'}",
        f"  {AUDIT_DIR / 'new_questions.csv'}",
        f"  {AUDIT_DIR / 'question_field_mapping.csv'}",
        f"  {AUDIT_DIR / 'old_id_to_new_map.json'}",
        f"  {AUDIT_DIR / 'answer_text_map.json'}",
    ]
    (AUDIT_DIR / 'step_1_2b_stats.txt').write_text('\n'.join(lines), encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    conn = sqlite3.connect(str(OLD_DB))
    print("1. 转储旧版 + 排序...")
    rows = dump_old(conn); conn.close()
    print("\n2. 执行迁移...")
    id_map, answer_map = run_migrate(rows)
    print("\n3. 转储新版...")
    dump_new(rows, id_map, answer_map)
    print("\n4. 统计...")
    write_stats(rows, id_map)
    print("\n完成，审核文件在 server/migration_audit/")
