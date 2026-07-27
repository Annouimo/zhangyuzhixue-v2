#!/bin/bash
# Install a weekly isolated database restore drill for the ubuntu service user.

set -euo pipefail

CRON_FILE="/etc/cron.d/zhangyuzhixue-restore-drill"
LOG_DIR="/var/log/zhangyuzhixue"
LOG_FILE="$LOG_DIR/restore-drill.log"
LOCK_FILE="/var/lock/zhangyuzhixue-restore-drill.lock"
DRILL_SCRIPT="/opt/zhangyuzhixue-v2/server/scripts/drill_restore_db.sh"

test -f "$DRILL_SCRIPT"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
chown ubuntu:ubuntu "$LOG_FILE"
chmod 640 "$LOG_FILE"
touch "$LOCK_FILE"
chown ubuntu:ubuntu "$LOCK_FILE"
chmod 640 "$LOCK_FILE"

printf '%s\n' \
    'SHELL=/bin/bash' \
    'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
    '0 5 * * 0 ubuntu flock -n /var/lock/zhangyuzhixue-restore-drill.lock bash /opt/zhangyuzhixue-v2/server/scripts/drill_restore_db.sh >> /var/log/zhangyuzhixue/restore-drill.log 2>&1' \
    > "$CRON_FILE"
chown root:root "$CRON_FILE"
chmod 644 "$CRON_FILE"

echo "Installed weekly restore drill: $CRON_FILE"
