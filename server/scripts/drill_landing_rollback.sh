#!/bin/bash
# Exercise Landing rollback against an isolated copy of the production tree.

set -euo pipefail

LANDING_DIR="/opt/zhangyuzhixue-v2/landing"
drill_dir="$(mktemp -d /tmp/zhangyuzhixue-landing-drill.XXXXXX)"
sandbox="$drill_dir/site"
backup="$drill_dir/landing-backup.tar.gz"
before="$drill_dir/before.sha256"
after="$drill_dir/after.sha256"

cleanup() {
    rm -rf -- "$drill_dir"
}
trap cleanup EXIT

test -f "$LANDING_DIR/index.html"
cp -a "$LANDING_DIR" "$sandbox"
tar -czf "$backup" -C "$drill_dir" site

manifest() {
    local root="$1"
    local output="$2"
    (
        cd "$root"
        find . -type f -print0 | sort -z | xargs -0 sha256sum
    ) > "$output"
}

manifest "$sandbox" "$before"

set +e
(
    set -eE
    rollback() {
        rm -rf -- "$sandbox"
        tar -xzf "$backup" -C "$drill_dir"
    }
    trap rollback ERR

    printf '\nrollback-drill-marker\n' >> "$sandbox/index.html"
    rm -f -- "$sandbox/robots.txt"
    false
)
failure_status=$?
set -e

if [[ $failure_status -eq 0 ]]; then
    echo "Failure injection unexpectedly succeeded" >&2
    exit 1
fi

manifest "$sandbox" "$after"
cmp --silent "$before" "$after"
test -f "$sandbox/robots.txt"
if grep -q 'rollback-drill-marker' "$sandbox/index.html"; then
    echo "Injected marker survived rollback" >&2
    exit 1
fi

echo "Landing rollback drill passed: files restored byte-for-byte"
