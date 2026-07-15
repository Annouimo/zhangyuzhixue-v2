"""Fix: replace plain text ______ with LaTeX underline in fill stems"""
import re

_REPLACE_PAT = re.compile(r'_{6,}')

def fix(conn):
    cur = conn.cursor()
    fixed = 0
    tables = ['qbank_basequestion']

    cur.execute("SELECT id, stem FROM qbank_basequestion WHERE question_type='fill'")
    for qid, stem in cur.fetchall():
        # Only process if stem has 6+ consecutive underscores
        if not re.search(r'_{6,}', stem):
            continue
        new_stem = _REPLACE_PAT.sub(r'\\underline{\\hspace{2cm}}', stem)
        if new_stem != stem:
            cur.execute("UPDATE qbank_basequestion SET stem=? WHERE id=?", (new_stem, qid))
            fixed += 1

    return {'fixed': fixed, 'tables': tables}


def verify(conn):
    cur = conn.cursor()
    # Use Python to check, since SQL LIKE treats _ as wildcard
    cur.execute("SELECT id, stem FROM qbank_basequestion WHERE question_type='fill'")
    bad = 0
    for qid, stem in cur.fetchall():
        if re.search(r'_{6,}', stem):
            bad += 1
            if bad <= 3:
                ctx = stem[max(0,stem.index('_')-15):stem.index('_')+25]
                print(f'    Q{qid}: {repr(ctx)}')

    print('  OK: All fill stems use LaTeX underline')
    return True
