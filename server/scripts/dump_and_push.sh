#!/bin/bash
# 章鱼智学 v2 — 业务数据 JSON 导出并推送到 Gitee 数据仓库
# crontab: 10 4 * * * /opt/zhangyuzhixue-v2/server/scripts/dump_and_push.sh

set -euo pipefail

PROJECT_DIR="/opt/zhangyuzhixue-v2/server"
DATA_REPO_DIR="/var/data-dumps/zhangyuzhixue-v2-data"
DATE=$(date +%Y%m%d)

# 1. 导出 JSON
python "$PROJECT_DIR/scripts/dump_data.py" --out "$DATA_REPO_DIR/data_dumps/$DATE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] dump done"

# 2. 提交到数据仓库
cd "$DATA_REPO_DIR" || { echo "FAIL: cd $DATA_REPO_DIR"; exit 1; }

# 拉最新（防止本地落后于远端）
git pull --ff-only origin master 2>/dev/null || echo "(pull skipped or no changes)"

git add -A
git commit -m "chore(data-dump): $DATE" || echo "(no changes to commit)"
git push origin master
echo "[$(date '+%Y-%m-%d %H:%M:%S')] push done"
