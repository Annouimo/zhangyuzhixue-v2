# Phase 1.5 — Staging 环境部署

> 本文档是 [00-落地计划.md](../00-落地计划.md) 中 Phase 1.5 的细化执行方案。
> 状态：**已完成** | 执行日期：2026-07-10 | 最后更新：2026-07-10

---

## 总览

| 子步骤 | 内容 | 工时 | 状态 |
|--------|------|------|------|
| **0** | 服务器安装 Python 3.11 | ~5 分钟 | ✅ |
| **1** | 服务器创建 bare repo + post-receive hook | ~10 分钟 | ✅ |
| **1b** | 本地添加 server remote + `git push` | ~2 分钟 | ✅ |
| **2** | scp `.env` 到服务器并配置 | ~5 分钟 | ✅ |
| **3** | systemd gunicorn 服务 | ~10 分钟 | ✅ |
| **4** | nginx 配置（新增 Django 路由，保留维护页） | ~5 分钟 | ✅ |
| **5** | 验证部署（curl API） | ~5 分钟 | ✅ |
| **6** | 首次构建 assets/lectures.db | ~5 分钟 | ✅ |
| **7** | 创建 Dev 用户 + 全量验证 | ~10 分钟 | ✅ |
| | **合计** | **~1 小时** | ✅ |

### 前置条件

- [x] Phase 1（服务端全量）已完成，本地可运行
- [x] Cloudflare Tunnel 已配置运行，指向 localhost:8080
- [x] ECS 服务器 123.57.85.160 可 SSH 登录
- [x] 旧版 math_platform 项目已不存在（/opt/ 为空）

### 关键设计文档索引

| 文档 | 用途 |
|------|------|
| [`服务端架构.md`](../03-服务端/服务端架构.md) | 部署方案、nginx/gunicorn 配置 |
| [`API设计.md`](../03-服务端/API设计.md) | 所有端点路径，用于 curl 验证 |
| [`00-落地计划.md`](../00-落地计划.md) §Phase 1.5 | Staging 部署总览 |

---

## 一、目标

将 Phase 1 完成的 Django 服务端部署到 ECS，接入现有 Cloudflare Tunnel，搭建 `stage.zhangyuzhixue.top`（或复用主域名）staging 环境，供 Phase 2 Flutter 数据层开发时对接。

## 二、现状

### 2.1 服务器（ECS 123.57.85.160）

| 项目 | 值 |
|:-----|:----|
| OS | Ubuntu 22.04.5 LTS |
| Python | 3.10.12（系统默认） |
| nginx | 1.18.0 |
| cloudflared | ✅ 已运行（tunnel: `math-platform`） |
| 磁盘 | 40G / 已用 12G / 剩余 26G |
| 内存 | 1.6G / 可用 1.1G |
| CPU | 2 核 |

### 2.2 当前运行状态

- Cloudflare Tunnel 指向 `http://localhost:8080`（nginx loopback）
- nginx 当前在 8080 端口仅 serve 一个**维护页面**（`/var/www/maintenance/index.html`）
- 服务端旧版项目 `math_platform` 已不存在（`/opt/` 为空）
- **连接链：** `用户 → Cloudflare → tunnel → localhost:8080 → nginx → 维护页面`

### 2.3 新版需求

| 组件 | 说明 |
|:-----|:------|
| Python | 新版需要 Python 3.11（`requirements.txt` 锁定 3.11+ 版本） |
| gunicorn | 新版已加入 `requirements.txt`（gunicorn==26.0.0） |
| nginx | 需新增 `location /static/` 和 `location /` proxy_pass |
| cloudflared | 已有，指向 8080，nginx 需同时处理维护页 + Django |
| db.sqlite3 | 本地已有 798 题 + 全量数据，需迁移至服务器 |

---

## 三、执行步骤

### 步骤 0 — 前置准备（一次性）

```bash
# 0.1 安装 Python 3.11（Ubuntu 22.04 默认 3.10，需用 deadsnakes PPA）
apt update
apt install -y software-properties-common
add-apt-repository -y ppa:deadsnakes/ppa
apt install -y python3.11 python3.11-venv python3.11-dev
```

### 步骤 1 — 代码部署到服务器

**方案：git push-to-deploy（推荐）**

在服务器创建 bare repo + post-receive hook，本地 `git push server master` 自动部署。

```bash
# 服务器：
mkdir -p /opt/zhangyuzhixue-v2.git
cd /opt/zhangyuzhixue-v2.git
git init --bare
```

创建 hooks/post-receive：

