# Phase 6 — 用户数据迁移 + 上线（1 天）

> 本文档是 [00-落地计划.md](../00-落地计划.md) 中 Phase 6 的细化执行方案。
> 状态：**待开始** | 最后更新：2026-07-11

---

## 总览

| 子步骤 | 内容 | 工时 | 状态 |
|:-------|:-----|:-----|:----:|
| **6.1** | 用户数据迁移（Old User → New User + Student） | 0.3 天 | ⬜ |
| **6.2** | 邀请码迁移 | 0.1 天 | ⬜ |
| **6.3** | 核对——用户数 + 随机抽 3 账号验证登录 | 0.1 天 | ⬜ |
| | **└ 教师 UAT 终签**：3 位教师登录真实账号确认可用 | (含在 6.3) | ⬜ |
| **6.4** | 正式部署到 ECS（域名/nginx/Cloudflare） | 0.2 天 | ⬜ |
| **6.5** | 数据库备份 crontab | 0.05 天 | ⬜ |
| **6.6** | 着陆页替换下载链接 | 0.05 天 | ⬜ |
| **6.7** | 观察 Sentry 24 小时 | 0.2 天 | ⬜ |
| | **合计** | **~1 天** | |

### 前置条件

- [ ] Phase 5 集成测试全部通过
- [ ] Staging 环境验证通过（所有 API 端点可用）
- [ ] 旧版 `D:\Hermes\math_platform\db.sqlite3` 中 auth_user 表可访问
- [ ] ECS 服务器 123.57.85.160 可 SSH 登录
- [ ] 3 位教师已准备好签收
- [ ] Sentinel DSN 已在服务端 `.env` 中配置（Phase 0 已完成）

### 关键设计文档索引

| 文档 | 用途 |
|:-----|:------|
| [`00-落地计划.md`](../00-落地计划.md) §Phase 6 | 顶层规划 |
| [`服务端架构.md`](../03-服务端/服务端架构.md) | 部署方案、nginx 配置 |
| [`学号生成算法.md`](../02-数据/学号生成算法.md) | LCG 参数、student_id 格式 |
| [`数据库结构设计.md`](../02-数据/数据库结构设计.md) | 新旧表结构对比 |
| [`更新机制.md`](../02-数据/更新机制.md) | 版本三层体系（App 发版参考） |
| [`Phase-1.5-Staging部署.md`](./Phase-1.5-Staging部署.md) | Staging 部署方案（参考，需改域名和端口） |
| [`Phase-1-服务端全量.md`](./Phase-1-服务端全量.md) §1.2 | 题库数据迁移方案（参考流程） |

### 核心设计决策

| 决策 | 说明 |
|:-----|:------|
| student_id 不迁移旧值 | 由 LCG 基于新数据库自增 ID 重新生成 |
| 做题数据不迁移 | 只迁移用户身份数据（User + Student/Teacher + InvitationCode） |
| 迁移脚本跑一次 | 不随 schema 迭代，上线前在 staging 试跑确认无误后，上线时跑一次正式 |
| 教师 UAT 终签放迁移后、上线前 | 避免迁移出问题后教师已签收但实际不可用 |

---

## 6.1 — 用户数据迁移（0.3 天）

### 前置探查

旧版 `D:\Hermes\math_platform\db.sqlite3` 中需要迁移的表：

| 旧版表 | 迁向 | 说明 |
|:-------|:-----|:-----|
| `auth_user` | 新版 `auth_user`（Django 内置） | 用户名/密码/邮箱/注册时间 原样迁移 |
| `accounts_student` | `accounts_student` | student_id 不迁移（LCG 自动生成） |
| `accounts_teacher` | `accounts_teacher` | 原样迁移 |
| `invitation_invitationcode` | `accounts_invitationcode` | 原样迁移 |

**用户名冲突风险：** 旧版表和新版 Dev 测试用户（teacher1/student1-3/admin）可能有重复。迁移方案：保持旧版用户 username 不变，Dev 用户已在旧版 student/teacher 账号之外通过 `create_dev_users.py` 创建。如果 Dev 用户的 username 在旧版中已存在，迁移脚本需跳过 Dev 用户或做重命名（概率很低，但脚本要有容错）。

### 涉及文件

```
server/scripts/migrate_users.py              # 新建：用户迁移主脚本
server/scripts/migrate_users_audit/          # 新建：审核文件目录（自动创建）
```

### 实现要点

参照 `migrate_questions.py` 的模式——独立脚本，直接连接新旧两个 SQLite 数据库，不走 Django ORM：

