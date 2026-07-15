"""Fix: Replace / with _ in qbank_basequestion.images paths

After directory flattening, paths like mock1/2023/haidian/q16.webp
become mock1_2023_haidian_q16.webp

Usage: python scripts/run_fix.py fix_flat_paths --local
"""
import json

def fix(conn):
    cur = conn.cursor()
    cur.execute("SELECT id, images FROM qbank_basequestion WHERE images IS NOT NULL AND images != '[]'")
    rows = cur.fetchall()
    fixed = 0
    for qid, img_json in rows:
        try:
            paths = json.loads(img_json) if isinstance(img_json, str) else img_json
        except json.JSONDecodeError:
            continue
        if not isinstance(paths, list):
            continue
        new_paths = [p.replace('/', '_') for p in paths]
        if new_paths != paths:
            cur.execute(
                "UPDATE qbank_basequestion SET images=? WHERE id=?",
                (json.dumps(new_paths, ensure_ascii=False), qid)
            )
            fixed += 1
    return {'fixed': fixed, 'tables': ['qbank_basequestion']}

def verify(conn):
    cur = conn.cursor()
    cur.execute("SELECT id, images FROM qbank_basequestion WHERE images IS NOT NULL AND images != '[]'")
    remaining = 0
    for qid, img_json in cur.fetchall():
        if '/' in img_json:
            remaining += 1
            if remaining <= 3:
                print(f'  ❌ Q{qid}: still has /: {img_json[:60]}')
    if remaining == 0:
        print('  ✅ All paths flattened (no / in images field)')
        return True
    print(f'  ❌ {remaining} records still contain /')
    return False
