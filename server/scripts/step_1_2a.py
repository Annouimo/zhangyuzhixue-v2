"""
Phase 1.2a — 概念标签迁移（三级分类体系）

一级（parent=NULL）    二级（parent=一级）              三级（parent=二级）
─────────────────────────────────────────────────────────────────────
代数 ─┬─ 集合, 逻辑, 不等式, 函数, 三角函数,          ← 各板块下的标签
      │   数列, 复数, 多项式
      └─ (跨板块) 运算, 单调性                         ← 6 个跨板块标签挂一级

几何 ─┬─ 解析几何, 立体几何, 解三角形, 向量, 几何通法
      └─ (跨板块) 直线, 面积, 高, 几何关系

概率统计 ─┬─ 概率

数据清洗：
  - 旧 id=23 常熟列 → 常数列（错别字修正）
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

from qbank.models import ConceptTag, KnowledgeCard

OLD_DB = Path(r'D:\Hermes\math_platform\db.sqlite3')
AUDIT_DIR = Path(__file__).resolve().parent.parent / 'migration_audit'
AUDIT_DIR.mkdir(parents=True, exist_ok=True)

# ── 数据清洗规则 ──
NAME_FIX = {
    23: '常数列',  # 常熟列 → 常数列（错别字）
}


def dump_old(conn):
    cur = conn.cursor()
    cur.execute("SELECT id, name, `order` FROM tags_knowledgeboard ORDER BY id")
    boards = [{'old_id': r[0], 'name': r[1], 'order': r[2]} for r in cur.fetchall()]
    cur.execute("SELECT id, name FROM tags_concepttag ORDER BY id")
    tags = [{'old_id': r[0], 'name': r[1]} for r in cur.fetchall()]
    cur.execute("SELECT concepttag_id, knowledgeboard_id FROM tags_concepttagboard")
    links = [{'tag_id': r[0], 'board_id': r[1]} for r in cur.fetchall()]
    old = {'knowledgeboard': boards, 'concepttag': tags, 'concepttag_board_links': links}
    (AUDIT_DIR / 'old_concept_tags.json').write_text(
        json.dumps(old, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f"old_concept_tags.json: 板块{len(boards)}个, 标签{len(tags)}条, 关联{len(links)}条")

    cur.execute("""
        SELECT id, name, category, content, is_label_only,
               is_published, created_at, updated_at
        FROM knowledge_knowledgecard WHERE is_published = 1 ORDER BY id
    """)
    cards = [{'old_id': r[0], 'name': r[1], 'category': r[2], 'content': r[3],
              'is_label_only': bool(r[4]), 'is_published': bool(r[5]),
              'created_at': r[6], 'updated_at': r[7]} for r in cur.fetchall()]
    (AUDIT_DIR / 'old_knowledge_cards.json').write_text(
        json.dumps(cards, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f"old_knowledge_cards.json: 已发布卡片{len(cards)}条")
    return boards, tags, links, cards


def run_migrate(boards, tags, links, cards):
    ConceptTag.objects.all().delete()
    KnowledgeCard.objects.all().delete()
    id_map = {}

    # ── 一级分类 ──
    cat_tags = {}
    for name in ['代数', '几何', '概率统计']:
        cat_tags[name] = ConceptTag.objects.create(name=name, parent=None)
        id_map[('cat', name)] = cat_tags[name]
    print(f"一级: {', '.join(cat_tags.keys())}")

    # ── 二级：板块归属 ──
    board_to_cat = {
        1: '代数', 2: '代数', 3: '代数', 4: '代数', 5: '代数',
        6: '代数', 7: '代数', 10: '代数',
        11: '几何', 12: '几何', 13: '几何', 14: '几何', 8: '几何',
        9: '概率统计',
    }
    board_rename = {8: '几何通法'}

    for b in boards:
        pc = board_to_cat.get(b['old_id'])
        if pc is None:
            continue
        name = board_rename.get(b['old_id'], b['name'])
        tag = ConceptTag.objects.create(name=name, parent=cat_tags[pc])
        id_map[('board', b['old_id'])] = tag

    # ── 三级：标签 ──
    cross_ids = {1, 3, 12, 15, 25, 28}  # 跨板块标签
    tag_boards = {}
    for link in links:
        tag_boards.setdefault(link['tag_id'], []).append(link['board_id'])

    for t in tags:
        oid = t['old_id']
        name = NAME_FIX.get(oid, t['name'])  # 应用数据清洗
        blist = tag_boards.get(oid, [])
        fixed_tag = '  (清洗: {0} → {1})'.format(t['name'], name) if oid in NAME_FIX else ''

        if oid in cross_ids:
            fb = blist[0] if blist else 4
            p = cat_tags.get(board_to_cat.get(fb, '代数'), cat_tags['代数'])
            tag = ConceptTag.objects.create(name=name, parent=p)
            id_map[('tag', oid)] = tag
            print(f"  跨板块 '{name}' → {p.name}{fixed_tag}")
        elif len(blist) == 1:
            pt = id_map.get(('board', blist[0]))
            if pt is None:
                tag = ConceptTag.objects.create(name=name, parent=cat_tags['代数'])
                id_map[('tag', oid)] = tag
            elif name == pt.name:
                id_map[('tag', oid)] = pt
                print(f"  同名复用 '{name}' = 板块节点{fixed_tag}")
            else:
                tag = ConceptTag.objects.create(name=name, parent=pt)
                id_map[('tag', oid)] = tag

    # ── 知识卡片 ──
    for c in cards:
        KnowledgeCard.objects.create(title=c['name'], content=c['content'] or '')
    return id_map


def dump_new(id_map):
    new_tags = []
    mapping = []
    for tag in ConceptTag.objects.all().order_by('id'):
        lineage = []
        p = tag
        while p:
            lineage.insert(0, p.name)
            p = p.parent
        path = ' / '.join(lineage)
        new_tags.append({'id': tag.id, 'name': tag.name,
                         'parent_id': tag.parent_id, 'path': path})
        oid = ''
        for k, v in id_map.items():
            if v.id == tag.id:
                oid = str(k[1])
                break
        mapping.append({'old_id': oid, 'new_id': tag.id, 'name': tag.name, 'path': path})

    (AUDIT_DIR / 'new_concept_tags.json').write_text(
        json.dumps(new_tags, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f"new_concept_tags.json: {len(new_tags)}条")

    with open(AUDIT_DIR / 'concept_tag_mapping.csv', 'w', newline='',
              encoding='utf-8-sig') as f:
        w = csv.DictWriter(f, fieldnames=['old_id', 'new_id', 'name', 'path'])
        w.writeheader()
        w.writerows(mapping)
    print(f"concept_tag_mapping.csv: {len(mapping)}行")

    new_cards = []
    for card in KnowledgeCard.objects.all().order_by('id'):
        new_cards.append({'id': card.id, 'title': card.title,
                          'content_preview': (card.content[:120] if card.content else '')})
    (AUDIT_DIR / 'new_knowledge_cards.json').write_text(
        json.dumps(new_cards, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f"new_knowledge_cards.json: {len(new_cards)}条")


def write_stats(boards, tags, links, cards):
    l1 = ConceptTag.objects.filter(parent__isnull=True).count()
    total = ConceptTag.objects.count()
    n_card = KnowledgeCard.objects.count()
    lines = [
        "=" * 50, "Phase 1.2a 迁移统计", "=" * 50, "",
        f"一级（三大分类）: {l1}",
        f"ConceptTag 总数:  {total}",
        f"清洗记录: 常熟列→常数列",
        f"新版 KnowledgeCard: {n_card}", "",
        "审核文件:", f"  {AUDIT_DIR / 'new_concept_tags.json'}",
        f"  {AUDIT_DIR / 'concept_tag_mapping.csv'}",
        f"  {AUDIT_DIR / 'old_concept_tags.json'}",
    ]
    (AUDIT_DIR / 'step_1_2a_stats.txt').write_text('\n'.join(lines), encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    conn = sqlite3.connect(str(OLD_DB))
    print("1. 转储旧版...")
    b, t, l, c = dump_old(conn)
    print("\n2. 执行迁移...")
    m = run_migrate(b, t, l, c)
    print("\n3. 转储新版...")
    dump_new(m)
    print("\n4. 统计...")
    write_stats(b, t, l, c)
    conn.close()
    print("\n完成，审核文件在 server/migration_audit/")
