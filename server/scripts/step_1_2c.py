"""
Phase 1.2c — 题目-概念标签关联迁移

从旧版 questions_question_concept_tags（2247 条）导入新版 QuestionConceptTag。
通过名称交叉引用建立旧→新 tag id 映射（不依赖 1.2a 的运行时状态）。

产出 (server/migration_audit/):
  old_q_tags.csv           — 旧版 2247 条关联（含标签名）
  new_q_tags.csv           — 新版全部 QuestionConceptTag
  q_tag_mapping.csv        — 旧 question_id + 标签名 → 新 question_id + 标签名
  tag_id_cross_ref.json    — 旧 tag_id → 新 tag_id 映射
  step_1_2c_stats.txt     — 统计摘要
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

from qbank.models import BaseQuestion, ConceptTag, QuestionConceptTag

OLD_DB = Path(r'D:\Hermes\math_platform\db.sqlite3')
AUDIT_DIR = Path(__file__).resolve().parent.parent / 'migration_audit'


def load_old_tag_map():
    """从 old_concept_tags.json 加载旧版标签名 → id 映射"""
    old = json.loads((AUDIT_DIR / 'old_concept_tags.json').read_text(encoding='utf-8'))
    tag_name_to_oid = {}  # name → old_id
    for t in old['concepttag']:
        tag_name_to_oid[t['name']] = t['old_id']
    return tag_name_to_oid


def build_tag_id_cross_ref():
    """
    通过名称交叉引用建立旧 tag_id → 新 tag_id 映射。
    注意: 旧 id=23 '常熟列' 在新版中为 '常数列'（清洗修正）。
    """
    name_rev = {  # 旧名→新名的修正映射
        '常熟列': '常数列',
    }
    old_name_to_oid = load_old_tag_map()
    cross = {}

    for new_tag in ConceptTag.objects.all():
        old_name = None
        for on, oid in old_name_to_oid.items():
            fixed = name_rev.get(on, on)
            if fixed == new_tag.name:
                old_name = on
                cross[oid] = new_tag.id
                break

    print(f"tag_id_cross_ref: {len(cross)} 个旧标签映射到新标签")
    # 检查缺失
    missing = set(old_name_to_oid.values()) - set(cross.keys())
    if missing:
        print(f"⚠️  未映射的旧 tag_id: {missing}")

    (AUDIT_DIR / 'tag_id_cross_ref.json').write_text(
        json.dumps(cross, ensure_ascii=False, indent=2), encoding='utf-8')
    return cross


def load_qid_map():
    return json.loads((AUDIT_DIR / 'old_id_to_new_map.json').read_text(encoding='utf-8'))


def dump_old(conn, old_name_to_oid):
    """转储旧版全量关联 + 建立旧→新版映射"""
    cur = conn.cursor()
    cur.execute("""
        SELECT qt.id, qt.question_id, qt.concepttag_id
        FROM questions_question_concept_tags qt
        ORDER BY qt.id
    """)
    old_rows = cur.fetchall()
    print(f"旧版关联: {len(old_rows)} 条")

    qid_map = load_qid_map()
    tag_cross = build_tag_id_cross_ref()
    old_name_rev = {v: k for k, v in old_name_to_oid.items()}  # oid → name

    # 写旧版全量 + 附带名称
    old_with_name = []
    for r in old_rows:
        tag_name = old_name_rev.get(r[2], '?')
        old_with_name.append([r[0], r[1], r[2], tag_name])

    with open(AUDIT_DIR / 'old_q_tags.csv', 'w', newline='',
              encoding='utf-8-sig') as f:
        w = csv.writer(f)
        w.writerow(['id', 'question_id', 'concepttag_id', 'tag_name'])
        w.writerows(old_with_name)
    print(f"old_q_tags.csv: {len(old_with_name)} 行")

    # ── 执行迁移 ──
    QuestionConceptTag.objects.all().delete()
    created = 0
    skipped = 0
    mapping_rows = []

    for r in old_rows:
        old_qid = r[1]
        old_tid = r[2]
        new_qid = qid_map.get(str(old_qid))
        new_tid = tag_cross.get(old_tid)

        if new_qid is None:
            skipped += 1
            continue
        if new_tid is None:
            skipped += 1
            continue

        QuestionConceptTag.objects.get_or_create(
            question_id=new_qid, concept_tag_id=new_tid)
        created += 1
        mapping_rows.append([
            old_qid, new_qid, old_tid, new_tid,
            old_name_rev.get(old_tid, '?'),
        ])

    print(f"创建关联: {created}, 跳过: {skipped}")

    # 写新版全量
    new_rows = []
    for qt in QuestionConceptTag.objects.all().order_by('question_id', 'concept_tag_id'):
        new_rows.append([qt.id, qt.question_id, qt.concept_tag_id])
    with open(AUDIT_DIR / 'new_q_tags.csv', 'w', newline='',
              encoding='utf-8-sig') as f:
        w = csv.writer(f)
        w.writerow(['id', 'question_id', 'concept_tag_id'])
        w.writerows(new_rows)
    print(f"new_q_tags.csv: {len(new_rows)} 行")

    # 写对照表
    mc = ['old_question_id', 'new_question_id', 'old_tag_id', 'new_tag_id', 'tag_name']
    with open(AUDIT_DIR / 'q_tag_mapping.csv', 'w', newline='',
              encoding='utf-8-sig') as f:
        w = csv.writer(f); w.writerow(mc); w.writerows(mapping_rows)
    print(f"q_tag_mapping.csv: {len(mapping_rows)} 行")

    return created, skipped


def write_stats(created, skipped, old_total):
    lines = [
        "=" * 50, "Phase 1.2c 迁移统计", "=" * 50, "",
        f"旧版关联:                {old_total}",
        f"新版 QuestionConceptTag:  {QuestionConceptTag.objects.count()}",
        f"创建:                    {created}",
        f"跳过（无映射）:           {skipped}", "",
        "审核文件:",
        f"  {AUDIT_DIR / 'old_q_tags.csv'}",
        f"  {AUDIT_DIR / 'new_q_tags.csv'}",
        f"  {AUDIT_DIR / 'q_tag_mapping.csv'}",
        f"  {AUDIT_DIR / 'tag_id_cross_ref.json'}",
    ]
    (AUDIT_DIR / 'step_1_2c_stats.txt').write_text('\n'.join(lines), encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    conn = sqlite3.connect(str(OLD_DB))
    old_name_to_oid = load_old_tag_map()

    print("1. 构建标签 ID 交叉引用...")
    build_tag_id_cross_ref()

    print("\n2. 读取旧版关联 + 迁移...")
    created, skipped = dump_old(conn, old_name_to_oid)
    conn.close()

    print("\n3. 统计...")
    write_stats(created, skipped, 2247)
    print("\n完成，审核文件在 server/migration_audit/")
