"""Fix D-02/D-04: Convert long inline $...$ (>=40 chars) to $$...$$ block math
Fix D-03: Remove --- horizontal rules from step content
"""
import re

def fix_long_inline(content):
    """Only convert $inline$ ≥40 chars to $$block$$"""
    def replacer(m):
        inner = m.group(1)
        return '$$' + inner + '$$'
    return re.sub(r'\$([^$]{40,}?)\$', replacer, content)

def fix(conn):
    cur = conn.cursor()
    total = 0
    
    # D-02: solution step content
    cur.execute("SELECT id, content FROM qbank_solutionstep WHERE content LIKE '%$%' AND content NOT LIKE '%$$%'")
    steps = cur.fetchall()
    fixed_steps = 0
    for sid, content in steps:
        new_content = fix_long_inline(content)
        if new_content != content:
            cur.execute("UPDATE qbank_solutionstep SET content=? WHERE id=?", (new_content, sid))
            fixed_steps += 1
    print(f'  D-02: {fixed_steps} steps fixed')
    total += fixed_steps
    
    # D-04: stem (also covers D-07 remaining case id=214 which was already fixed)
    cur.execute("SELECT id, stem FROM qbank_subquestion WHERE stem LIKE '%$%' AND stem NOT LIKE '%$$%'")
    stems = cur.fetchall()
    fixed_stems = 0
    for qid, stem in stems:
        new_stem = fix_long_inline(stem)
        if new_stem != stem:
            cur.execute("UPDATE qbank_subquestion SET stem=? WHERE id=?", (new_stem, qid))
            fixed_stems += 1
    print(f'  D-04: {fixed_stems} stems fixed')
    total += fixed_stems
    
    # D-03: Remove --- from step content (horizontal rules)
    cur.execute("SELECT id, content FROM qbank_solutionstep WHERE content LIKE '%---%'")
    steps = cur.fetchall()
    fixed_hr = 0
    for sid, content in steps:
        original = content
        # Various --- patterns
        content = re.sub(r'\n\n---\n\n', '\n\n', content)
        content = re.sub(r'\n\n---\n', '\n\n', content)
        content = re.sub(r'\n---\n\n', '\n\n', content)
        content = re.sub(r'\n\n---$', '', content)  # at end of string
        content = re.sub(r'^---\n\n', '', content)  # at start
        if content != original:
            cur.execute("UPDATE qbank_solutionstep SET content=? WHERE id=?", (content, sid))
            fixed_hr += 1
    print(f'  D-03: {fixed_hr} steps with --- fixed')
    total += fixed_hr
    
    conn.commit()
    return {'fixed': total, 'tables': ['qbank_solutionstep', 'qbank_subquestion']}

def verify(conn):
    cur = conn.cursor()
    ok = True
    
    # D-02: check no long inline remains
    cur.execute("SELECT id, content FROM qbank_solutionstep WHERE content LIKE '%$%' AND content NOT LIKE '%$$%'")
    for sid, content in cur.fetchall():
        for m in re.finditer(r'\$([^$]{40,}?)\$', content):
            print(f'  ❌ D-02 Step {sid} still has long inline ({len(m.group(1))}c)')
            ok = False
            break
    
    # D-04: check no long inline in stems
    cur.execute("SELECT id, stem FROM qbank_subquestion WHERE stem LIKE '%$%' AND stem NOT LIKE '%$$%'")
    for qid, stem in cur.fetchall():
        for m in re.finditer(r'\$([^$]{40,}?)\$', stem):
            print(f'  ❌ D-04 Stem {qid} still has long inline ({len(m.group(1))}c)')
            ok = False
            break
    
    if ok:
        print('  ✅ No long inline formulas remaining')
    
    # D-03: check (sample)
    cur.execute("SELECT COUNT(*) FROM qbank_solutionstep WHERE content LIKE '%---%'")
    remaining = cur.fetchone()[0]
    print(f'  D-03: {remaining} steps still have ---')
    
    return ok
