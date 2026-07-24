# 章鱼智学 Docker 迁移至 43.137.3.138 实施计划

> **状态：** 待批准
> **目标：** 将章鱼智学后端（Django + SQLite）和前端着陆页以 Docker 容器方式部署到新服务器 43.137.3.138，与现有服务（室风项目）完全隔离，互不影响。

---

## 一、架构总览

```
用户 → DNS (zhangyuzhixue.zhtec123.com / zhangyuzhixue.top)
         ↓
      43.137.3.138:443 (host nginx)
         ↓
  server block: zhangyuzhixue.zhtec123.com
         ↓
  proxy_pass http://127.0.0.1:8001  →  Docker 容器: gunicorn (端口 8001)
                          ↓
                    Django (SQLite, 静态文件)  ←  volume: /data/zhangyuzhixue/
```

### 关键隔离措施

| 层面 | 隔离方式 |
|------|---------|
| 进程 | 独立 Docker 容器 |
| 网络 | `--network bridge`，仅暴露 8001 给宿主机 |
| 磁盘 | 全部在 `/data/zhangyuzhixue/` 下，不动现有目录 |
| 资源 | `--memory=512m --cpus=1` 上限 |
| nginx | 新增 server block，互相独立 |

---

## 二、前置条件（手动确认）

- [ ] DNS：`zhangyuzhixue.zhtec123.com` 指向 `43.137.3.138`（或确认继续用 `zhangyuzhixue.top`）
- [ ] 服务器 43.137.3.138 上 Docker 已安装（已有容器证明 OK）
- [ ] SSH 密钥已配置（已验证 OK）
- [ ] 现有数据库文件：从旧服务器或本机备份中导出 `server/db.sqlite3`
- [ ] `.env.production` 文件（含 SECRET_KEY 等敏感配置）

---

## 三、步骤清单

### Step 1：服务器上创建目录结构

```bash
ssh root@43.137.3.138
mkdir -p /data/zhangyuzhixue/{data,static,media,landing,backups}
```

**不动任何现有目录**（`/data/house/`, `/data/zhtec123.com/`, `/data/mysql/` 等一概不碰）。

---

### Step 2：推送代码到服务器

方式 A：从 Gitee 拉取（推荐，与当前工作流一致）

```bash
cd /data/zhangyuzhixue
git clone https://gitee.com/annouimo/zhangyuzhixue-v2.git code
```

方式 B：从本地 scp server/ + landing/ 目录（如果只想传部分文件）

之后创建 `.env`：

```bash
cd /data/zhangyuzhixue/code/server
cp .env.production .env
# 编辑 .env 中的 SECRET_KEY、ALLOWED_HOSTS、CSRF_TRUSTED_ORIGINS
```

---

### Step 3：创建 Dockerfile

**路径：** `/data/zhangyuzhixue/Dockerfile`

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# 系统依赖（SQLite、Pillow 等需要）
RUN apt-get update && apt-get install -y --no-install-recommends \
    libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*

# Python 依赖
COPY code/server/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# 代码
COPY code/server/ .

# 环境变量（由 .env 或 docker-compose 传入）
ENV PYTHONUNBUFFERED=1
ENV DJANGO_SETTINGS_MODULE=math_platform.settings

# 暴露 gunicorn 端口
EXPOSE 8001

# 启动
CMD ["gunicorn", "math_platform.wsgi:application", \
     "--bind", "0.0.0.0:8001", \
     "--workers", "2", \
     "--timeout", "120", \
     "--access-logfile", "-", \
     "--error-logfile", "-"]
```

---

### Step 4：创建 docker-compose.yml

**路径：** `/data/zhangyuzhixue/docker-compose.yml`

```yaml
version: '3.8'

services:
  web:
    build: .
    container_name: zhangyuzhixue-web
    restart: unless-stopped
    ports:
      - "127.0.0.1:8001:8001"
    volumes:
      - ./data:/app/data          # SQLite 数据库持久化
      - ./static:/app/staticfiles  # collectstatic 产物
      - ./media:/app/media         # 用户上传/用户DB文件
    env_file:
      - ./code/server/.env
    environment:
      - DB_NAME=/app/data/db.sqlite3
      - STATIC_ROOT=/app/staticfiles
      - MEDIA_ROOT=/app/media
    mem_limit: 512m
    cpus: 1
    networks:
      - default
