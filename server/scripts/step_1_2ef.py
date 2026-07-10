"""
Phase 1.2e + 1.2f — 选项提取 + 配图关联 + 卡片关联

1.2e: 选择题选项从 stem 提取为 ChoiceExt；配图按路径匹配写入 images
1.2f: 从 SolutionStep.card_titles 反向建立 QuestionKnowledgeCard

产出 (server/migration_audit/):
  1.2e:
    choice_ext_audit.csv     — 全部选择题：题号+原始选项片段+提取的options+清理后stem
    image_mapping.csv        — 有配图的题：磁盘文件 → question_id
    questions_with_images.csv — 有配图的题清单
  1.2f:
    card_ref_analysis.csv    — card_refs 中引用的卡片名称+出现次数
    new_q_card_links.csv     — 新版 QuestionKnowledgeCard 全部记录
    unmatched_card_refs.csv  — 旧版有但新版找不到的卡片名称
  step_1_2ef_stats.txt       — 统计摘要
"""
import csv
import json
import os
import re
import sqlite3
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'math_platform.settings')
import django
django.setup()

from qbank.models import (
    BaseQuestion, ChoiceExt, KnowledgeCard, QuestionKnowledgeCard, SolutionStep,
)

OLD_DB = Path(r'D:\Hermes\math_platform\db.sqlite3')
AUDIT_DIR = Path(__file__).resolve().parent.parent / 'migration_audit'
IMG_SRC = Path(r'D:\Hermes\math_platform\static\questions\附图')
IMG_DST = Path(__file__).resolve().parent.parent / 'static' / 'questions' / 'images'

qid_map = json.loads((AUDIT_DIR / 'old_id_to_new_map.json').read_text(encoding='utf-8'))
# 反查: new_qid → old_qid
rev_qid = {v: int(k) for k, v in qid_map.items()}


# ═══════════════════════════════════════════════════════════════
# 1.2e: 选择题选项提取
# ═══════════════════════════════════════════════════════════════

def parse_choice_options(stem):
    """
    从选择题 stem 末尾提取 (A)...(B)...(C)...(D)... 选项。
    返回 (cleaned_stem, options_dict_or_None)
    """
    if not stem:
        return stem, None
    # 匹配 (A)...(B)...(C)...(D)... 模式（题号可能带全角括号）
    # 选项文本可能含 LaTeX $...$、中文、数字
    pattern = re.compile(
        r'[（(]\s*[A-Da-d]\s*[）)]\s*.*?(?=[（(]\s*[A-Da-d]\s*[）)]|\Z)',
        re.DOTALL
    )
    matches = pattern.findall(stem)
    if len(matches) < 2:
        return stem, None  # 没找到至少两个选项

    options = {}
    for m in matches:
        # 提取选项字母
        letter_match = re.match(r'[（(]\s*([A-Da-d])\s*[）)]', m)
        if not letter_match:
            continue
        letter = letter_match.group(1).upper()
        # 选项内容 = 去掉 (X) 前缀后的部分
        content = re.sub(r'^[（(]\s*[A-Da-d]\s*[）)]\s*', '', m).strip()
        options[letter] = content

    if len(options) < 2:
        return stem, None

    # 清理 stem：去掉选项部分
    # 找到第一个选项的位置
    first_opt = re.search(r'[（(]\s*[A-Da-d]\s*[）)]', stem)
    if first_opt:
        cleaned = stem[:first_opt.start()].strip()
    else:
        cleaned = stem

    return cleaned, options


def migrate_choice_ext(conn):
    """提取选择题选项到 ChoiceExt"""
    print("\n" + "=" * 60)
    print("1.2e — 选择题选项提取")
    print("=" * 60)

    ChoiceExt.objects.all().delete()
    choice_questions = BaseQuestion.objects.filter(question_type='choice')
    print(f"选择题: {choice_questions.count()} 题")

    audit_rows = []  # 审核用
    created = 0
    skipped = 0

    for q in choice_questions:
        cleaned, options = parse_choice_options(q.stem)
        if not options:
            skipped += 1
            audit_rows.append([q.id, q.stem[:120], '解析失败', q.stem[:120]])
            continue

        ChoiceExt.objects.create(
            question=q,
            options=options,
        )
        created += 1
        audit_rows.append([
            q.id, q.stem[:120],
            json.dumps(options, ensure_ascii=False),
            (cleaned or q.stem)[:120],
        ])

        # 更新 stem（去掉选项）
        if cleaned and cleaned != q.stem:
            q.stem = cleaned
            q.save(update_fields=['stem'])

    print(f"ChoiceExt 创建: {created}, 跳过（解析失败）: {skipped}")

    with open(AUDIT_DIR / 'choice_ext_audit.csv', 'w', newline='',
              encoding='utf-8-sig') as f:
        w = csv.writer(f)
        w.writerow(['question_id', 'stem_preview', 'extracted_options', 'cleaned_stem'])
        w.writerows(audit_rows)
    print(f"choice_ext_audit.csv: {len(audit_rows)} 行")

    return created, skipped