```
migrate_users.py
├── 1. 连接旧版 db.sqlite3
│   ├── PRAGMA table_info(auth_user)
│   ├── PRAGMA table_info(accounts_student)
│   ├── PRAGMA table_info(accounts_teacher)
│   └── PRAGMA table_info(invitation_invitationcode)
├── 2. 迁移 auth_user
│   ├── 按 id 升序遍历旧版用户（跳过已存在同 username 的 Dev 用户）
│   ├── 直接执行 INSERT INTO auth_user（保持 id 一致？或用新 ID）
│   └── 记录旧→新 user_id 映射
├── 3. 迁移 accounts_student
│   ├── 基于旧→新 user_id 映射
│   ├── student_id 留空 → 触发 Student.save() 的 LCG 自动生成
│   ├── class_group=null
│   └── 其他字段（school/gaokao_year/phone）原样迁移
├── 4. 迁移 accounts_teacher
│   └── 基于旧→新 user_id 映射，原样迁移
├── 5. 迁移 InvitationCode（6.2 合并至此）
│   └── 原样迁移，保持 code 不变
└── 6. 验证
    ├── 用户数：旧版 ↔ 新版
    ├── 学生数：旧版 ↔ 新版
    ├── 教师数：旧版 ↔ 新版
    ├── 邀请码数：旧版 ↔ 新版
    └── 随机抽 3 个学生 + 3 个邀请码逐字段对比
```

**关键点：**

| 问题 | 方案 |
|:-----|:------|
| ID 保持 | **保持旧 ID 不变**（旧版 auth_user.id 写入新版 auth_user.id），这样旧版 Student 表中的 user_id 外键直接可用，无需二次映射。前提是本地新版数据库中无冲突 ID |
| password 字段 | Django 的 password 是加密后的 hash，直接复制即可（`pbkdf2_sha256$...` 格式）。明文密码无法恢复 |
| student_id | 留空 → 利用 Student 模型的 `save()` 方法自动 LCG 生成 |
| date_joined | 保留旧版注册时间 |
| 密码算法兼容性 | Django 5.2 的 PBKDF2 算法与旧版一致，无需重新哈希 |

### 验证方式

```bash
python scripts/migrate_users.py
# 期望输出：
# ✅ auth_user: 旧版 N 条 → 新版 N 条
# ✅ accounts_student: 旧版 N 条 → 新版 N 条
# ✅ accounts_teacher: 旧版 N 条 → 新版 N 条
# ✅ invitation_invitationcode: 旧版 N 条 → 新版 N 条
# ✅ 随机抽 3 个用户：全部匹配
# ✅ 抽 3 个邀请码：全部匹配

# 验证登录（用迁移后的账号）
python manage.py shell -c "
from django.contrib.auth import authenticate
u = authenticate(username='xxxx', password='原始密码')
print('登录成功' if u else '登录失败')
"
```

### 注意事项

- **ID 冲突处理：** 新版数据库中已有 Dev 测试用户（admin/teacher1/student1-3）。迁移脚本需检查旧版用户 ID 是否与新版已有 ID 冲突。**方案：** 旧版 user 从 id=100 开始（避开 1-99 的 Dev 用户区间），student/teacher 也做相应偏移
- **事务：** 每条 INSERT 组在独立事务中，失败可回退单步
- **幂等：** 脚本开头检查新版 auth_user 表中是否有从旧版迁移的数据（例如标记列或行数超过 Dev 用户数），有则跳过
- **password 字段复制：** Django 的 password hash 包含算法标识，直接复制 `auth_user.password` 值即可
- 迁移完在 staging 环境试跑一次确认无误，再在上线时跑一次正式

---

## 6.2 — 邀请码迁移

已合并到 6.1 的步骤 5。不单独写脚本，与用户迁移同文件。

---

## 6.3 — 核对 + 教师 UAT 终签（0.1 天）

### 核对清单

| 检查项 | 怎么查 | 结果 |
|:-------|:-------|:----:|
| 用户数一致 | 旧版 `SELECT COUNT(*) FROM auth_user` vs 新版 | ⬜ |
| 学生数一致 | 旧版 `accounts_student` vs 新版 | ⬜ |
| 教师数一致 | 同上 | ⬜ |
| 邀请码数一致 | 旧版 `invitation_invitationcode` vs 新版 | ⬜ |
| 密码可用 | 抽 3 个账号用原始密码登录 | ⬜ |
| student_id 生成 | 抽 3 个学生确认学号格式与 `学号生成算法.md` 一致 | ⬜ |
| 非迁移数据不受影响 | Dev 用户（admin/teacher1/student1-3）仍可登录 | ⬜ |
| API 可用 | 迁移后 `/api/v1/auth/login/` 对新旧账号均可用 | ⬜ |

