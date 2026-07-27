#!/bin/bash
# Restore a compressed production backup into an isolated temporary database.

set -euo pipefail

DEPLOY_DIR="/opt/zhangyuzhixue-v2"
BACKUP_DIR="/var/backups/zhangyuzhixue-v2/db"
PYTHON="$DEPLOY_DIR/venv/bin/python"
BACKUP_FILE="${1:-}"

if [[ -z "$BACKUP_FILE" ]]; then
    BACKUP_FILE="$(find "$BACKUP_DIR" -maxdepth 1 -type f \
        -name 'db.*.sqlite3.gz' -printf '%T@ %p\n' \
        | sort -nr | sed -n '1p' | cut -d' ' -f2-)"
fi

case "$BACKUP_FILE" in
    "$BACKUP_DIR"/db.*.sqlite3.gz) ;;
    *)
        echo "Backup must be a database archive in $BACKUP_DIR" >&2
        exit 1
        ;;
esac
if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Backup not found: $BACKUP_FILE" >&2
    exit 1
fi

restore_dir="$(mktemp -d /tmp/zhangyuzhixue-restore-drill.XXXXXX)"
restore_db="$restore_dir/db.sqlite3"
cleanup() {
    rm -rf -- "$restore_dir"
}
trap cleanup EXIT

gzip -t "$BACKUP_FILE"
gunzip -c "$BACKUP_FILE" > "$restore_db"

"$PYTHON" - "$restore_db" <<'PY'
import sqlite3
import sys

path = sys.argv[1]
connection = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
foreign_keys = connection.execute("PRAGMA foreign_key_check").fetchall()
table_count = connection.execute(
    "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table'"
).fetchone()[0]
migration_count = connection.execute(
    "SELECT COUNT(*) FROM django_migrations"
).fetchone()[0]
connection.close()

if integrity != "ok" or foreign_keys:
    raise SystemExit(
        f"Restore validation failed: integrity={integrity}, "
        f"foreign_key_violations={len(foreign_keys)}"
    )
if table_count == 0 or migration_count == 0:
    raise SystemExit(
        f"Restore validation failed: tables={table_count}, "
        f"migrations={migration_count}"
    )
print(
    f"SQLite validation passed: integrity={integrity}, "
    f"foreign_key_violations=0, tables={table_count}, "
    f"migrations={migration_count}"
)
PY

cd "$DEPLOY_DIR/server"
DB_NAME="$restore_db" "$PYTHON" manage.py migrate --noinput
DB_NAME="$restore_db" "$PYTHON" manage.py migrate --check

"$PYTHON" - "$restore_db" <<'PY'
import sqlite3
import sys

connection = sqlite3.connect(f"file:{sys.argv[1]}?mode=ro", uri=True)
integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
foreign_keys = connection.execute("PRAGMA foreign_key_check").fetchall()
migration_count = connection.execute(
    "SELECT COUNT(*) FROM django_migrations"
).fetchone()[0]
connection.close()
if integrity != "ok" or foreign_keys:
    raise SystemExit(
        f"Post-migration validation failed: integrity={integrity}, "
        f"foreign_key_violations={len(foreign_keys)}"
    )
print(
    f"Post-migration validation passed: integrity={integrity}, "
    f"foreign_key_violations=0, migrations={migration_count}"
)
PY

echo "Restore drill passed: $BACKUP_FILE"
