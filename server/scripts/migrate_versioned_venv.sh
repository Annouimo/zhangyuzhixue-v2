#!/bin/bash
# Convert the existing production venv directory into a versioned symlink layout.

set -euo pipefail

DEPLOY_DIR="/opt/zhangyuzhixue-v2"
VENV_LINK="$DEPLOY_DIR/venv"
VENV_ROOT="$DEPLOY_DIR/venvs"
SERVICE="zhangyuzhixue-web"
timestamp="$(date '+%Y%m%d-%H%M%S')"
bootstrap_venv="$VENV_ROOT/bootstrap-$timestamp"
migrated=false

if [[ -L "$VENV_LINK" ]]; then
    target="$(readlink -f "$VENV_LINK")"
    test -x "$target/bin/gunicorn"
    echo "Versioned venv layout already active: $target"
    exit 0
fi
if [[ ! -d "$VENV_LINK" || ! -x "$VENV_LINK/bin/gunicorn" ]]; then
    echo "Expected production venv directory not found: $VENV_LINK" >&2
    exit 1
fi

rollback() {
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        return
    fi
    trap - EXIT
    set +e
    if $migrated; then
        systemctl stop "$SERVICE"
        rm -f -- "$VENV_LINK"
        mv "$bootstrap_venv" "$VENV_LINK"
        systemctl restart "$SERVICE"
    fi
    exit "$exit_code"
}
trap rollback EXIT

mkdir -p "$VENV_ROOT"
systemctl stop "$SERVICE"
mv "$VENV_LINK" "$bootstrap_venv"
migrated=true
ln -s "$bootstrap_venv" "$VENV_LINK"
systemctl start "$SERVICE"

for _ in {1..20}; do
    if curl -s -o /dev/null http://127.0.0.1:8001/admin/; then
        break
    fi
    sleep 1
done
systemctl is-active --quiet "$SERVICE"
test "$(readlink -f "$VENV_LINK")" = "$bootstrap_venv"
test -x "$VENV_LINK/bin/gunicorn"

trap - EXIT
echo "Versioned venv migration completed: $bootstrap_venv"