### 教师 UAT 终签

**时机：** 核对通过后、正式上线前。

**参与人：** 3 位教师（用自己的真实迁移后的账号）。

**流程（30 分钟）：**

```
1. 教师用真实账号登录（验证密码迁移成功）
2. 快速走主线（3 分钟/人）：
   登录 → 首页 → 做一道选择题 → 做一道解答题 → 查看讲义 → 检查作业列表
3. 确认上次 UAT（Phase 3.5）反馈已修复
4. 签字确认
```

**产出：** 3 位教师签字确认。

| 教师 | 账号 | 结论 | 签字 |
|:-----|:-----|:-----|:-----|
| 教师 A | 旧版迁移 | ✅ 可用 / ❌ 不可用 | _____ |
| 教师 B | 旧版迁移 | ✅ 可用 / ❌ 不可用 | _____ |
| 教师 C | 旧版迁移 | ✅ 可用 / ❌ 不可用 | _____ |

如果签字不通过：记录问题 → 修复 → 重新核对 → 重新签字。

---

## 6.4 — 正式部署到 ECS（0.2 天）

### 对比 Staging 部署的差异

| 项目 | Staging（Phase 1.5） | **正式（Phase 6.4）** |
|:-----|:--------------------|:---------------------|
| 域名 | `zhangyuzhixue.top`（同域名，维护页兜底） | `zhangyuzhixue.top`（去掉维护页兜底） |
| nginx 维护页 | `/` 显示维护页，`/api/` 走 Django | `/` 跳转下载页（静态 landing），`/api/` 走 Django |
| gunicorn workers | 2 | 2 或 3（看内存） |
| 数据库 | staging 新库（无旧版用户） | 迁移了旧版用户的正式库 |
| 环境变量 | `DEBUG=False` | 同（确认） |
| Sentry | 已配置 | 同 |
| SSL | Cloudflare Tunnel | 同 |

### 涉及文件

```
server/.env.production              # 新建：生产环境变量模板
scripts/deploy_prod.sh              # 新建：一键部署脚本（封装 git push）
```

### 执行步骤

```bash
# 0. 前提：数据库已迁移、核对通过、教师签收

# 1. 本地生成生产环境 .env 并 scp 到服务器
scp server/.env.production root@123.57.85.160:/opt/zhangyuzhixue-v2/server/.env

# 2. 推送代码（post-receive hook 自动 migrate + collectstatic + restart）
git push server master --force

# 3. SSH 到服务器，验证部署
ssh root@123.57.85.160
cd /opt/zhangyuzhixue-v2/server
source ../venv/bin/activate
python manage.py check --deploy    # 零问题
python manage.py migrate --noinput  # 确认迁移已应用

# 4. 更新 nginx 配置（去掉维护页兜底，改为 landing 静态目录）
```

### nginx 配置变更（正式版）

```nginx
server {
    listen 127.0.0.1:8080;
    server_name _;

    # 静态文件（nginx 直出）
    location /static/ {
        alias /opt/zhangyuzhixue-v2/server/staticfiles/;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    # API + Admin → Django
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
        # ... 同上
    }
    location /pdf/ {
        proxy_pass http://127.0.0.1:8000;
        # ... 同上
    }

    # 着陆页（替换维护页 — nginx 直出静态 HTML）
    location / {
        root /opt/zhangyuzhixue-v2/landing;
        index index.html;
        try_files $uri $uri/ =404;
    }
}
```

**注意：** 正式版 nginx 不再用 `/var/www/maintenance/index.html` 兜底，而是直接 serve `landing/` 目录。但需要保留 `/etc/nginx/sites-available/maintenance` 的快速切换能力（改一下 symlink 就能切回去）。

### 验证方式

```bash
# 服务器本地测试
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/admin/      # → 200
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/api/v1/docs/ # → 200

# 通过域名测试
curl -s -o /dev/null -w "%{http_code}" https://zhangyuzhixue.top/api/v1/auth/login/  # → 200（POST）
curl -s -o /dev/null -w "%{http_code}" https://zhangyuzhixue.top/                     # → 200（landing 页）
```

---

## 6.5 — 数据库备份 crontab（0.05 天）

### 涉及文件

```
（服务器端操作，无涉及文件）
```

### 实现要点

在 ECS 服务器上添加定时任务：