# ═══════════════════════════════════════════════════════════════
# 1.2e: 配图关联
# ═══════════════════════════════════════════════════════════════

def migrate_images(conn):
    """按路径匹配配图并写入 images 字段，同时复制到静态目录"""
    print("\n" + "=" * 60)
    print("1.2e — 配图关联")
    print("=" * 60)

    if not IMG_SRC.exists():
        print(f"⚠️  配图目录不存在: {IMG_SRC}")
        return 0

    # 扫描所有图片文件
    image_files = []
    for root, dirs, files in os.walk(str(IMG_SRC)):
        for f in files:
            if f.lower().endswith(('.png', '.webp', '.jpg', '.jpeg')):
                rel = Path(root).relative_to(IMG_SRC)
                image_files.append((rel, f))

    print(f"磁盘图片文件: {len(image_files)} 个")

    # 解析文件名 → (exam_type, year, district, q_number)
    def parse_img_path(rel_path, filename):
        parts = rel_path.parts
        if len(parts) >= 3:
            exam_type = parts[0]
            year = parts[1]
            district = parts[2]
        elif len(parts) == 2:
            exam_type = parts[0]
            year = parts[1]
            district = ''
        else:
            return None
        # 文件名: q{NUMBER}.ext 或 q{NUMBER}_X.ext
        m = re.match(r'q(\d+)', filename)
        if not m:
            return None
        qnum = int(m.group(1))
        return (exam_type, year, district, qnum)

    # 建立 (exam_type, year, district, q_number) → file path 索引
    # 优先用 webp
    img_index = {}
    for rel, fname in image_files:
        key = parse_img_path(rel, fname)
        if key is None:
            continue
        ext = fname.lower().split('.')[-1]
        # 优先 webp
        if key not in img_index or ext == 'webp':
            img_index[key] = str(rel / fname)

    print(f"可匹配的图片索引: {len(img_index)} 条")

    # 从旧版数据库查 (exam, district, question_number) → old_qid
    cur = conn.cursor()
    cur.execute("""
        SELECT id, exam, district, question_number
        FROM questions_question
        WHERE year != 2099
    """)
    old_questions = cur.fetchall()

    matched = 0
    img_dst = IMG_DST
    img_dst.mkdir(parents=True, exist_ok=True)

    mapping_rows = []
    for old_id, exam, district, qnum in old_questions:
        new_id = qid_map.get(str(old_id))
        if new_id is None:
            continue
        # 先试 exam, year=202x, district
        for year_guess in [2020, 2021, 2022, 2023, 2024, 2025, 2026]:
            key = (exam, str(year_guess), district, qnum)
            if key in img_index:
                # 写 images 字段
                rel_path = img_index[key]
                img_fn = Path(rel_path).name
                q = BaseQuestion.objects.get(id=new_id)
                q.images = [str(rel_path)]
                q.save(update_fields=['images'])

                # 复制文件
                src = IMG_SRC / rel_path
                if src.exists():
                    dst = img_dst / img_fn
                    if not dst.exists():
                        import shutil
                        shutil.copy2(str(src), str(dst))

                mapping_rows.append([old_id, new_id, exam, year_guess, district, qnum, rel_path])
                matched += 1
                break

    print(f"匹配到配图的题: {matched} 题")

    with open(AUDIT_DIR / 'image_mapping.csv', 'w', newline='',
              encoding='utf-8-sig') as f:
        w = csv.writer(f)
        w.writerow(['old_qid', 'new_qid', 'exam', 'year', 'district', 'q_number', 'img_path'])
        w.writerows(mapping_rows)
    print(f"image_mapping.csv: {len(mapping_rows)} 行")

    # 有配图的题清单
    with_img = BaseQuestion.objects.exclude(images=[]).count()
    print(f"有配图的题（images非空）: {with_img}")

    return matched


# ═══════════════════════════════════════════════════════════════
# 1.2f: 题目-知识卡片关联
# ═══════════════════════════════════════════════════════════════

