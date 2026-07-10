# Phase 0 — 执行记录

> 执行日期：2026-07-10 | 对应计划文档：Phase-0-脚手架+CI.md

---

## 0.1 — 依赖安装结果

| 包名 | 版本 |
|------|------|
| djangorestframework | 3.17.1 |
| djangorestframework-simplejwt | 5.5.1 |
| django-cors-headers | 4.9.0 |
| python-decouple | 3.8 |
| flake8 | 7.3.0 |
| drf-spectacular | 0.30.0 |
| django-auditlog | 3.4.1 |

**附：** Django 5.2.15 → 5.2.16 和 sentry-sdk 2.63.0 → 2.64.0 也一并更新。

## 0.2 — Django 脚手架结果

- [x] `python manage.py check` — **零问题**
- [x] `python manage.py migrate` — **34 个迁移全部 OK**
- [x] flake8 — **零问题**
- [x] sentry-sdk 静默不启动

**提交：** `eb06ebe`（后合并至 `9cee0db`、`ca44fe4`）

## 0.3 — Flutter 脚手架结果

- [x] `flutter pub get` — **78 依赖解析成功**
- [x] `dart analyze` — **No issues found!**
- [x] `flutter test` — **All tests passed!**

**提交：** `0fa9587`

## 0.4 — 着陆页结果

- [x] `landing/index.html` 正常显示
- [x] 三个下载按钮存在（# 占位链接）
- [x] 微信二维码图片显示
- [x] 隐私政策和用户协议页面可跳转

**提交：** `333f440`

## 0.5 — CI 配置结果

**CI 调试过程：** 经历了 7 轮修复（Node.js 兼容性→Flutter SDK 下载路径→`subosito/flutter-action` 缓存配置等），最终流水线全绿通过。

**前置条件完成情况：**
- [x] 用户创建空 GitHub 仓库（同名 `zhangyuzhixue-v2`）
- [x] 用户在 Gitee 仓库设置中配置自动同步到 GitHub
- [x] 首次 push 触发 CI，验证两条流水线均通过 ✅

**提交：** `ca44fe4`

---

## Phase 0 产出确认

- ✅ Django 项目可编译、迁移通过、flake8 零问题
- ✅ Flutter 项目 dart analyze 零问题、测试通过
- ✅ 着陆页静态 HTML 就位
- ✅ GitHub Actions CI 配置就位，流水线全绿 ✅