```bash
crontab -e
# 每日凌晨 4 点备份，保留 30 天
0 4 * * * cp /opt/zhangyuzhixue-v2/server/db.sqlite3 /opt/backup/db.$(date +\%Y\%m\%d).sqlite3 && find /opt/backup/ -name "db.*.sqlite3" -mtime +30 -delete
```

### 验证方式

```bash
crontab -l  # 确认任务存在
# 手动跑一次验证
sudo -u root cp /opt/zhangyuzhixue-v2/server/db.sqlite3 /opt/backup/db.$(date +%Y%m%d).sqlite3.test
ls -la /opt/backup/
rm /opt/backup/db.*.test
```

---

## 6.6 — 着陆页替换下载链接（0.05 天）

### 涉及文件

```
landing/index.html       # 修改：替换 # 占位链接为真实下载 URL
```

### 实现要点

当前 `landing/index.html` 中三个下载按钮的 `href` 都是 `#`，需替换为真实的 APK / TestFlight / Windows 安装包 URL。

**具体操作（在 Phase 6.6 时才做，需先准备好下载产物）：**

```diff
- <a href="#" class="btn">📱 Android 版</a>
+ <a href="https://zhangyuzhixue.top/download/app-v2.0.0.apk" class="btn">📱 Android 版</a>

- <a href="#" class="btn">🍎 iOS 版</a>
+ <a href="https://testflight.apple.com/join/xxxxx" class="btn">🍎 iOS 版</a>

- <a href="#" class="btn">💻 Windows 版</a>
+ <a href="https://zhangyuzhixue.top/download/app-v2.0.0-windows.zip" class="btn">💻 Windows 版</a>
```

**注意：** 下载 URL 的域名 `zhangyuzhixue.top` 使用正式域名，文件放在 nginx 的 `location /download/` 目录下（需在 nginx 配置中补充一行 `location /download/` 直出）。

### 验证方式

```bash
# 本地确认链接不再是 #
grep -c 'href="#"' landing/index.html   # 期望输出：0
# 浏览器打开 landing 页，点每个下载按钮确认可下载
```

---

## 6.7 — 观察 Sentry 24 小时（0.2 天）

### 实现要点

上线后不立即通知旧版用户迁移。观察 Sentry 24 小时：

| 观察项 | 阈值 | 行动 |
|:-------|:-----|:-----|
| 认证错误（401/400 异常增长） | 超过旧版线 50% | 检查登录/注册端点 |
| 500 错误 | 任何 500 | 立即检查服务器日志 |
| API 超时 | > 5% 请求耗时 > 5s | gunicorn worker 数或 nginx 配置 |
| PDF 签名失败 | 连续 3 次 | 检查 PDF_SECRET_KEY |

**24 小时后确认无异常增长 → 通知旧版用户迁移。**

### 通知话术（参考）

> 「章鱼智学新版 App 已上线！新版采用全新架构，解题更流畅、推荐更精准。请通过 [下载链接] 安装新版，使用原有账号登录即可。旧版 App 保留 30 天后下线，建议尽快迁移。」

---

## 紧急回退方案

万一上线后发现严重问题（S0/S1），按以下顺序回退：

| 优先级 | 操作 | 影响 |
|:-------|:-----|:-----|
| 1 | nginx 切回维护页面（`rm staging symlink; ln -s maintenance`） | 用户看到维护页，API 不可用 |
| 2 | systemctl stop gunicorn | 完全下线 API |
| 3 | 回退 git 版本 + 恢复旧版 db.sqlite3 备份 | 回退到上线前状态 |

Sentry 在观测期发现异常时，先切维护页面保护现场，再排查问题。

---

## 操作清单（上线当天）

```text
□ 08:00  确认数据库备份
□ 08:05  在 staging 试跑 migrate_users.py（验证数据正确）
□ 08:15  staging 核对通过
□ 08:20  教师终签
□ 08:30  正式迁移（migrate_users.py）
□ 08:35  git push server master（部署到 ECS）
□ 08:40  验证 API + 登录
□ 08:45  更新 nginx 配置
□ 08:50  更新着陆页下载链接
□ 08:55  git push 到正式分支（Gitee master）
□ 09:00  crontab 备份就位
□ 09:00–次日 09:00  Sentry 观测期
□ 次日 09:00  确认无异常 → 通知旧版用户迁移
```

---

## 验收标准

1. 迁移脚本可运行、幂等、输出审核文件
2. 迁移后用户数核对一致、随机 3 账号可登录
3. 3 位教师签字确认可上线
4. 正式域名 API 和 landing 页均可访问
5. crontab 数据库备份就位
6. 着陆页下载链接非 # 占位
7. Sentry 观测 24 小时无异常增长
