#!/bin/bash
# Validate and deploy a Cloudflare Tunnel config without storing credentials in Git.

set -euo pipefail

CONFIG="/etc/cloudflared/config.yml"
SERVICE="cloudflared-zhangyuzhixue"
BACKUP_DIR="/var/backups/zhangyuzhixue-v2/cloudflared"
LOG_FILE="/var/log/zhangyuzhixue/cloudflared-deployments.log"
LOCK_FILE="/var/lock/zhangyuzhixue-cloudflared-deploy.lock"
CANDIDATE="${1:-$CONFIG}"
timestamp="$(date '+%Y%m%d-%H%M%S')"
backup="$BACKUP_DIR/config.$timestamp.yml"
installed=false

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "Another Tunnel configuration deployment is running" >&2
    exit 1
fi

test -f "$CONFIG"
test -f "$CANDIDATE"
mkdir -p "$BACKUP_DIR" "$(dirname "$LOG_FILE")"
cp -a "$CONFIG" "$backup"

rollback() {
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        return
    fi
    trap - EXIT
    set +e
    if $installed; then
        install -o root -g root -m 600 "$backup" "$CONFIG"
        /usr/local/bin/cloudflared --config "$CONFIG" tunnel ingress validate
        systemctl restart "$SERVICE"
    fi
    exit "$exit_code"
}
trap rollback EXIT

/usr/local/bin/cloudflared --config "$CANDIDATE" tunnel ingress validate
if [[ "$CANDIDATE" != "$CONFIG" ]]; then
    install -o root -g root -m 600 "$CANDIDATE" "$CONFIG"
    installed=true
fi
systemctl restart "$SERVICE"
systemctl is-active --quiet "$SERVICE"
curl --fail --silent --output /dev/null http://127.0.0.1:8080/
curl --fail --silent --output /dev/null https://zhangyuzhixue.top/
login_status="$(curl --silent --output /dev/null --write-out '%{http_code}' \
    https://zhangyuzhixue.zhtec123.com/api/v1/auth/login/)"
test "$login_status" = "405"

printf '%s config_sha256=%s backup=%s status=success\n' \
    "$(date --iso-8601=seconds)" \
    "$(sha256sum "$CONFIG" | awk '{print $1}')" \
    "$backup" >> "$LOG_FILE"
trap - EXIT
echo "Cloudflare Tunnel configuration deployment completed: $backup"
