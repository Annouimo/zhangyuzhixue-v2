#!/bin/bash
# 章鱼智学 v2 — 一键部署脚本（Phase 6.4）
#
# 用法：
#   ./scripts/deploy_prod.sh                    # 默认部署到正式环境
#   ./scripts/deploy_prod.sh --dry-run          # 只打印要执行的命令，但不执行
#
# 前提：
#   - 本地 git 已配置 server remote（指向 ECS bare repo）
#   - ECS 上 post-receive hook 已配置（自动 migrate + collectstatic + restart）
#   - .env.production 已准备就绪

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REMOTE="server"
BRANCH="master"
SSH_HOST="root@81.70.243.63"
DEPLOY_DIR="/opt/zhangyuzhixue-v2"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

run() {
    if $DRY_RUN; then
        echo "  [DRY-RUN] $*"
    else
        echo "  ▶ $*"
        "$@"
    fi
}

echo "=========================================="
echo " 章鱼智学 v2 — 部署到 ECS"
echo "=========================================="
echo "  目标: $SSH_HOST:$DEPLOY_DIR"
echo "  分支: $REMOTE/$BRANCH"
echo "  模式: $($DRY_RUN && echo 'DRY-RUN' || echo '正式')"
echo ""

# 1. 检查 .env.production 存在
ENV_FILE="$PROJECT_DIR/.env.production"
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ 缺少 $ENV_FILE"
    echo "   请先创建生产环境 .env 文件"
    exit 1
fi
echo "✅ .env.production 存在"

# 2. 推送 .env.production 到 ECS
echo ""
echo "┌─ 推送 .env.production 到 ECS"
run scp "$ENV_FILE" "$SSH_HOST:$DEPLOY_DIR/server/.env"

# 3. 推送代码
echo ""
echo "┌─ 推送代码到 ECS"
if git remote get-url "$REMOTE" &>/dev/null; then
    echo "   remote '$REMOTE' 已配置"
else
    echo "❌ remote '$REMOTE' 未配置"
    echo "   请先添加: git remote add server ssh://git@81.70.243.63/opt/zhangyuzhixue-v2.git"
    exit 1
fi
run git push "$REMOTE" "$BRANCH" --force

# 4. SSH 执行验证
echo ""
echo "┌─ 验证部署"
if $DRY_RUN; then
    echo "  [DRY-RUN] ssh $SSH_HOST ..."
else
    ssh "$SSH_HOST" << 'REMOTE_CHECKS'
        set -euo pipefail
        cd /opt/zhangyuzhixue-v2/server
        source ../venv/bin/activate 2>/dev/null || true

        echo "  ▶ Django check --deploy"
        python manage.py check --deploy 2>&1 | head -5

        echo "  ▶ Django migrate"
        python manage.py migrate --noinput 2>&1 | tail -3

        echo "  ▶ API 健康检查"
        curl -s -o /dev/null -w "  HTTP %{http_code}\n" http://127.0.0.1:8000/admin/ || echo "  ⚠ gunicorn 可能未运行"

        echo ""
        echo "✅ 部署验证完成"
REMOTE_CHECKS
fi

echo ""
echo "=========================================="
echo " ✅ 部署完成"
echo "    验证步骤（SSH 到服务器）："
echo "      curl http://127.0.0.1:8000/admin/     → 200"
echo "      curl https://zhangyuzhixue.zhtec123.com/api/v1/auth/login/ → 200"
echo "      curl https://zhangyuzhixue.top/       → 200 (landing)"
echo "=========================================="
