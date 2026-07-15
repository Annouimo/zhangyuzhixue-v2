"""Fix BOLD v2: Remove ALL whitespace before ** delimiters
CommonMark: ** preceded by whitespace cannot open or close.
Fix: `word **text**` → `word **text**` (remove space before **)
Only for ** that are followed by non-whitespace (formatting markers).
"""
import re

def fix(conn):
    cur = conn.cursor()
    cur.execute("SELECT id, content FROM qbank_solutionstep WHERE content LIKE '%**%'")
    fixed = 0
    for sid, content in cur.fetchall():
        original = content
        # Remove space before ** when ** is followed by non-space
        # Pattern: (space)**(non-space,non-newline) → **(non-space,non-newline)
        content = re.sub(r' (?=\*\*[^ \*\n])', '', content)
        if content != original:
            cur.execute("UPDATE qbank_solutionstep SET content=? WHERE id=?", (content, sid))
            fixed += 1
    conn.commit()
    return {'fixed': fixed, 'table': 'qbank_solutionstep'}

def verify(conn):
    cur = conn.cursor()
    cur.execute("SELECT id, content FROM qbank_solutionstep WHERE content LIKE '%**%'")
    bad = 0
    for sid, content in cur.fetchall():
        for m in re.finditer(r'\*\*', content):
            pos = m.start()
            if pos > 0:
                before = content[pos-1]
                if before == ' ':
                    after = content[pos+2] if pos+2 < len(content) else ''
                    # Only flag if ** has non-space after (meaning it's a formatting marker)
                    if after and after not in (' ', '\n'):
                        bad += 1
                        ctx_b = repr(content[max(0,pos-8):pos])
                        ctx_a = repr(content[pos+2:min(len(content),pos+8)])
                        print(f'  ⚠ Step {sid}: ...{ctx_b}**{ctx_a}')
                        break  # one per step
    if bad == 0:
        print('  ✅ All ** properly formatted')
    return bad == 0
