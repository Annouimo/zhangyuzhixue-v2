#!/bin/bash
# 章鱼智学 v2 — 一键部署脚本（Phase 6.4）
#
# 用法：
#   ./scripts/deploy_prod.sh                    # 默认部署到正式环境
#   ./scripts/deploy_prod.sh --dry-run          # 只打印要执行的命令，但不执行
#
# 前提：
#   - 本地 git 已配置 server remote（指向 ECS bare repo）
#   - 服务器 post-receive hook 已配置（自动备份、migrate、restart）
#   - 生产 .env 只保存在服务器，不从本地覆盖

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$PROJECT_DIR/.." && pwd)"
REMOTE="server"
BRANCH="master"
SSH_HOST="root@82.157.115.219"
DEPLOY_DIR="/opt/zhangyuzhixue-v2"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa}"
SSH=(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST")

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

cd "$REPO_DIR"
if [[ "$(git branch --show-current)" != "$BRANCH" ]]; then
    echo "❌ 生产部署必须从 $BRANCH 分支执行"
    exit 1
fi
if [[ -n "$(git status --porcelain -- server)" ]]; then
    echo "❌ server/ 存在未提交改动，拒绝部署"
    git status --short -- server
    exit 1
fi
RELEASE_COMMIT="$(git rev-parse HEAD)"
REMOTE_REF="refs/heads/$BRANCH"
echo "  Commit: $RELEASE_COMMIT"

# 1. 部署前检查（不读取密钥值）
echo ""
echo "┌─ 部署前检查"
if $DRY_RUN; then
    echo "  [DRY-RUN] 检查远程 .env、服务和 Git hook"
else
    "${SSH[@]}" "test -f '$DEPLOY_DIR/server/.env' && \
        test -x '$DEPLOY_DIR.git/hooks/pre-receive' && \
        test -x '$DEPLOY_DIR.git/hooks/post-receive' && \
        systemctl is-active --quiet zhangyuzhixue-web"
    echo "✅ 远程环境、部署 hooks 和服务正常"
fi

# 2. 推送代码
echo ""
echo "┌─ 推送代码到 ECS"
if git remote get-url "$REMOTE" &>/dev/null; then
    echo "   remote '$REMOTE' 已配置"
else
    echo "❌ remote '$REMOTE' 未配置"
    echo "   请先添加: git remote add server ssh://root@82.157.115.219/opt/zhangyuzhixue-v2.git"
    exit 1
fi
if $DRY_RUN; then
    echo "  [DRY-RUN] git push $REMOTE $RELEASE_COMMIT:$REMOTE_REF"
else
    remote_commit="$(git ls-remote --exit-code "$REMOTE" "$REMOTE_REF" \
        | awk '{print $1}')"
    if [[ -z "$remote_commit" ]] || \
       ! git merge-base --is-ancestor "$remote_commit" "$RELEASE_COMMIT"; then
        echo "❌ 生产 ref 不是目标 commit 的祖先，拒绝发布"
        echo "   production: ${remote_commit:-missing}"
        echo "   release:    $RELEASE_COMMIT"
        exit 1
    fi
    GIT_SSH_COMMAND="ssh -o BatchMode=yes -i $SSH_KEY" \
        git push "$REMOTE" "$RELEASE_COMMIT:$REMOTE_REF"

    deployed_commit="$(git ls-remote --exit-code "$REMOTE" "$REMOTE_REF" \
        | awk '{print $1}')"
    if [[ "$deployed_commit" != "$RELEASE_COMMIT" ]]; then
        echo "❌ 生产 ref 未停留在目标 commit，发布可能已回滚"
        echo "   expected: $RELEASE_COMMIT"
        echo "   actual:   $deployed_commit"
        exit 1
    fi
fi

# 3. SSH 执行验证
echo ""
echo "┌─ 验证部署"
if $DRY_RUN; then
    echo "  [DRY-RUN] ssh $SSH_HOST ..."
else
    "${SSH[@]}" << 'REMOTE_CHECKS'
        set -euo pipefail
        cd /opt/zhangyuzhixue-v2/server
        source ../venv/bin/activate

        echo "  ▶ Django check --deploy"
        python manage.py check --deploy 2>&1 | head -5

        echo "  ▶ 迁移状态"
        python manage.py showmigrations accounts | tail -8

        echo "  ▶ API 健康检查"
        curl --fail -s -o /dev/null \
            http://127.0.0.1:8001/admin/ || true
        systemctl is-active --quiet zhangyuzhixue-web

        echo "  ▶ Nginx 配置"
        nginx -t

        echo "  ▶ 数据库完整性"
        python - <<'PY'
import sqlite3

connection = sqlite3.connect("file:db.sqlite3?mode=ro", uri=True)
integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
foreign_keys = connection.execute("PRAGMA foreign_key_check").fetchall()
connection.close()
if integrity != "ok" or foreign_keys:
    raise SystemExit(
        f"Database validation failed: integrity={integrity}, "
        f"foreign_key_violations={len(foreign_keys)}"
    )
print("Database validation passed.")
PY

        echo ""
        echo "✅ 部署验证完成"
REMOTE_CHECKS
    python "$REPO_DIR/scripts/smoke_production.py"
fi

echo ""
echo "=========================================="
echo " ✅ 部署完成"
echo "    验证步骤（SSH 到服务器）："
echo "      curl http://127.0.0.1:8001/admin/     → 302"
echo "      curl https://zhangyuzhixue.zhtec123.com/api/v1/auth/login/ → 405 (GET)"
echo "      curl https://zhangyuzhixue.top/       → 200 (landing)"
echo "=========================================="
