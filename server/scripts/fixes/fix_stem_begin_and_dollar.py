"""Fix D-07: \begin{cases}/\begin{pmatrix} in inline $...$ → $$...$$
Fix D-06: $$(range) should be $(range) (not block math)
"""
import re

def fix(conn):
    cur = conn.cursor()
    fixed_total = 0
    
    # D-07: \begin inside inline $ → $$
    cur.execute("""
        SELECT id, stem FROM qbank_subquestion 
        WHERE id IN (214, 560, 883)
    """)
    fixed = 0
    for qid, stem in cur.fetchall():
        original = stem
        # Replace $...\begin{...}...$ with $$...\begin{...}...$$
        # Use regex: find $...$ where content contains \begin{...}
        stem = re.sub(r'\$([^$]*?\\begin\{[^}]+\}[^$]*?)\$', r'$$\1$$', stem)
        if stem != original:
            cur.execute("UPDATE qbank_subquestion SET stem=? WHERE id=?", (stem, qid))
            fixed += 1
            print(f'  D-07 id={qid}: fixed')
    fixed_total += fixed
    print(f'  D-07: {fixed} stems fixed')
    
    # D-06: $$(range) misuse → $(range)
    # Pattern: inline text followed by $$(expr)$ → $(expr)$
    cur.execute("""
        SELECT id, stem FROM qbank_subquestion 
        WHERE id IN (30, 50, 51, 615, 621)
    """)
    fixed = 0
    for qid, stem in cur.fetchall():
        original = stem
        # Fix: $$(paren...) → $(paren...)
        # Pattern: $$(content)$ where content is not a multi-line block
        stem = re.sub(r'\$\$\(([^)]+)\)\$', r'$(\1)$', stem)
        # Also handle $$(content) without closing $ at some positions
        stem = re.sub(r'\$\$\(', r'$(', stem)
        if stem != original:
            cur.execute("UPDATE qbank_subquestion SET stem=? WHERE id=?", (stem, qid))
            fixed += 1
            print(f'  D-06 id={qid}: fixed')
    fixed_total += fixed
    print(f'  D-06: {fixed} stems fixed')
    
    conn.commit()
    return {'fixed': fixed_total, 'table': 'qbank_subquestion'}

def verify(conn):
    cur = conn.cursor()
    ok = True
    
    # D-07 check
    cur.execute("""
        SELECT id, stem FROM qbank_subquestion 
        WHERE id IN (214, 560, 883)
    """)
    for qid, stem in cur.fetchall():
        if '\\begin{' in stem:
            # Check if wrapped in $$...$$ not $...$
            # stem should have $$ before \begin
            idx = stem.find('\\begin{')
            before = stem[max(0,idx-5):idx]
            after_begin = stem[idx:idx+50]
            has_double = '$$' in before
            status = '✅' if has_double else '❌'
            print(f'  {status} D-07 id={qid}: {repr(before)}...{repr(after_begin[:20])}')
            if not has_double:
                ok = False
    
    # D-06 check  
    cur.execute("""
        SELECT id, stem FROM qbank_subquestion 
        WHERE id IN (30, 50, 51, 615, 621)
    """)
    for qid, stem in cur.fetchall():
        # Should not have $$( or $$[ (parenthetical block indicators without close)
        if '$$(' in stem or '$$[' in stem:
            print(f'  ❌ D-06 id={qid}: still has $$( pattern')
            ok = False
        else:
            print(f'  ✅ D-06 id={qid}: clean')
    
    return ok
