#!/bin/bash
# 章鱼智学 v2 — 数据库每日备份
# 位置：server/scripts/backup_db.sh
# crontab 示例：0 4 * * * /opt/zhangyuzhixue-v2/server/scripts/backup_db.sh

set -euo pipefail

cd /

PROJECT="zhangyuzhixue-v2"
PROJECT_DIR="/opt/$PROJECT/server"
BACKUP_DIR="/var/backups/$PROJECT/db"
DATE=$(date +%Y%m%d)
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"

# 1. 备份 SQLite 主库（gzip 压缩）
cp "$PROJECT_DIR/db.sqlite3" "$BACKUP_DIR/db.$DATE.sqlite3"
gzip -f "$BACKUP_DIR/db.$DATE.sqlite3"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] db backup: $(ls -lh "$BACKUP_DIR/db.$DATE.sqlite3.gz" | awk '{print $5}')"

# 2. 备份构建产物（qbank/lecture .db.gz 文件）
if [ -d "$PROJECT_DIR/media/db" ]; then
    cp "$PROJECT_DIR/media/db/"*.db.gz "$BACKUP_DIR/" 2>/dev/null || true
fi

# 3. 删除 30 天前的旧备份文件
find "$BACKUP_DIR" -name "db.*.sqlite3.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.db.gz" -mtime +$RETENTION_DAYS ! -name "db.*.sqlite3.gz" -delete

# 4. 清理空目录
# (无，mkdir -p 已经创建)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] backup complete, $(ls "$BACKUP_DIR"/*.gz 2>/dev/null | wc -l) gz files in $BACKUP_DIR"
