#!/bin/bash
# Check production services, backups, certificates and public endpoints.

set -euo pipefail

PROJECT="zhangyuzhixue-v2"
BACKUP_DIR="/var/backups/$PROJECT/db"
RESTORE_LOG="/var/log/zhangyuzhixue/restore-drill.log"
RESTORE_CRON="/etc/cron.d/zhangyuzhixue-restore-drill"
WEBHOOK_FILE="/etc/zhangyuzhixue/alert-webhook-url"
DISABLE_ALERT_DELIVERY="${DISABLE_ALERT_DELIVERY:-0}"
MAX_DISK_PERCENT="${MAX_DISK_PERCENT:-85}"
MAX_BACKUP_AGE_HOURS="${MAX_BACKUP_AGE_HOURS:-30}"
MAX_RESTORE_AGE_HOURS="${MAX_RESTORE_AGE_HOURS:-192}"
CERT_MIN_SECONDS="${CERT_MIN_SECONDS:-1209600}"

failures=()

fail() {
    failures+=("$1")
}

for service in nginx zhangyuzhixue-web.service cloudflared-zhangyuzhixue.service; do
    systemctl is-active --quiet "$service" || fail "service inactive: $service"
done

disk_percent="$(df --output=pcent / | tail -1 | tr -dc '0-9')"
if [[ -z "$disk_percent" ]] || (( disk_percent >= MAX_DISK_PERCENT )); then
    fail "root disk usage is ${disk_percent:-unknown}% (limit ${MAX_DISK_PERCENT}%)"
fi

latest_backup="$(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'db.*.sqlite3.gz' \
    -printf '%T@ %p\n' | sort -nr | sed -n '1p' | cut -d' ' -f2-)"
if [[ -z "$latest_backup" ]]; then
    fail "no database backup found"
else
    backup_age="$(( ($(date +%s) - $(stat -c %Y "$latest_backup")) / 3600 ))"
    (( backup_age <= MAX_BACKUP_AGE_HOURS )) || \
        fail "latest database backup is ${backup_age}h old"
    gzip -t "$latest_backup" || fail "latest database backup failed gzip validation"
fi

if [[ -s "$RESTORE_LOG" ]]; then
    last_restore_epoch="$(grep 'Restore drill passed:' "$RESTORE_LOG" | tail -1 \
        | sed -n 's/^\[\([^]]*\)\].*/\1/p' || true)"
    if [[ -n "$last_restore_epoch" ]]; then
        restore_epoch="$(date -d "$last_restore_epoch" +%s 2>/dev/null || true)"
    else
        restore_epoch="$(stat -c %Y "$RESTORE_LOG")"
    fi
    restore_age="$(( ($(date +%s) - restore_epoch) / 3600 ))"
    (( restore_age <= MAX_RESTORE_AGE_HOURS )) || \
        fail "last successful restore drill is ${restore_age}h old"
elif [[ -f "$RESTORE_CRON" ]]; then
    cron_age="$(( ($(date +%s) - $(stat -c %Y "$RESTORE_CRON")) / 3600 ))"
    (( cron_age <= MAX_RESTORE_AGE_HOURS )) || fail "restore drill has never succeeded"
else
    fail "restore drill cron is missing"
fi

while read -r certificate; do
    [[ -n "$certificate" && -f "$certificate" ]] || continue
    openssl x509 -checkend "$CERT_MIN_SECONDS" -noout -in "$certificate" >/dev/null || \
        fail "certificate expires within 14 days: $certificate"
done < <(nginx -T 2>/dev/null | awk '$1 == "ssl_certificate" {gsub(";", "", $2); print $2}' | sort -u)

for url in \
    https://zhangyuzhixue.top/ \
    https://zhangyuzhixue.zhtec123.com/api/v1/sync/qbank/version/; do
    curl --fail --silent --show-error --max-time 15 "$url" >/dev/null || \
        fail "public endpoint failed: $url"
done

if (( ${#failures[@]} > 0 )); then
    message="Production health check failed: $(IFS='; '; echo "${failures[*]}")"
    logger -t "$PROJECT-health" -- "$message"
    echo "$message" >&2
    if [[ "$DISABLE_ALERT_DELIVERY" != "1" && -r "$WEBHOOK_FILE" ]]; then
        webhook="$(head -1 "$WEBHOOK_FILE")"
        [[ -z "$webhook" ]] || curl --silent --show-error --max-time 10 \
            --data-urlencode "content=$message" "$webhook" >/dev/null || true
    fi
    exit 1
fi

echo "Production health check passed: disk=${disk_percent}%, backup=$(basename "$latest_backup")"