```

---

### Step 5：配置 host nginx

**路径：** `/etc/nginx/conf.d/zhangyuzhixue.conf`（新文件，不影响现有 8 个 conf）

```nginx
# 静态文件（着陆页）
server {
    listen 443 ssl;
    server_name zhangyuzhixue.zhtec123.com;

    ssl_certificate /etc/letsencrypt/live/zhtec123.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/zhtec123.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # 着陆页静态文件
    location / {
        root /data/zhangyuzhixue/landing;
        try_files $uri $uri/ /index.html;
    }

    # API 代理到 Docker 容器
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # admin 后台
    location /admin/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Django 静态文件（由 whitenoise 处理，或通过 nginx 直出）
    location /static/ {
        alias /data/zhangyuzhixue/static/;
    }

    location /media/ {
        alias /data/zhangyuzhixue/media/;
    }
}

# HTTP → HTTPS 跳转
server {
    listen 80;
    server_name zhangyuzhixue.zhtec123.com;
    return 301 https://$host$request_uri;
}
```

**验证步骤：**

```bash
# 先测试配置
nginx -t
# 如果返回 "syntax is ok"，再 reload
nginx -s reload
# 如果配置有错，nginx -t 会报错，reload 不会被接受，现有服务不受影响
```

---

### Step 6：迁移数据库

```bash
# 从本地 scp 数据库到服务器
scp server/db.sqlite3 root@43.137.3.138:/data/zhangyuzhixue/data/

# 或从旧服务器 scp
ssh root@43.137.3.138 "scp root@81.70.243.63:/opt/zhangyuzhixue-v2/server/db.sqlite3 /data/zhangyuzhixue/data/"
```

---

### Step 7：构建并启动

```bash
cd /data/zhangyuzhixue
docker compose build --no-cache
docker compose up -d

# 验证
docker compose ps
docker compose logs --tail=20

# Django migrate（首次）
docker compose exec web python manage.py migrate --noinput

# collectstatic
docker compose exec web python manage.py collectstatic --noinput

# 创建超级用户（可选）
docker compose exec web python manage.py createsuperuser
```

---

### Step 8：验证上线

```bash
# 内部验证
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://127.0.0.1:8001/api/

# 外部验证（DNS 已生效后）
curl -s -o /dev/null -w "HTTP %{http_code}\n" https://zhangyuzhixue.zhtec123.com/
curl -s -o /dev/null -w "HTTP %{http_code}\n" https://zhangyuzhixue.zhtec123.com/api/
curl -s -o /dev/null -w "HTTP %{http_code}\n" https://zhangyuzhixue.zhtec123.com/privacy.html
```

---

### Step 9：客户端更新

如果域名不变（仍用 `zhangyuzhixue.zhtec123.com`），客户端不需要改代码，只靠 DNS 切换。如果换域名，需要修改：

- `flutter_app/lib/pages/profile/about_page.dart` — URL 中的域名
- `teacher_app/lib/pages/settings/settings_page.dart` — URL 中的域名
- 各端 `server_url` 默认值

---

## 四、安全注意事项

| 事项 | 说明 |
|------|------|
| **.env 文件** | 含 SECRET_KEY、PDF_SECRET_KEY 等敏感信息，不要提交到 git |
| **数据库权限** | SQLite 文件应仅容器内 www-data 用户可读写 |
| **容器资源上限** | 设 `mem_limit: 512m`，防止内存泄漏影响其他服务 |
| **日志** | nginx access log 可能包含用户 IP，注意合规 |
| **备份策略** | `/data/zhangyuzhixue/data/db.sqlite3` 定期备份到 `/data/zhangyuzhixue/backups/` |

---

## 五、回滚方案

如果出现问题，不影响现有服务：

```bash
# 停止+删除容器
cd /data/zhangyuzhixue && docker compose down

# 删除新增的 nginx 配置
rm /etc/nginx/conf.d/zhangyuzhixue.conf && nginx -s reload

# DNS 改回旧服务器 IP
```

所有现有容器、数据、站点完全不受影响。

---

## 六、待确认问题

1. **域名：** 用 `zhangyuzhixue.zhtec123.com` 还是 `zhangyuzhixue.top`？影响 nginx server_name 和 SSL 证书
2. **数据库：** 旧服务器上的 SQLite 能否获取到？是否需要我从本地备份中导出一份？
3. **SSL 证书：** `zhtec123.com` 的 Let's Encrypt 证书是否覆盖子域名 `zhangyuzhixue.zhtec123.com`？需要确认通配符 `*.zhtec123.com` 还是单独申请
4. **着陆页位置：** landing/ 目录是放到容器里（让 Django 或 nginx 直出），还是单独放宿主机由 nginx 直接 serve？
5. **教师端 App 部署：** 教师端（`teacher_app/`）是纯 Flutter 客户端，不需要服务器运行，但 Android/iOS 构建需要在你 Mac 上完成