def migrate_card_links():
    """从 SolutionStep.card_titles 建立 QuestionKnowledgeCard"""
    print("\n" + "=" * 60)
    print("1.2f — 题目-知识卡片关联")
    print("=" * 60)

    QuestionKnowledgeCard.objects.all().delete()

    # 收集所有 card_titles 引用
    title_counter = Counter()
    q_card_links = {}  # (question_id, card_title) → count

    for ss in SolutionStep.objects.exclude(card_titles=[]):
        qid = ss.method.sub_question.question_id
        for title in ss.card_titles:
            if not title:
                continue
            title_counter[title] += 1
            key = (qid, title)
            q_card_links[key] = q_card_links.get(key, 0) + 1

    print(f"card_refs 中引用的卡片名称: {len(title_counter)} 种")

    # 名称出现次数统计
    with open(AUDIT_DIR / 'card_ref_analysis.csv', 'w', newline='',
              encoding='utf-8-sig') as f:
        w = csv.writer(f)
        w.writerow(['card_title', 'occurrence_count'])
        for title, cnt in title_counter.most_common():
            w.writerow([title, cnt])
    print(f"card_ref_analysis.csv: {len(title_counter)} 行")

    # 建立关联
    created = 0
    unmatched = []

    for (qid, title), _ in q_card_links.items():
        cards = KnowledgeCard.objects.filter(title=title)
        if cards.exists():
            card = cards.first()
            QuestionKnowledgeCard.objects.get_or_create(
                question_id=qid,
                knowledge_card=card,
            )
            created += 1
        else:
            unmatched.append(title)

    unmatched_unique = list(set(unmatched))
    print(f"QuestionKnowledgeCard 创建: {created}")
    print(f"无法匹配的卡片名称: {len(unmatched_unique)} 种")

    # 写新版全量
    links_rows = []
    for link in QuestionKnowledgeCard.objects.all().order_by('question_id', 'knowledge_card_id'):
        links_rows.append([link.id, link.question_id, link.knowledge_card_id,
                           link.knowledge_card.title])
    with open(AUDIT_DIR / 'new_q_card_links.csv', 'w', newline='',
              encoding='utf-8-sig') as f:
        w = csv.writer(f)
        w.writerow(['id', 'question_id', 'knowledge_card_id', 'card_title'])
        w.writerows(links_rows)
    print(f"new_q_card_links.csv: {len(links_rows)} 行")

    # 无法匹配的
    with open(AUDIT_DIR / 'unmatched_card_refs.csv', 'w', newline='',
              encoding='utf-8-sig') as f:
        w = csv.writer(f)
        w.writerow(['card_title'])
        for title in sorted(unmatched_unique):
            w.writerow([title])
    print(f"unmatched_card_refs.csv: {len(unmatched_unique)} 行")

    return created, len(unmatched_unique)


# ═══════════════════════════════════════════════════════════════

def write_stats(e_created, e_skipped, img_matched, f_created, f_unmatched):
    lines = [
        "=" * 50,
        "Phase 1.2e + 1.2f 迁移统计",
        "=" * 50, "",
        "── 1.2e 选择题选项 ──",
        f"ChoiceExt 创建:          {e_created}",
        f"解析跳过:                {e_skipped}", "",
        "── 1.2e 配图 ──",
        f"匹配到配图的题:          {img_matched}",
        f"images 非空的题:         {BaseQuestion.objects.exclude(images=[]).count()}", "",
        "── 1.2f 卡片关联 ──",
        f"QuestionKnowledgeCard:   {QuestionKnowledgeCard.objects.count()}",
        f"无法匹配的卡片名称:       {f_unmatched}", "",
        "审核文件:",
        f"  {AUDIT_DIR / 'choice_ext_audit.csv'}",
        f"  {AUDIT_DIR / 'image_mapping.csv'}",
        f"  {AUDIT_DIR / 'card_ref_analysis.csv'}",
        f"  {AUDIT_DIR / 'new_q_card_links.csv'}",
        f"  {AUDIT_DIR / 'unmatched_card_refs.csv'}",
    ]
    (AUDIT_DIR / 'step_1_2ef_stats.txt').write_text('\n'.join(lines), encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    conn = sqlite3.connect(str(OLD_DB))

    e_created, e_skipped = migrate_choice_ext(conn)
    img_matched = migrate_images(conn)

    conn.close()

    f_created, f_unmatched = migrate_card_links()

    print("\n" + "=" * 60)
    print("统计")
    print("=" * 60)
    write_stats(e_created, e_skipped, img_matched, f_created, f_unmatched)
    print("\n完成，审核文件在 server/migration_audit/")
