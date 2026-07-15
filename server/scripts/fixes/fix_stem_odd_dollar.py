"""Fix D-05: 3 stems with odd $ count (truncated formulas)
id=211: ')$...' → should start with '$'
id=401: '=\dfrac...$' → should start with '$'
id=910: ')$...' → should start with '$'
"""
import re

def fix(conn):
    cur = conn.cursor()
    fixes = {
        211: ('$)$', '$$)'),  # First char is ')', add '$' before
        401: ('$=\\dfrac', '$$=\\dfrac'),  # Starts with '=', add '$' before
        910: ('$)$', '$$)'),  # Same as 211
    }
    fixed = 0
    for qid, (old_prefix, new_prefix) in fixes.items():
        cur.execute("SELECT stem FROM qbank_subquestion WHERE id=?", (qid,))
        row = cur.fetchone()
        if row:
            stem = row[0]
            new_stem = stem
            # Prepend $ if stem starts with ) or =
            if new_stem.startswith(')'):
                new_stem = '$' + new_stem
            elif new_stem.startswith('='):
                new_stem = '$' + new_stem
            if new_stem != stem:
                cur.execute("UPDATE qbank_subquestion SET stem=? WHERE id=?", (new_stem, qid))
                fixed += 1
                print(f'  id={qid}: {repr(stem[:30])} → {repr(new_stem[:30])}')
    conn.commit()
    return {'fixed': fixed, 'table': 'qbank_subquestion'}

def verify(conn):
    cur = conn.cursor()
    for qid in [211, 401, 910]:
        cur.execute("SELECT stem FROM qbank_subquestion WHERE id=?", (qid,))
        row = cur.fetchone()
        stem = row[0]
        dollar_count = stem.count('$')
        ok = dollar_count % 2 == 0
        status = '✅' if ok else '❌'
        print(f'  {status} id={qid}: {dollar_count} $, {repr(stem[:30])}')
    return all(
        cur.execute("SELECT stem FROM qbank_subquestion WHERE id=?", (qid,)).fetchone()[0].count('$') % 2 == 0
        for qid in [211, 401, 910]
    )
