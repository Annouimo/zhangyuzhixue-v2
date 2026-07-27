#!/bin/bash
# Exercise the post-receive rollback mechanics in an isolated Git/SQLite sandbox.

set -euo pipefail

drill_dir="$(mktemp -d /tmp/zhangyuzhixue-backend-drill.XXXXXX)"
bare_repo="$drill_dir/repository.git"
source_repo="$drill_dir/source"
deploy_dir="$drill_dir/deploy"
backup_file="$drill_dir/db.sqlite3.gz"
db_file="$deploy_dir/server/db.sqlite3"
venv_root="$deploy_dir/venvs"
venv_link="$deploy_dir/venv"
old_venv="$venv_root/old"
new_venv="$venv_root/new"

cleanup() {
    rm -rf -- "$drill_dir"
}
trap cleanup EXIT

git init --bare --quiet "$bare_repo"
git init --quiet "$source_repo"
git -C "$source_repo" config user.name "Deployment Drill"
git -C "$source_repo" config user.email "deployment-drill@localhost"

mkdir -p "$source_repo/server"
printf 'old\n' > "$source_repo/server/version.txt"
printf 'restore-me\n' > "$source_repo/server/removed-in-new.txt"
git -C "$source_repo" add server
git -C "$source_repo" commit --quiet -m old
old_rev="$(git -C "$source_repo" rev-parse HEAD)"

printf 'new\n' > "$source_repo/server/version.txt"
rm -f -- "$source_repo/server/removed-in-new.txt"
git -C "$source_repo" add -A server
git -C "$source_repo" commit --quiet -m new
new_rev="$(git -C "$source_repo" rev-parse HEAD)"
git -C "$source_repo" push --quiet "$bare_repo" HEAD:refs/heads/master

mkdir -p "$deploy_dir"
git --git-dir="$bare_repo" --work-tree="$deploy_dir" \
    checkout -f "$old_rev" -- server

python3 - "$db_file" <<'PY'
import sqlite3
import sys

connection = sqlite3.connect(sys.argv[1])
connection.execute("PRAGMA foreign_keys = ON")
connection.execute("CREATE TABLE stable_data (id INTEGER PRIMARY KEY, value TEXT)")
connection.execute("INSERT INTO stable_data (value) VALUES ('old')")
connection.commit()
connection.close()
PY
old_db_hash="$(sha256sum "$db_file" | cut -d' ' -f1)"
gzip -c "$db_file" > "$backup_file"
mkdir -p "$old_venv/bin"
printf '#!/bin/sh\n' > "$old_venv/bin/python"
chmod 755 "$old_venv/bin/python"
ln -s "$old_venv" "$venv_link"
git --git-dir="$bare_repo" update-ref \
    refs/heads/master "$old_rev" "$new_rev"

validate_database() {
    python3 - "$db_file" <<'PY'
import sqlite3
import sys

connection = sqlite3.connect(f"file:{sys.argv[1]}?mode=ro", uri=True)
integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
foreign_keys = connection.execute("PRAGMA foreign_key_check").fetchall()
failed_table = connection.execute(
    "SELECT COUNT(*) FROM sqlite_master "
    "WHERE type = 'table' AND name = 'failed_release'"
).fetchone()[0]
connection.close()
if integrity != "ok" or foreign_keys or failed_table:
    raise SystemExit(
        f"Rollback validation failed: integrity={integrity}, "
        f"foreign_key_violations={len(foreign_keys)}, "
        f"failed_table={failed_table}"
    )
PY
}

for failure_stage in dependency migration health; do
    mkdir -p "$new_venv/bin"
    printf '#!/bin/sh\n' > "$new_venv/bin/python"
    chmod 755 "$new_venv/bin/python"
    git --git-dir="$bare_repo" update-ref \
        refs/heads/master "$new_rev" "$old_rev"

    if [[ "$failure_stage" != "dependency" ]]; then
        git --git-dir="$bare_repo" --work-tree="$deploy_dir" \
            checkout -f "$new_rev" -- server
    fi
    if [[ "$failure_stage" == "health" ]]; then
        python3 - "$db_file" <<'PY'
import sqlite3
import sys

connection = sqlite3.connect(sys.argv[1])
connection.execute("CREATE TABLE failed_release (id INTEGER PRIMARY KEY)")
connection.commit()
connection.close()
PY
        replacement="$venv_root/.next"
        ln -s "$new_venv" "$replacement"
        mv -Tf "$replacement" "$venv_link"
    fi

    set +e
    (
        set -e
        rollback() {
            exit_code=$?
            trap - EXIT
            set +e
            if [[ "$(readlink -f "$venv_link")" == "$new_venv" ]]; then
                replacement="$venv_root/.rollback"
                ln -s "$old_venv" "$replacement"
                mv -Tf "$replacement" "$venv_link"
            fi
            git --git-dir="$bare_repo" --work-tree="$deploy_dir" \
                checkout -f "$old_rev" -- server
            git --git-dir="$bare_repo" update-ref \
                refs/heads/master "$old_rev" "$new_rev"
            rm -f -- "$db_file-wal" "$db_file-shm"
            gunzip -c "$backup_file" > "$db_file"
            rm -rf -- "$new_venv"
            exit "$exit_code"
        }
        trap rollback EXIT
        false
    )
    failure_status=$?
    set -e

    if [[ $failure_status -eq 0 ]]; then
        echo "Failure injection unexpectedly succeeded: $failure_stage" >&2
        exit 1
    fi

    test "$(git --git-dir="$bare_repo" rev-parse refs/heads/master)" = "$old_rev"
    test "$(cat "$deploy_dir/server/version.txt")" = "old"
    test -f "$deploy_dir/server/removed-in-new.txt"
    test "$(sha256sum "$db_file" | cut -d' ' -f1)" = "$old_db_hash"
    test "$(readlink -f "$venv_link")" = "$old_venv"
    test ! -e "$new_venv"
    validate_database
    echo "Backend rollback stage passed: $failure_stage"
done

echo "Backend rollback drill passed for all failure stages"
