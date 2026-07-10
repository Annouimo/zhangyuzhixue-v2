# Phase 0 — 双项目脚手架 + CI

> 本文档是 00-落地计划.md 中 Phase 0 的细化执行方案。
> 更新日期：2026-07-10 | 等待负责人批准后执行。

---

## 总览

| 子步骤 | 内容 | 工时 |
|--------|------|------|
| **0.1** | 安装缺失依赖 + 准备项目目录 | ~0.1 天 |
| **0.2** | Django 脚手架（settings/urls/5 Apps/env/flake8） | ~0.4 天 |
| **0.3** | Flutter 脚手架（`flutter_app/` + pubspec + Riverpod） | ~0.3 天 |
| **0.4** | 着陆页占位 HTML | ~0.1 天 |
| **0.5** | Gitee Go CI 配置 + git commit | ~0.1 天 |
| **合计** | | **~1 天** |

---

## 0.1 — 依赖安装 + 目录准备

```bash
pip install djangorestframework djangorestframework-simplejwt
pip install django-cors-headers python-decouple flake8
pip install drf-spectacular django-auditlog
```

**项目结构目标（落地后）：**
```
zhangyuzhixue_app_v2/
├── docs/                         # 已有
├── scripts/                      # 已有
├── server/                       # 新建 ← Django 项目
│   ├── manage.py
│   ├── requirements.txt
│   ├── .env
│   ├── math_platform/            # Django 配置 settings/urls/wsgi
│   ├── accounts/                 # 认证与用户
│   ├── qbank/                    # 题库
│   ├── courses/                  # 课程/讲义/作业
│   ├── interactions/             # 学习交互
│   ├── system/                   # 系统管理
│   └── scripts/                  # 构建脚本
├── flutter_app/                  # 新建 ← Flutter 项目
├── landing/                      # 新建 ← 着陆页静态 HTML
└── .gitee/workflows/ci.yml       # Gitee Go CI
```

---

## 0.2 — Django 脚手架

### 步骤

1. `django-admin startproject math_platform server/`
2. 创建 5 个 App（`accounts/qbank/courses/interactions/system`）
3. **settings.py 配置：**
   - `INSTALLED_APPS`：5 App + `rest_framework` + `corsheaders` + `whitenoise` + `drf_spectacular` + `auditlog` + `sentry_sdk`
   - SQLite WAL：`DATABASES` + `connection_created` signal 执行 `PRAGMA journal_mode=WAL;`
   - JWT：`SIMPLE_JWT`（ACCESS_TOKEN_LIFETIME=24h，RE...
   - `REST_FRAMEWORK`：统一响应格式、默认分页、认证类
   - CORS：配置 `CORS_ALLOWED_ORIGINS`（开发 = Flutter 调试端口）
   - 环境变量分离：`python-decouple` 读 `SECRET_KEY`/`DEBUG`/`ALLOWED_HOSTS`
   - WhiteNoise：白名单中间件
   - sentry-sdk：DSN 从环境变量读取，值为空时不初始化
4. **urls.py 挂载：** `/api/v1/` 前缀 + drf-spectacular schema 端点
5. **创建 .env**：生成 SECRET_KEY、DEBUG=True、DB 路径等
6. **requirements.txt**：锁定版本
7. **flake8 配置**：`max-line-length=100`
8. 验证：`python manage.py check` + `python manage.py migrate` 通过

### 验收标准

- [ ] `python manage.py check` 无报错
- [ ] `python manage.py migrate` 成功（虽无模型，但 auth/contenttypes 等内置表创建）
- [ ] flake8 零报错
- [ ] sentry-sdk 初始化不报错（DSN 空时静默不启动）

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

3. `flutter pub get` 验证编译通过
4. `dart analyze` 验证零 warning
5. 删除默认计数器示例代码，保留干净入口

### 验收标准

- [ ] `flutter pub get` 无错误
- [ ] `dart analyze` 零 warning（仅默认模板清理后）
- [ ] 项目能编译（`flutter build apk --debug` 只是验证，不一定跑）

---

## 0.4 — 着陆页

创建 `landing/` 目录，nginx 直出，不走 Django：

| 文件 | 内容 |
|------|------|
| `index.html` | App 下载按钮 + 微信二维码 + 产品简介（占位符） |
| `privacy.html` | 隐私政策（占位符） |
| `terms.html` | 用户协议（占位符） |

页面要求：
- 极简 HTML（无框架依赖）
- 中文字体用系统字体
- `index.html` 底部留版本号占位

### 验收标准

- [ ] 浏览器打开 `landing/index.html` 可正常显示
- [ ] 包含下载按钮和二维码占位
- [ ] 隐私政策和用户协议页面可跳转

---

## 0.5 — CI + git commit

### CI 流水线

**方案：Gitee Go**

路径：`.gitee/workflows/ci.yml`

```yaml
并行流水线：
├─ Flutter:
│   ├─ dart analyze
│   └─ flutter test
└─ Django:
    ├─ flake8
    ├─ python manage.py check --deploy
    └─ python manage.py makemigrations --check
```

### git 提交

```bash
git add server/ flutter_app/ landing/ .gitee/ requirements.txt
git commit -m "Phase 0: 双项目脚手架 + Gitee Go CI"
git push 章鱼智学v2 master
```

### 验收标准

- [ ] Gitee 仓库中可见新提交
- [ ] Gitee Go 流水线自动触发
- [ ] Flutter 和 Django 两条流水线均通过

---

## 产出

两边能编译/迁移通过 + 每次 push 到 Gitee 自动跑流水线。
