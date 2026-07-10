# Phase 0 — 双项目脚手架 + CI

> 本文档是 00-落地计划.md 中 Phase 0 的细化执行方案。
> 状态：**已完成** | 执行日期：2026-07-10 | 最后更新：2026-07-10

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

---

## 0.1 — 依赖安装

```bash
pip install djangorestframework djangorestframework-simplejwt
pip install django-cors-headers python-decouple flake8
pip install drf-spectacular django-auditlog
```

### 执行结果

| 包名 | 版本 |
|------|------|
| djangorestframework | 3.17.1 |
| djangorestframework-simplejwt | 5.5.1 |
| django-cors-headers | 4.9.0 |
| python-decouple | 3.8 |
| flake8 | 7.3.0 |
| drf-spectacular | 0.30.0 |
| django-auditlog | 3.4.1 |

**Django 5.2.15 → 5.2.16** 和 **sentry-sdk 2.63.0 → 2.64.0** 也一并更新。

---

## 0.2 — Django 脚手架

### 步骤

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

### 执行结果

- [x] `python manage.py check` — **零问题**
- [x] `python manage.py migrate` — **34 个迁移全部 OK**
- [x] flake8 — **零问题**
- [x] sentry-sdk 静默不启动

**提交：** `eb06ebe`（后合并至 `9cee0db`、`ca44fe4`）

---

## 0.3 — Flutter 脚手架

### 步骤

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

### 执行结果

- [x] `flutter pub get` — **78 依赖解析成功**
- [x] `dart analyze` — **No issues found!**
- [x] `flutter test` — **All tests passed!**

**提交：** `0fa9587`

---

## 0.4 — 着陆页

从 `docs/07-工作流/landing/` 复制到项目根目录 `landing/`，nginx 直出，不走 Django。

| 文件 | 说明 |
|------|------|
| `index.html` | App 下载按钮 + 微信二维码 + 产品简介（已有设计） |
| `privacy.html` | 隐私政策（占位内容） |
| `terms.html` | 用户协议（占位内容） |
| `images/wechat-qr.jpg` | 微信二维码图片 |

### 部署说明

`landing/` 在开发阶段仅作为源码维护，**不上传到服务器**。部署时由脚本复制到 nginx（Phase 6.7）。

### 执行结果

- [x] `landing/index.html` 正常显示
- [x] 三个下载按钮存在（# 占位链接）
- [x] 微信二维码图片显示
- [x] 隐私政策和用户协议页面可跳转

**提交：** `333f440`

---

## 0.5 — GitHub Actions CI

### 变更说明

最初计划使用 Gitee Go，但 Gitee Go 新版需要自建主机组（Agent 部署到 ECS），考虑到 ECS 资源有限，改为以下方案：

| 组件 | 方案 |
|------|------|
| 主仓库 | Gitee（`gitee.com/annouimo/zhangyuzhixue-v2`） |
| CI 引擎 | GitHub Actions |
| 同步方式 | Gitee 自动镜像到 GitHub 仓库 |
| CI 配置文件 | `.github/workflows/ci.yml` |

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

### 完成情况

- [x] 用户创建空 GitHub 仓库（同名 `zhangyuzhixue-v2`）
- [x] 用户在 Gitee 仓库设置中配置自动同步到 GitHub
- [x] 首次 push 触发 CI，验证两条流水线均通过 ✅

> CI 调试过程经历了 7 轮修复（Node.js 兼容性→Flutter SDK 下载路径→`subosito/flutter-action` 缓存配置等），最终流水线全绿通过。

**提交：** `ca44fe4`

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

## 产出

- ✅ Django 项目可编译、迁移通过、flake8 零问题
- ✅ Flutter 项目 dart analyze 零问题、测试通过
- ✅ 着陆页静态 HTML 就位
- ✅ GitHub Actions CI 配置就位，流水线全绿 ✅
