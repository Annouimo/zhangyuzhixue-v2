# Phase 0 — 双项目脚手架 + CI

> 本文档是 [00-落地计划.md](../00-落地计划.md) 中 Phase 0 的细化执行方案。
> 状态：**已完成** | 最后更新：2026-07-10

---

## 总览

| 子步骤 | 内容 | 工时 | 状态 |
|--------|------|------|------|
| **0.1** | 安装缺失依赖 | ~0.1 天 | ✅ |
| **0.2** | Django 脚手架（settings/urls/5 Apps/env/flake8） | ~0.4 天 | ✅ |
| **0.3** | Flutter 脚手架（`flutter_app/` + pubspec + Riverpod） | ~0.3 天 | ✅ |
| **0.4** | 着陆页（从 docs/07-工作流/landing 复制 + 补充隐私/协议） | ~0.1 天 | ✅ |
| **0.5** | GitHub Actions CI（Gitee 镜像到 GitHub） | ~0.1 天 | ✅ |
| **合计** | | **~1 天** | ✅ 已完成 |

### 前置条件

- [x] Git 环境就绪，本地 SSH key 已配置
- [x] Gitee 仓库已创建
- [x] GitHub 账号已登录
- [x] 已读取 `docs/07-工作流/开发工作流程.md`

### 关键设计文档索引

| 文档 | 用途 |
|------|------|
| [`开发工作流程.md`](../07-工作流/开发工作流程.md) | 项目结构与工作流 |

---

## 0.1 — 依赖安装

```bash
pip install djangorestframework djangorestframework-simplejwt
pip install django-cors-headers python-decouple flake8
pip install drf-spectacular django-auditlog
```

### 验证方式

```bash
pip list | findstr <package-name>
```

### 注意事项

- 如果在中国大陆网络环境，pip install 可能超时，可添加 `-i https://mirrors.aliyun.com/pypi/simple/` 镜像源

---

## 0.2 — Django 脚手架

### 实现要点

1. `django-admin startproject math_platform server/`
2. 创建 5 个 App（`accounts/qbank/courses/interactions/system`）
3. **settings.py 配置：**
   - `INSTALLED_APPS`：5 App + `rest_framework` + `corsheaders` + `whitenoise` + `drf_spectacular` + `auditlog`
   - SQLite WAL：`connection_created` signal 执行 `PRAGMA journal_mode=WAL;`
   - JWT：`SIMPLE_JWT`（ACCESS_TOKEN_LIFETIME=24h，REFRESH_TOKEN_LIFETIME=30d）
   - `REST_FRAMEWORK`：统一响应格式、默认分页、JWTAuthentication
   - CORS：`CORS_ALLOWED_ORIGINS` 从环境变量读取
   - 环境变量分离：`python-decouple` 读 `SECRET_KEY`/`DEBUG`/`ALLOWED_HOSTS`
   - WhiteNoise：压缩静态文件
   - sentry-sdk：DSN 从环境变量读取，为空时不初始化
4. **urls.py 挂载：** `/api/v1/` 前缀 + drf-spectacular schema 端点
5. **创建 .env**：SECRET_KEY、DEBUG=True、DB 路径
6. **requirements.txt**：版本锁定
7. **flake8 配置**：`max-line-length=100`
8. 创建 `math_platform/exceptions.py`（统一 JSON 响应格式）

### 验证方式

```bash
python manage.py check               # 零问题
python manage.py migrate              # 34 个迁移全部 OK
flake8                                # 零问题
```

### 注意事项

- SQLite 不支持 `ALTER TABLE ... RENAME COLUMN`，models.py 必须一次写准
- `SECRET_KEY` 先用本地生成的 key，staging 部署时需生成新 key

---

## 0.3 — Flutter 脚手架

### 实现要点

1. `flutter create flutter_app`（项目根下生成）
2. **pubspec.yaml 添加依赖：**

```yaml
dependencies:
  drift: ^2.20.0
  sqlite3_flutter_libs: ^0.5.0
  dio: ^5.7.0
  dio_smart_retry: ^7.0.0
  flutter_markdown: ^0.7.0
  url_launcher: ^6.3.0
  cached_network_image: ^3.4.0
  shared_preferences: ^2.3.0
  flutter_riverpod: ^2.6.0
  connectivity_plus: ^6.1.0
```

