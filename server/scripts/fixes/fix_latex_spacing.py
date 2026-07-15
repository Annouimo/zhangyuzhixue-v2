"""
修复 LaTeX 间距命令双转义问题

问题：\\, \\! \\; \\: 被存储为 \\\\, \\\\! \\\\; \\\\:
（LaTeX 中的 \, 在数据导入时被多转义了一次）

影响：\\ 在行内公式 $...$ 中被 TeX 解析器解释为换行命令，
生成 CrNode（TemporaryNode 子类），导致 texBreak() 崩溃。

修复：在行内公式 $...$ 中且不在 \begin{xxx}...\end{xxx} 环境内，
将 \\\\, → \\, 等。

用法：
    python scripts/fixes/fix_latex_spacing.py --local   # 本地测试
    或通过 run_fix.py 执行
"""

import re


def fix(conn):
    """
    修复 solution_step.content 和 sub_question.answer 中的间距命令双转义。
    
    Returns: {'fixed': int, 'tables': [str]}
    """
    bs = chr(92)  # \
    
    fixed_total = 0
    tables_affected = set()
    
    # 需要修复的间距模式
    spacing_patterns = {
        bs * 2 + ',': bs + ',',   # \\, → \,
        bs * 2 + '!': bs + '!',   # \\! → \!
        bs * 2 + ';': bs + ';',   # \\; → \;
        bs * 2 + ':': bs + ':',   # \\: → \:
    }
    
    def fix_content(text):
        """修复单条 content，返回修复后的文本和改动次数"""
        if not text:
            return text, 0
        
        changes = 0
        bs_escaped = bs * 2  # \\ (double backslash)
        
        def fix_inline(m):
            """Fix spacing commands inside an inline $...$ chunk."""
            nonlocal changes
            chunk = m.group(1)
            original = chunk
            pos = 0
            while pos < len(chunk):
                idx = chunk.find(bs_escaped, pos)
                if idx < 0:
                    break
                after = chunk[idx+2:idx+3] if idx+2 < len(chunk) else ''
                
                if after in ',!;:':
                    before_env = chunk[:idx]
                    env_opens = re.findall(r'\\begin\{([^}]+)\}', before_env)
                    in_env = any(
                        f'\\end{{{env}}}' in chunk[idx+2:] for env in env_opens
                    )
                    if not in_env:
                        key = bs_escaped + after
                        rep = spacing_patterns.get(key)
                        if rep:
                            chunk = chunk[:idx] + rep + chunk[idx+2:]
                            changes += 1
                            pos = idx + len(rep)
                            continue
                pos = idx + 2
            return '$' + chunk + '$' if changes > 0 else m.group(0)
        
        # Match $...$ but not $$...$$
        result = re.sub(r'(?<!\$)\$([^$\n]+?)\$(?!\$)', fix_inline, text)
        return result, changes
    
    # ── 修复 solution_step ──
    cursor = conn.cursor()
    cursor.execute("SELECT id, content FROM qbank_solutionstep WHERE content IS NOT NULL")
    steps = cursor.fetchall()
    
    update_sql = "UPDATE qbank_solutionstep SET content = ? WHERE id = ?"
    step_fixed = 0
    for sid, content in steps:
        new_content, changes = fix_content(content)
        if changes > 0:
            cursor.execute(update_sql, (new_content, sid))
            step_fixed += changes
    
    if step_fixed:
        tables_affected.add('qbank_solutionstep')
    print(f"  ✅ qbank_solutionstep: {step_fixed} 处修复")
    
    # ── 修复 sub_question.answer ──
    cursor.execute("SELECT id, answer FROM qbank_subquestion WHERE answer IS NOT NULL")
    subs = cursor.fetchall()
    
    update_sql = "UPDATE qbank_subquestion SET answer = ? WHERE id = ?"
    sub_fixed = 0
    for sid, answer in subs:
        new_answer, changes = fix_content(answer)
        if changes > 0:
            cursor.execute(update_sql, (new_answer, sid))
            sub_fixed += changes
    
    if sub_fixed:
        tables_affected.add('qbank_subquestion')
    print(f"  ✅ qbank_subquestion: {sub_fixed} 处修复")
    
    fixed_total = step_fixed + sub_fixed
    
    return {
        'fixed': fixed_total,
        'tables': sorted(tables_affected),
    }


def verify(conn):
    """
    验证修复：检查是否还有未修复的间距命令双转义。
    """
    bs = chr(92)
    # Check solution_step
    cursor = conn.cursor()
    cursor.execute("SELECT id, content FROM qbank_solutionstep WHERE content IS NOT NULL")
    remaining = 0
    for sid, content in cursor.fetchall():
        if not content:
            continue
        for after_char in ',!;:':
            pattern = bs * 2 + after_char
            idx = content.find(pattern)
            while idx >= 0:
                # Check if in inline math and not in environment
                before = content[:idx]
                if before.count('$') % 2 == 1:
                    env_opens = re.findall(r'\\begin\{([^}]+)\}', before)
                    in_env = False
                    if env_opens:
                        env = env_opens[-1]
                        if f'\\end{{{env}}}' in content[idx:]:
                            in_env = True
                    if not in_env:
                        remaining += 1
                        break
                idx = content.find(pattern, idx + 2)
    
    cursor.execute("SELECT id, answer FROM qbank_subquestion WHERE answer IS NOT NULL")
    for sid, answer in cursor.fetchall():
        if not answer:
            continue
        for after_char in ',!;:':
            pattern = bs * 2 + after_char
            idx = answer.find(pattern)
            while idx >= 0:
                before = answer[:idx]
                if before.count('$') % 2 == 1:
                    env_opens = re.findall(r'\\begin\{([^}]+)\}', before)
                    in_env = False
                    if env_opens:
                        env = env_opens[-1]
                        if f'\\end{{{env}}}' in answer[idx:]:
                            in_env = True
                    if not in_env:
                        remaining += 1
                        break
                idx = answer.find(pattern, idx + 2)
    
    if remaining == 0:
        print(f"  ✅ 验证通过：无残留")
        return True
    else:
        print(f"  ❌ 验证失败：仍有 {remaining} 处未修复")
        return False
