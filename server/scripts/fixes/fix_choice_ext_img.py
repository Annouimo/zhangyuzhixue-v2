"""
修复 choice_ext 选项 JSON 中残留的 <img> 标签

问题：原始数据迁移时，选项文本末尾嵌入了
  \\n\\n<imgsrc='/static/questions/...png' alt='图'>
这些 HTML 标签应在数据清洗时去除。

用法：通过 run_fix.py 执行
"""

import json
import re


def fix(conn):
    cursor = conn.cursor()
    cursor.execute("SELECT id, options FROM qbank_choiceext WHERE options LIKE '%<img%'")
    rows = cursor.fetchall()
    print(f"  找到 {len(rows)} 行含 <img>")

    img_pattern = re.compile(r'<img[^>]*>', re.IGNORECASE)
    fixed = 0

    for cid, options_json in rows:
        try:
            parsed = json.loads(options_json)
        except (json.JSONDecodeError, TypeError):
            continue

        original_json = options_json
        changed = False

        for key in parsed:
            val = parsed[key]
            if isinstance(val, str) and img_pattern.search(val):
                new_val = img_pattern.sub('', val).rstrip()
                if new_val != val:
                    parsed[key] = new_val
                    changed = True

        if changed:
            new_json = json.dumps(parsed, ensure_ascii=False)
            cursor.execute("UPDATE qbank_choiceext SET options = ? WHERE id = ?", (new_json, cid))
            fixed += 1

    print(f"  ✅ choice_ext: {fixed} 行已修复")
    return {'fixed': fixed, 'tables': ['qbank_choiceext']}


def verify(conn):
    cursor = conn.cursor()
    cursor.execute("SELECT id, options FROM qbank_choiceext")
    remaining = 0
    for cid, opts in cursor.fetchall():
        if re.search(r'<img[^>]*>', opts, re.IGNORECASE):
            remaining += 1
    if remaining == 0:
        print("  ✅ 验证通过：无 <img> 残留")
        return True
    else:
        print(f"  ❌ 验证失败：仍有 {remaining} 行含 <img>")
        return False