3. 删除默认计数器代码，保留干净入口 `ZhangyuzhixueApp`
4. 添加 `build.yaml`（sqlite3 使用系统库，解决 GitHub 下载超时问题）

### 验证方式

```bash
flutter pub get          # 78 依赖解析成功
dart analyze             # No issues found!
flutter test             # All tests passed!
```

### 注意事项

- `build.yaml` 需配置 `sqlite: {version: 3.35, modules: {json1: true}}` 确保 JSON 函数可用
- GitHub Releases 下载超时（国内网络）时，在 `build.yaml` 中设置 `source: system` 使用系统 sqlite3 库

---

## 0.4 — 着陆页

### 实现要点

从 `docs/07-工作流/landing/` 复制到项目根目录 `landing/`，nginx 直出，不走 Django。

| 文件 | 说明 |
|------|------|
| `index.html` | App 下载按钮 + 微信二维码 + 产品简介（已有设计） |
| `privacy.html` | 隐私政策（占位内容） |
| `terms.html` | 用户协议（占位内容） |
| `images/wechat-qr.jpg` | 微信二维码图片 |

### 部署说明

`landing/` 在开发阶段仅作为源码维护，**不上传到服务器**。部署时由脚本复制到 nginx（Phase 6.7）。

### 验证方式

- `landing/index.html` 正常显示
- 三个下载按钮存在（# 占位链接）
- 微信二维码图片显示
- 隐私政策和用户协议页面可跳转

### 注意事项

- `landing/` 在开发阶段仅源码维护，不部署到服务器，由 Phase 6.7 部署脚本统一处理
- 下载链接先用 `#` 占位，正式版本发布后替换

---

## 0.5 — GitHub Actions CI

### 实现要点

**方案说明**

| 组件 | 方案 |
|------|------|
| 主仓库 | Gitee（`gitee.com/annouimo/zhangyuzhixue-v2`） |
| CI 引擎 | GitHub Actions（Gitee 自动镜像到 GitHub 仓库） |
| CI 配置文件 | `.github/workflows/ci.yml` |

> 最初计划使用 Gitee Go，但 Gitee Go 新版需要自建主机组（Agent 部署到 ECS），考虑到 ECS 资源有限，改为以上方案。

### 流水线内容

```yaml
并行执行：
├─ Flutter (ubuntu-latest):
│   ├─ actions/checkout@v4
│   ├─ subosito/flutter-action@v2 (Flutter 3.44)
│   ├─ dart analyze
│   └─ flutter test
└─ Django (ubuntu-latest):
    ├─ actions/checkout@v4
    ├─ actions/setup-python@v5 (Python 3.11)
    ├─ pip install -r server/requirements.txt
    ├─ flake8 --config server/.flake8
    ├─ python manage.py check --deploy
    └─ python manage.py makemigrations --check
```

### 前置条件

- [x] 用户创建空 GitHub 仓库（同名 `zhangyuzhixue-v2`）
- [x] 用户在 Gitee 仓库设置中配置自动同步到 GitHub
- [x] 首次 push 触发 CI，确认两条流水线均通过

### 验证方式

- GitHub Actions 页面两流水线（Flutter + Django）全绿
- `python manage.py check --deploy` 通过
- `dart analyze` No issues found

### 注意事项

- Gitee→GitHub 镜像同步可能有 1-5 分钟延迟，push 后稍等再检查 CI
- CI 中 Flutter 使用 `subosito/flutter-action@v2`，需指定 Flutter 版本与本地一致（3.44+）
- `--deploy` 检查在本地 dev 环境也可能有 warning，staging 环境需零问题

---

## 项目结构（落地后）

```
zhangyuzhixue_app_v2/
├── .github/workflows/ci.yml       # GitHub Actions CI
├── docs/                           # 设计文档
├── landing/                        # 着陆页静态 HTML
├── scripts/                        # 工具脚本
├── server/                         # Django 后端
│   ├── accounts/                   # 认证与用户
│   ├── courses/                    # 课程/讲义/作业
│   ├── interactions/               # 学习交互
│   ├── math_platform/              # Django 配置
│   ├── qbank/                      # 题库
│   ├── system/                     # 系统管理
│   ├── manage.py
│   ├── requirements.txt
│   └── .env
└── flutter_app/                    # Flutter 客户端
```
