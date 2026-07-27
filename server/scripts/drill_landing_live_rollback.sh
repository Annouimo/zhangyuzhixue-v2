#!/bin/bash
# Perform a short, controlled rollback drill against the live Landing directory.

set -euo pipefail

DEPLOY_ROOT="/opt/zhangyuzhixue-v2"
LANDING_DIR="$DEPLOY_ROOT/landing"
BACKUP_DIR="$DEPLOY_ROOT/backups"
LOCK_FILE="/var/lock/zhangyuzhixue-landing-deploy.lock"
timestamp="$(date '+%Y%m%d-%H%M%S')"
backup="$BACKUP_DIR/landing-live-drill-$timestamp.tar.gz"
work_dir="$(mktemp -d /tmp/zhangyuzhixue-landing-live-drill.XXXXXX)"
before="$work_dir/before.sha256"
after="$work_dir/after.sha256"

cleanup() {
    rm -rf -- "$work_dir"
}
trap cleanup EXIT

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "Another Landing deployment is running" >&2
    exit 1
fi

validate_landing_root() {
    test "$LANDING_DIR" = "/opt/zhangyuzhixue-v2/landing"
}

manifest() {
    local output="$1"
    (
        cd "$LANDING_DIR"
        find . -type f -print0 | sort -z | xargs -0 sha256sum
    ) > "$output"
}

restore() {
    validate_landing_root
    rm -rf -- "$LANDING_DIR"
    tar -xzf "$backup" -C "$DEPLOY_ROOT"
}

test -f "$LANDING_DIR/index.html"
mkdir -p "$BACKUP_DIR"
manifest "$before"
tar -czf "$backup" -C "$DEPLOY_ROOT" landing

set +e
(
    set -eE
    trap restore ERR
    printf '\n<!-- live-rollback-drill -->\n' >> "$LANDING_DIR/index.html"
    printf 'failed-release\n' > "$LANDING_DIR/.rollback-drill-extra"
    false
)
failure_status=$?
set -e

if [[ $failure_status -eq 0 ]]; then
    echo "Failure injection unexpectedly succeeded" >&2
    exit 1
fi

manifest "$after"
cmp --silent "$before" "$after"
test ! -e "$LANDING_DIR/.rollback-drill-extra"
if grep -q 'live-rollback-drill' "$LANDING_DIR/index.html"; then
    echo "Injected marker survived rollback" >&2
    exit 1
fi
nginx -t

echo "Live Landing rollback drill passed: $backup"
