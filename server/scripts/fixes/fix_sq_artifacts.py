"""Fix B+C+D+E: Strip sub-question stem artifacts

B: Strip (1)/(2)/(3)/(Ⅰ) prefix from stems that start with them
C: Strip trailing \n\n--- (179 cases)
D: Strip trailing \n\n| (2 cases)
E: Strip embedded <img ...> HTML tags (34 cases, mostly overlap with C)
"""
import re

def fix(conn):
    cur = conn.cursor()
    fixed = 0
    tables = ['qbank_subquestion']

    cur.execute("SELECT id, stem FROM qbank_subquestion WHERE stem IS NOT NULL AND stem != ''")
    for sid, stem in cur.fetchall():
        original = stem
        changed = False

        # E: strip <img ...> tags first (before ---/| removal)
        if '<img' in stem.lower():
            stem = re.sub(r'<img[^>]*>', '', stem)
            changed = True

        # C: strip trailing \n\n--- (possibly followed by $ or $$)
        if '\n\n---' in stem:
            stem = re.sub(r'\n\n---[\$]*\s*$', '', stem)
            changed = True

        # D: strip trailing \n\n| (only at end, not inside tables)
        if stem.rstrip().endswith('|') and '\n\n|' in stem:
            stem = re.sub(r'\n\n\|\s*$', '', stem)
            changed = True

        # B: strip leading (1)/(2)/(3)/(Ⅰ)/(Ⅱ)/(Ⅲ) prefix
        s = stem.strip()
        m = re.match(r'^\((\d|[ⅠⅡⅢⅣⅤ])\)', s)
        if m:
            prefix_len = len(m.group(0))
            stem = s[prefix_len:].lstrip()
            changed = True

        if changed:
            cur.execute("UPDATE qbank_subquestion SET stem=? WHERE id=?", (stem, sid))
            fixed += 1

    return {'fixed': fixed, 'tables': tables}


def verify(conn):
    cur = conn.cursor()
    cur.execute("SELECT id, stem FROM qbank_subquestion WHERE stem IS NOT NULL AND stem != ''")
    bad_b = bad_c = bad_d = bad_e = 0
    for sid, stem in cur.fetchall():
        s = stem.strip()

        # B: should not start with (1)/(2)/(Ⅰ) etc.
        if re.match(r'^\(\d+\)', s) or re.match(r'^\([ⅠⅡⅢⅣⅤ]\)', s):
            bad_b += 1

        # C: should not have \n\n--- (including ---$ / ---$$)
        if re.search(r'\n\n---[\$]*\s*$', s) or re.search(r'\n\n---\n', s):
            bad_c += 1

        # D: should not have \n\n| only at the very end (not table content)
        if re.search(r'\n\n\|\s*$', s):
            bad_d += 1

        # E: should not have <img
        if '<img' in stem.lower():
            bad_e += 1

    ok = True
    if bad_b:
        print(f'  ❌ {bad_b} sub-questions still start with (number)/(Ⅰ) prefix')
        ok = False
    else:
        print(f'  ✅ No sub-questions start with (number)/(Ⅰ) prefix')

    if bad_c:
        print(f'  ❌ {bad_c} sub-questions still have \\n\\n---')
        ok = False
    else:
        print(f'  ✅ No sub-questions have \\n\\n---')

    if bad_d:
        print(f'  ❌ {bad_d} sub-questions still have \\n\\n|')
        ok = False
    else:
        print(f'  ✅ No sub-questions have \\n\\n| artifacts')

    if bad_e:
        print(f'  ❌ {bad_e} sub-questions still have <img tags')
        ok = False
    else:
        print(f'  ✅ No sub-questions have <img tags')

    return ok