```bash
# 服务器：/opt/zhangyuzhixue-v2.git/hooks/post-receive
#!/bin/bash
DEPLOY_DIR=/opt/zhangyuzhixue-v2
export GIT_WORK_TREE=$DEPLOY_DIR
export GIT_DIR=/opt/zhangyuzhixue-v2.git
git checkout -f

echo "=== Code checked out ==="
cd $DEPLOY_DIR

# 创建/激活 venv（首次）
if [ ! -d venv ]; then
    python3.11 -m venv venv
    echo "venv created"
fi
source venv/bin/activate
pip install -r server/requirements.txt -q \
    -i http://mirrors.cloud.aliyuncs.com/pypi/simple/ \
    --trusted-host mirrors.cloud.aliyuncs.com
echo "=== pip done ==="

# 复制 .env.staging（如果不存在）
if [ ! -f server/.env ]; then
    cp server/.env.example server/.env 2>/dev/null || true
    echo "⚠️ 需要手动配置 server/.env"
fi

cd server
# 迁移 + 静态文件
python manage.py migrate --noinput 2>&1 | tail -3
python manage.py collectstatic --noinput 2>&1 | tail -3
echo "=== migrate + collectstatic done ==="

# 重启 gunicorn
systemctl restart gunicorn-math-platform 2>/dev/null || true
echo "=== gunicorn restarted ==="

sleep 2
curl -s -o /dev/null -w "Status: %{http_code}\n" http://127.0.0.1:8000/
echo "=== Deploy complete ==="
```

```bash
chmod +x /opt/zhangyuzhixue-v2.git/hooks/post-receive
```

**本地添加 remote 并推送：**

```bash
git remote add server ssh://root@123.57.85.160/opt/zhangyuzhixue-v2.git
git push server master
```

**注意：** 首次推送后，需要手动配置 `.env` 和创建 systemd 服务，后续推送自动执行 hook。

### 步骤 2 — 配置环境变量

创建 `server/.env.staging` 模板（不提交到 git，首次部署时手动从本地复制或通过 scp）：

```bash
# 从本地 scp 到服务器
scp D:\Hermes\zhangyuzhixue_app_v2\server\.env root@123.57.85.160:/opt/zhangyuzhixue-v2/server/.env
```

**staging 环境需要的 key：**

| 变量 | 说明 | staging 值 |
|:-----|:-----|:-----------|
| `SECRET_KEY` | Django 密钥 | 生成新 key（非本地 dev key） |
| `DEBUG` | 调试模式 | `False` |
| `ALLOWED_HOSTS` | 允许的 Host | `localhost,127.0.0.1,123.57.85.160,zhangyuzhixue.top,stage.zhangyuzhixue.top` |
| `DB_NAME` | 数据库文件名 | `db.sqlite3` |
| `CORS_ALLOWED_ORIGINS` | 跨域来源 | `https://zhangyuzhixue.top,https://stage.zhangyuzhixue.top` |
| `SENTRY_DSN` | Sentry DSN | 从旧版 `.env` 复制 |
| `PDF_SECRET_KEY` | PDF 签名密钥 | 生成新 key |

### 步骤 3 — 创建 systemd 服务（gunicorn）

```bash
# 服务器：/etc/systemd/system/gunicorn-math-platform.service
[Unit]
Description=Zhangyuzhixue Django via Gunicorn
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/zhangyuzhixue-v2/server
ExecStart=/opt/zhangyuzhixue-v2/venv/bin/gunicorn \
    --workers 2 \
    --timeout 120 \
    --bind 127.0.0.1:8000 \
    math_platform.wsgi:application
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
systemctl daemon-reload
systemctl start gunicorn-math-platform
systemctl enable gunicorn-math-platform
```

**注意：** workers=2（2C2G 的最佳值，参考公式 2×CPU+1=5 但内存受限，压到 2）。
如需压测后调整，可改为 3。

### 步骤 4 — 更新 nginx 配置

**目标：** nginx 在 8080 端口（cloudflared 指向的目标）做路由分发：
- `/api/` → proxy_pass 到 gunicorn（127.0.0.1:8000）
- `/admin/` → proxy_pass 到 gunicorn
- `/pdf/` → proxy_pass 到 gunicorn
- `/static/` → nginx 直出静态文件
- 其他路径 → **维护页面**（普通用户打开域名看到升级提示，不暴露 Django 404）

