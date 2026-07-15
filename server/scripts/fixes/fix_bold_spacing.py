"""
修复解题步骤和子题目中粗体标记首尾空格

问题：**逐年计算: **、** (1) 求零点**、** (A) ** 等粗体标记内
含有多余空格，CommonMark 规范要求 ** 两侧不能紧贴空格，
否则不解析为粗体。

修复：在 **...** 内去除首尾空格：
  **text ** → **text**
  ** text** → **text**
  ** text ** → **text**

用法：通过 run_fix.py 执行
"""

import re


def _fix_bold_spacing(text):
    """
    修复单条文本中的粗体标记空格。
    返回 (修复后的文本, 修改次数)
    """
    if not text:
        return text, 0

    changes = 0
    result = text

    # 匹配 **...** 并捕获内部内容（不含前后空格版本）
    def replace_bold(m):
        nonlocal changes
        inner = m.group(1)
        stripped = inner.strip()
        if stripped != inner:
            changes += 1
            return '**' + stripped + '**'
        return m.group(0)

    result = re.sub(r'\*{2}([^*]+)\*{2}', replace_bold, result)
    return result, changes


def fix(conn):
    cursor = conn.cursor()
    total_fixed = 0
    tables_affected = set()

    # ── solution_step.content ──
    cursor.execute("SELECT id, content FROM qbank_solutionstep WHERE content IS NOT NULL")
    steps = cursor.fetchall()
    step_fixed = 0
    for sid, content in steps:
        new_content, c = _fix_bold_spacing(content)
        if c > 0:
            cursor.execute("UPDATE qbank_solutionstep SET content = ? WHERE id = ?", (new_content, sid))
            step_fixed += c
    if step_fixed:
        tables_affected.add('qbank_solutionstep')
    print(f"  ✅ qbank_solutionstep: {step_fixed} 处粗体修复")

    # ── solution_step.title ──
    cursor.execute("SELECT id, title FROM qbank_solutionstep WHERE title IS NOT NULL AND title != ''")
    steps = cursor.fetchall()
    title_fixed = 0
    for sid, title in steps:
        new_title, c = _fix_bold_spacing(title)
        if c > 0:
            cursor.execute("UPDATE qbank_solutionstep SET title = ? WHERE id = ?", (new_title, sid))
            title_fixed += c
    if title_fixed:
        tables_affected.add('qbank_solutionstep')
    print(f"  ✅ qbank_solutionstep.title: {title_fixed} 处粗体修复")

    # ── sub_question stem/answer/explanation ──
    for field in ['stem', 'answer', 'explanation']:
        cursor.execute(f"SELECT id, {field} FROM qbank_subquestion WHERE {field} IS NOT NULL AND {field} != ''")
        rows = cursor.fetchall()
        sub_fixed = 0
        for sqid, val in rows:
            new_val, c = _fix_bold_spacing(val)
            if c > 0:
                cursor.execute(f"UPDATE qbank_subquestion SET {field} = ? WHERE id = ?", (new_val, sqid))
                sub_fixed += c
        if sub_fixed:
            tables_affected.add('qbank_subquestion')
        print(f"  ✅ qbank_subquestion.{field}: {sub_fixed} 处粗体修复")
        total_fixed += sub_fixed

    total_fixed += step_fixed + title_fixed

    return {'fixed': total_fixed, 'tables': sorted(tables_affected)}


def verify(conn):
    cursor = conn.cursor()
    remaining = 0

    # Check solution_step content
    cursor.execute("SELECT id, content FROM qbank_solutionstep WHERE content IS NOT NULL")
    for sid, content in cursor.fetchall():
        for m in re.finditer(r'\*{2}([^*]+)\*{2}', content):
            inner = m.group(1)
            if inner != inner.strip():
                remaining += 1

    # Check sub_question
    for field in ['stem', 'answer', 'explanation']:
        cursor.execute(f"SELECT id, {field} FROM qbank_subquestion WHERE {field} IS NOT NULL")
        for sqid, val in cursor.fetchall():
            for m in re.finditer(r'\*{2}([^*]+)\*{2}', val):
                inner = m.group(1)
                if inner != inner.strip():
                    remaining += 1

    if remaining == 0:
        print("  ✅ 验证通过：无粗体空格残留")
        return True
    else:
        print(f"  ❌ 验证失败：仍有 {remaining} 处粗体空格")
        return False
