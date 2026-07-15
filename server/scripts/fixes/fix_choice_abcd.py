"""Fix A: Strip ABCD options from choice question stems (2026 年 1-10 题)"""
import re

def fix(conn):
    cur = conn.cursor()
    fixed = 0
    tables = ['qbank_basequestion']

    cur.execute("SELECT id, stem FROM qbank_basequestion WHERE question_type='choice' AND year=2026")
    for qid, stem in cur.fetchall():
        # Strip from the FIRST \n\nA[.．] to end
        new_stem = re.sub(r'\n\n[ABCD][.．].*$', '', stem, flags=re.DOTALL)
        if new_stem != stem:
            cur.execute("UPDATE qbank_basequestion SET stem=? WHERE id=?", (new_stem, qid))
            fixed += 1
    return {'fixed': fixed, 'tables': tables}

def verify(conn):
    cur = conn.cursor()
    cur.execute("SELECT id, stem FROM qbank_basequestion WHERE question_type='choice' AND year=2026")
    bad = 0
    for qid, stem in cur.fetchall():
        # Should not have \n\nA[.．] pattern (options embedded)
        has = bool(re.search(r'\n\n[ABCD][.．]', stem))
        if has:
            bad += 1
    if bad:
        print(f'  ❌ {bad} choice stems still contain ABCD options')
        return False
    print('  ✅ All 2026 choice stems clean')
    return True
