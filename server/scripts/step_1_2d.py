"""
Phase 1.2d — 解题步骤迁移（SubQuestion → SolutionMethod → SolutionStep）

旧版 questions_questionstep（3061 行）→ 新版三层结构。
旧版 answer_text（从 answer_text_map.json）→ SubQuestion.answer。
title 从"步骤 N"生成（旧版无 step_title）。
card_refs JSON → card_titles（提取 name 字段）。

产出 (server/migration_audit/):
  old_steps.csv                — 旧版 3061 条 step（含题号+标签）
  new_sub_questions.csv        — 新版全部 SubQuestion
  new_solution_methods.csv     — 新版全部 SolutionMethod
  new_solution_steps.csv       — 新版全部 SolutionStep（含 title + card_titles）
  step_comparison_sample.json  — 按题号组织的前 20 题新旧对照
  step_1_2d_stats.txt          — 统计摘要
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

from qbank.models import BaseQuestion, SubQuestion, SolutionMethod, SolutionStep

OLD_DB = Path(r'D:\Hermes\math_platform\db.sqlite3')
AUDIT_DIR = Path(__file__).resolve().parent.parent / 'migration_audit'

# 选填题型（只有 subquestion=0）
SIMPLE_TYPES = {'choice', 'fill'}


def load_maps():
    qid_map = json.loads((AUDIT_DIR / 'old_id_to_new_map.json').read_text(encoding='utf-8'))
    qid_map_int = {int(k): v for k, v in qid_map.items()}
    answer_map = json.loads((AUDIT_DIR / 'answer_text_map.json').read_text(encoding='utf-8'))
    answer_map_int = {int(k): v for k, v in answer_map.items()}
    return qid_map_int, answer_map_int


def parse_card_refs(card_refs_str):
    """解析 card_refs JSON → card_titles list"""
    if not card_refs_str or card_refs_str.strip() == '':
        return []
    try:
        refs = json.loads(card_refs_str)
        if isinstance(refs, list):
            return [r.get('name', '') for r in refs if r.get('name')]
    except (json.JSONDecodeError, TypeError):
        pass
    return []


def dump_old(conn):
    cur = conn.cursor()
    cur.execute("""
        SELECT qs.id, qs.question_id, qs.subquestion, qs.method,
               qs.step, qs.content, qs.card_refs,
               qq.exam, qq.district, qq.question_number
        FROM questions_questionstep qs
        JOIN questions_question qq ON qq.id = qs.question_id
        WHERE qq.year != 2099
        ORDER BY qs.question_id, qs.subquestion, qs.method, qs.step
    """)
    rows = cur.fetchall()
    print(f"旧版 step: {len(rows)} 行")

    old_out = []
    for r in rows:
        card_refs = parse_card_refs(r[6])
        old_out.append([
            r[0], r[1], r[2], r[3], r[4],
            r[5][:80] if r[5] else '',
            json.dumps(card_refs, ensure_ascii=False),
            r[7], r[8], r[9],
        ])
    with open(AUDIT_DIR / 'old_steps.csv', 'w', newline='',
              encoding='utf-8-sig') as f:
        w = csv.writer(f)
        w.writerow(['id', 'question_id', 'subquestion', 'method', 'step',
                     'content_preview', 'card_titles',
                     'exam', 'district', 'question_number'])
        w.writerows(old_out)
    print(f"old_steps.csv: {len(old_out)} 行")
    return rows


def run_migrate(rows, qid_map, answer_map):
    SubQuestion.objects.all().delete()
    SolutionMethod.objects.all().delete()
    SolutionStep.objects.all().delete()

    stats = {'sq': 0, 'method': 0, 'step': 0, 'answered': 0}

    # 按 (new_question_id, subquestion) 分组创建 SubQuestion
    # 按 (new_question_id, subquestion, method) 分组创建 SolutionMethod
    seen_sq = set()
    seen_method = set()

    for r in rows:
        old_qid = r[1]
        new_qid = qid_map.get(old_qid)
        if new_qid is None:
            continue
        subq = r[2]
        method = r[3]
        step_num = r[4]
        content = r[5] or ''
        card_refs = parse_card_refs(r[6])

        # 判断题型
        try:
            qtype = BaseQuestion.objects.get(id=new_qid).question_type
        except BaseQuestion.DoesNotExist:
            continue

        # SubQuestion
        sq_key = (new_qid, subq)
        if sq_key not in seen_sq:
            seen_sq.add(sq_key)
            # answer: 选填题用旧版 answer_text，解答题填空
            answer = ''
            if qtype in SIMPLE_TYPES:
                answer = answer_map.get(old_qid, '')
            SubQuestion.objects.create(
                question_id=new_qid,
                parent=None,
                stem=None,
                answer=answer,
                sort_order=subq,
            )
            stats['sq'] += 1
            if answer:
                stats['answered'] += 1

        # SolutionMethod
        method_key = (new_qid, subq, method)
        if method_key not in seen_method:
            seen_method.add(method_key)
            # 找到对应的 sub_question
            sq = SubQuestion.objects.filter(
                question_id=new_qid, sort_order=subq).first()
            if sq:
                SolutionMethod.objects.create(
                    sub_question=sq,
                    method_name=None,  # 旧版无名称
                    source='',
                    sort_order=method,
                )
                stats['method'] += 1

        # SolutionStep
        sq = SubQuestion.objects.filter(
            question_id=new_qid, sort_order=subq).first()
        sm = SolutionMethod.objects.filter(
            sub_question=sq, sort_order=method).first()
        if sq and sm:
            SolutionStep.objects.create(
                method=sm,
                step_number=step_num,
                title=f'步骤 {step_num}',
                content=content,
                card_titles=card_refs,
            )
            stats['step'] += 1

    print(f"SubQuestion: {stats['sq']}, "
          f"SolutionMethod: {stats['method']}, "
          f"SolutionStep: {stats['step']}, "
          f"写 answer: {stats['answered']}")
    return stats


def dump_new(rows, qid_map, stats):
    # SubQuestion
    sq_rows = []
    for sq in SubQuestion.objects.all().order_by('question_id', 'sort_order'):
        sq_rows.append([sq.id, sq.question_id, sq.parent_id,
                        sq.answer[:60] if sq.answer else '',
                        sq.sort_order])
    with open(AUDIT_DIR / 'new_sub_questions.csv', 'w', newline='',
              encoding='utf-8-sig') as f:
        csv.writer(f).writerow(
            ['id', 'question_id', 'parent_id', 'answer', 'sort_order'])
        csv.writer(f).writerows(sq_rows)
    print(f"new_sub_questions.csv: {len(sq_rows)} 行")

    # SolutionMethod
    sm_rows = []
    for sm in SolutionMethod.objects.all().order_by(
            'sub_question__question_id', 'sub_question__sort_order', 'sort_order'):
        sm_rows.append([sm.id, sm.sub_question_id,
                        sm.method_name or '', sm.source, sm.sort_order])
    with open(AUDIT_DIR / 'new_solution_methods.csv', 'w', newline='',
              encoding='utf-8-sig') as f:
        csv.writer(f).writerow(
            ['id', 'sub_question_id', 'method_name', 'source', 'sort_order'])
        csv.writer(f).writerows(sm_rows)
    print(f"new_solution_methods.csv: {len(sm_rows)} 行")

    # SolutionStep
    ss_rows = []
    for ss in SolutionStep.objects.all().order_by(
            'method__sub_question__question_id',
            'method__sub_question__sort_order',
            'method__sort_order', 'step_number'):
        ss_rows.append([ss.id, ss.method_id, ss.step_number, ss.title,
                        ss.content[:80], json.dumps(ss.card_titles, ensure_ascii=False)])
    with open(AUDIT_DIR / 'new_solution_steps.csv', 'w', newline='',
              encoding='utf-8-sig') as f:
        csv.writer(f).writerow(
            ['id', 'method_id', 'step_number', 'title',
             'content_preview', 'card_titles'])
        csv.writer(f).writerows(ss_rows)
    print(f"new_solution_steps.csv: {len(ss_rows)} 行")

    # 新旧对照样本（前 20 题）
    comparison = []
    qid_map_rev = {v: k for k, v in qid_map.items()}
    sample_qids = list(qid_map_rev.keys())[:20]
    for new_qid in sample_qids:
        old_qid = qid_map_rev[new_qid]
        q = BaseQuestion.objects.get(id=new_qid)
        # 旧版 step
        old_steps = []
        for r in rows:
            if r[1] == old_qid:
                old_steps.append({
                    'subq': r[2], 'method': r[3], 'step': r[4],
                    'content_preview': (r[5] or '')[:80],
                    'card_refs': parse_card_refs(r[6]),
                })
        # 新版 step
        new_steps = []
        for ss in SolutionStep.objects.filter(
                method__sub_question__question_id=new_qid).order_by(
                'method__sub_question__sort_order',
                'method__sort_order', 'step_number'):
            new_steps.append({
                'subq': ss.method.sub_question.sort_order,
                'method': ss.method.sort_order,
                'step': ss.step_number,
                'title': ss.title,
                'content_preview': ss.content[:80],
                'card_titles': ss.card_titles,
            })
        comparison.append({
            'new_question_id': new_qid,
            'old_question_id': old_qid,
            'exam': f'{q.year} {q.exam_type} {q.region} 第{q.number}题',
            'old_step_count': len(old_steps),
            'new_step_count': len(new_steps),
            'match': len(old_steps) == len(new_steps),
        })
    (AUDIT_DIR / 'step_comparison_sample.json').write_text(
        json.dumps(comparison, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f"step_comparison_sample.json: {len(comparison)} 题")


def write_stats(rows, stats):
    total_ss = SolutionStep.objects.count()
    lines = [
        "=" * 50, "Phase 1.2d 迁移统计", "=" * 50, "",
        f"旧版 questionstep:           {len(rows)}",
        f"新版 SubQuestion:            {stats['sq']}",
        f"新版 SolutionMethod:         {stats['method']}",
        f"新版 SolutionStep:           {total_ss}",
        f"（其中写 answer 的选填题）:    {stats['answered']}", "",
        "审核文件:",
        f"  {AUDIT_DIR / 'old_steps.csv'}",
        f"  {AUDIT_DIR / 'new_sub_questions.csv'}",
        f"  {AUDIT_DIR / 'new_solution_methods.csv'}",
        f"  {AUDIT_DIR / 'new_solution_steps.csv'}",
        f"  {AUDIT_DIR / 'step_comparison_sample.json'}",
    ]
    (AUDIT_DIR / 'step_1_2d_stats.txt').write_text('\n'.join(lines), encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    conn = sqlite3.connect(str(OLD_DB))
    qid_map, answer_map = load_maps()

    print("1. 转储旧版步骤...")
    rows = dump_old(conn)
    conn.close()

    print("\n2. 执行迁移...")
    stats = run_migrate(rows, qid_map, answer_map)

    print("\n3. 转储新版...")
    dump_new(rows, qid_map, stats)

    print("\n4. 统计...")
    write_stats(rows, stats)
    print("\n完成，审核文件在 server/migration_audit/")
