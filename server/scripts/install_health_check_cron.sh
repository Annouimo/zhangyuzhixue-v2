#!/bin/bash
# Install the production health check without storing alert credentials in Git.

set -euo pipefail

CHECK_SCRIPT="/opt/zhangyuzhixue-v2/server/scripts/check_production_health.sh"
CRON_FILE="/etc/cron.d/zhangyuzhixue-health-check"
LOG_DIR="/var/log/zhangyuzhixue"
LOG_FILE="$LOG_DIR/health-check.log"
LOCK_FILE="/var/lock/zhangyuzhixue-health-check.lock"

test -f "$CHECK_SCRIPT"
install -d -o root -g root -m 755 "$LOG_DIR"
touch "$LOG_FILE" "$LOCK_FILE"
chown root:root "$LOG_FILE" "$LOCK_FILE"
chmod 640 "$LOG_FILE" "$LOCK_FILE"

printf '%s\n' \
    'SHELL=/bin/bash' \
    'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
    '*/10 * * * * root flock -n /var/lock/zhangyuzhixue-health-check.lock bash /opt/zhangyuzhixue-v2/server/scripts/check_production_health.sh >> /var/log/zhangyuzhixue/health-check.log 2>&1' \
    > "$CRON_FILE"
chown root:root "$CRON_FILE"
chmod 644 "$CRON_FILE"

echo "Installed production health check: $CRON_FILE"