```nginx
# 服务器：/etc/nginx/sites-available/zhangyuzhixue-staging
server {
    listen 127.0.0.1:8080;
    server_name _;

    # 静态文件（nginx 直接 serve，不走 gunicorn）
    location /static/ {
        alias /opt/zhangyuzhixue-v2/server/staticfiles/;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    # API 和管理后台 → Django
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 120s;
    }
    location /admin/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    location /pdf/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 其他路径 → 维护页面（用户友好，不暴露 API）
    location / {
        root /var/www/maintenance;
        index index.html;
        try_files $uri $uri/ =404;
    }
}
```

**启用新配置（保留原 maintenance 配置不变，两者并存）：**

```bash
ln -sf /etc/nginx/sites-available/zhangyuzhixue-staging /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
```

原有 `/etc/nginx/sites-enabled/maintenance` 仍然有效，但 nginx 按 `server_name` 匹配——两个 server 块都 `listen 127.0.0.1:8080` 且 `server_name _`，先加载的优先。所以只保留 zhangyuzhixue-staging 的 symlink，maintenance 的 symlink 删除或改名。

### 步骤 5 — 验证部署

```bash
# 5.1 gunicorn 是否在运行
systemctl status gunicorn-math-platform

# 5.2 本地 curl 测试
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://127.0.0.1:8000/api/v1/docs/
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://127.0.0.1:8080/api/v1/docs/

# 5.3 Django check --deploy
cd /opt/zhangyuzhixue-v2/server && python manage.py check --deploy

# 5.4 API 测试 — 认证端点
curl -s -X POST http://127.0.0.1:8000/api/v1/auth/login/ \
    -H "Content-Type: application/json" \
    -d '{"username":"student1","password":"test123","app_type":"student"}' | python3 -m json.tool

# 5.5 外部访问测试（通过 Cloudflare Tunnel）
curl -s -o /dev/null -w "HTTP %{http_code}\n" https://zhangyuzhixue.top/api/v1/docs/
```

### 步骤 6 — 首次构建运行

```bash
cd /opt/zhangyuzhixue-v2/server
source ../venv/bin/activate
python scripts/build_assets.py
python scripts/build_lectures.py

# 验证构建产物
sqlite3 media/db/qbank_v1.db.gz ".tables"
sqlite3 media/db/qbank_v1.db.gz "SELECT COUNT(*) FROM question"
```

### 步骤 7 — 创建 Dev 用户 + 验证 API 全通

```bash
cd /opt/zhangyuzhixue-v2/server
source ../venv/bin/activate
python scripts/create_dev_users.py

# 或者手动创建后运行 pytest（如果服务器能跑测试的话）
# pip install pytest pytest-django
# pytest accounts/tests/ courses/tests/ interactions/tests/ system/tests/ -v
```

### 步骤 8 — 维护页面快速切换方案

**不需要切换。** 维护页面一直开着，用户访问 `zhangyuzhixue.top/` 始终看到维护提示。

如果 Django 崩溃（gunicorn 挂了），`/api/` 返回 502，但 `/` 仍正常显示维护页面。

如果要完全回退到仅显示维护页面的状态：

```bash
systemctl stop gunicorn-math-platform
# nginx 对 /api/ 返回 502，对 / 仍正常显示维护页
```

---

## 四、注意事项

### 4.1 Python 版本差异

本地用 Python 3.11.15，服务器 Ubuntu 22.04 默认 3.10.12。虽然 Django 5.2 官方支持 3.10，但需确认全量依赖兼容。使用 `deadsnakes` PPA 装 3.11 是最稳妥方案。

### 4.2 SQLite 版本

服务器 `sqlite3 --version` 可能需要确认≥3.25（Django 5.2 窗口函数支持）。Ubuntu 22.04 默认 sqlite3 3.37+，大概率满足。

### 4.3 SQLite 在 nginx/gunicorn 下的并发

SQLite 不适合高并发写，但 staging 环境仅开发自用（1-2 人），完全够用。上线前如需要可切换 PostgreSQL，但不在 Phase 1.5 范围内。

### 4.4 CORS 与域名

- `CORS_ALLOWED_ORIGINS` 必须包含 Cloudflare 代理后的域名（`https://zhangyuzhixue.top`），否则 Flutter App 发 API 请求会被浏览器 CORS 拦截
- 如果使用 `stage.zhangyuzhixue.top` 域名，需先在 Cloudflare DNS 添加 A 记录

### 4.5 Memory/CPU

2C2G ECS，gunicorn 2 workers 是保守值。如果看到 OOM（gunicorn worker 被 kill），可改为 1 worker 或加 swap。
