# OperationLog — 客户端运行日志系统

> 本文档定义客户端的飞行记录器（OperationLog）设计、覆盖范围和导出方式。
>
> 更新日期：2026-07-16

---

## 设计目标

内测阶段需要一种轻量方式获取用户操作上下文，以便排查"没有报错但体验不对"的问题。

| 原则 | 说明 |
|------|------|
| **release 下正常工作** | 不依赖 `--dart-define`，正式构建也有日志 |
| **低开销** | 内存滚动 200 条，文件约 60KB，不写 DAO 级别的细粒度日志 |
| **可导出** | 用户通过按钮把日志文件导出，通过微信发给你 |
| **不自动上报** | 内测 3 教师不需要，等规模扩大再考虑 Sentry |

---

## 记录内容

每条日志是一个 NDJSON 行（JSON 对象，`\n` 分隔）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `t` | string | ISO8601 时间戳 |
| `seq` | int | 全局序号 |
| `cat` | string | 类别：`page` / `api` / `action` / `nav` / `error` / `sync` |
| `src` | string | 来源（页面名/API 路径/操作名） |
| `d` | string | 详情 |

### 记录类别

| 类别 | 记录时机 | 示例 |
|------|---------|------|
| **page** | 页面 `_load()` 成功时 | `IndexPage load_ok pending=3` |
| **api** | 每次 API 请求后（成功+失败） | `GET /api/v1/sync/qbank/version/ 200` |
| **action** | 用户关键操作成功后 | `checkin ok +5pts streak=3` |
| **nav** | 每次页面跳转（路由 push） | `/solve/choice?id=42 push` |
| **error** | catch 块捕获的异常 | `IndexPage._load DioException: timeout` |
| **sync** | 同步操作 | `push 2 items done` |

### 不记录的内容

- DAO 每次查询（太吵）
- SharedPreferences 每次读取（无意义）
- Widget build/rebuild（无意义）

---

## 覆盖范围

### 学生端 (flutter_app)

| 维度 | 覆盖 |
|------|------|
| 全局未捕获异常 | `FlutterError.onError` + `PlatformDispatcher.onError` |
| API 请求 | 所有请求（成功响应+网络异常+业务错误） |
| 页面 catch 块 | 全部 34 个页面 |
| 导航 | `GoRouter` 的 `_RouteLogger` observer |
| 用户操作 | 签到 / 登录 / 注册 / 做题提交 / 评分 / 组卷 |
| 日志导出 | 关于页 + 登录页有「导出运行日志」按钮 |

### 教师端 (teacher_app)

| 维度 | 覆盖 |
|------|------|
| 全局未捕获异常 | `FlutterError.onError` + `PlatformDispatcher.onError` |
| 页面 catch 块 | 全部 8 个页面 |
| 日志导出 | 设置页有「导出运行日志」按钮 |

---

## 导出方式

用户点击「导出运行日志」按钮后：

1. `OperationLog.exportToShare()` 将日志文件复制到应用文档目录下的 `operation_log_export.ndjson`
2. 弹出 Toast 提示「日志已导出，可通过微信发送」
3. 用户通过微信文件传输功能把文件发给你

**日志文件位置**（用户可以自行找到）：

| 平台 | 路径 |
|------|------|
| Windows | `%APPDATA%/com.zhangyuzhixue.student/operation_log.ndjson` |
| Android | `/data/data/com.zhangyuzhixue.student/app_flutter/operation_log.ndjson` |

---

## 实现文件

| 文件 | 说明 |
|------|------|
| `lib/data/debug/operation_log.dart` | OperationLog 单例（学生端） |
| `teacher_app/lib/data/debug/operation_log.dart` | OperationLog 单例（教师端，内容相同） |
| `lib/main.dart` | 学生端初始化 + 全局异常捕获 |
| `teacher_app/lib/main.dart` | 教师端初始化 + 全局异常捕获 |
| `lib/data/api/api_client.dart` | API 拦截器日志 |
| `lib/pages/router.dart` | 导航 observer |
| `lib/pages/profile/about_page.dart` | 学生端导出按钮 |
| `lib/pages/login_page.dart` | 登录页导出按钮 |
| `teacher_app/lib/pages/settings/settings_page.dart` | 教师端导出按钮 |
