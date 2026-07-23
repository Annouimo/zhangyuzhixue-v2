# 章鱼智学 · App 基本信息

> 本文档记录所有 App 的基本身份信息（名称、包名、版本等）。这两个 App 互不依赖，可独立构建和发布。
>
> 更新日期：2026-07-16

---

## 一、学生端 (flutter_app)

| 属性 | 值 | 说明 |
|------|----|------|
| **项目名** | `flutter_app` | Dart 包名，仅内部使用 |
| **应用名** | `章鱼智学` | 用户看到的名称 |
| **应用描述** | `章鱼智学 v2 - Flutter 学生端` | pubspec.yaml 描述字段 |
| **版本** | `1.0.0-alpha.2+1` | 见下方版本号说明 |
| **Android - 包名 (applicationId)** | `com.zhangyuzhixue.student` | Google Play / 各应用商店区分应用的唯一 ID。**发布后不可更改**，否则视为新应用 |
| **Android - 显示名称** | `章鱼智学` | `AndroidManifest.xml` 中 `android:label`，桌面图标下方文字 |
| **iOS - Bundle ID** | `com.zhangyuzhixue.student` | App Store 区分应用唯一 ID，与 Android applicationId 对应但独立维护 |
| **iOS - 显示名称** | `章鱼智学` | `Info.plist` 中 `CFBundleDisplayName`，桌面图标下方文字 |
| **iOS - 内部名称** | `章鱼智学` | `Info.plist` 中 `CFBundleName`，系统内部使用 |
| **Windows - 窗口标题** | `章鱼智学` | `windows/runner/main.cpp` 中 `window.Create()` 的参数。任务栏和窗口标题栏显示的名称 |
| **Windows - 安装包名** | `章鱼智学-alpha1.exe` | 发布物文件名 |
| **Windows - MSIX 标识** | `Annouimo.526026C9DD952` | 微软商店安装标识 |
| **Windows - 显示名称** | `章鱼智学` | MSIX 开始菜单/任务栏显示 |

### 版本号详解

`1.0.0-alpha.2+1` 拆解：

```
 1 . 0 . 0 -alpha . 1 + 1
 │   │   │    │       │
 │   │   │    │       └── 构建号 (build number)
 │   │   │    │           Android: versionCode，Google Play 据此判断哪个包更新
 │   │   │    │           iOS: CFBundleVersion
 │   │   │    │           纯数字，每次发布递增，不要重复
 │   │   │    │           不展示给用户看
 │   │   │    │
 │   │   │    └────── 预发布标识 (pre-release)
 │   │   │               alpha  → 内部测试阶段
 │   │   │               beta   → 公开测试阶段
 │   │   │               rc     → 发布候选 (release candidate)
 │   │   │               后缀 .1, .2, .3... 表示第几次迭代
 │   │   │               正式发布时删除此段
 │   │   │
 │   │   └─────────────────── 补丁号 (patch)
 │   │                        修复 bug 时递增
 │   │                        不新增功能、不改变 UI 交互
 │   │
 │   └─────────────────────── 次版本号 (minor)
 │                            新增功能（向下兼容）时递增
 │                            如：新增一个页面、新增一个 API 端点
 │
 └─────────────────────────── 主版本号 (major)
                              不兼容的重大变更时递增
                              如：重构数据库架构、更换技术栈、
                              重写核心交互流程
```

**变更规则：**

| 场景 | 改哪段 | 示例 |
|------|--------|------|
| 修了个 bug，重新发版 | 只升 build | `1.0.0-alpha.1+1` → `1.0.0-alpha.1+2` |
| 增加了小功能 | 升 pre-release 补丁 | `1.0.0-alpha.1+1` → `1.0.0-alpha.2+1` |
| 进入公开测试 | 改 pre-release 标识 | `1.0.0-alpha.2+1` → `1.0.0-beta.1+1` |
| 正式发版 | 去掉 pre-release | `1.0.0-beta.3+5` → `1.0.0+6` |
| 重大架构变更 | 升 major | `1.0.0+6` → `2.0.0+1` |

**自动生成：** `lib/constants/app_version.dart` 由 `scripts/generate_version.py` 从 `pubspec.yaml` 读取生成。不要手动编辑该文件。

### 版本号在各平台的位置

| 平台 | 字段 | 文件 |
|------|------|------|
| 单源定义 | `version: 1.0.0-alpha.1+1` | `pubspec.yaml` |
| Android versionName | `1.0.0-alpha.1` | `pubspec.yaml` → `CFBundleShortVersionString` |
| Android versionCode | `1` | `pubspec.yaml` → `CFBundleVersion` |
| iOS Short Version | `$(FLUTTER_BUILD_NAME)` | `ios/Runner/Info.plist`（自动读取） |
| iOS Build Version | `$(FLUTTER_BUILD_NUMBER)` | `ios/Runner/Info.plist`（自动读取） |

> ⚠️ `ios/Flutter/Generated.xcconfig` 中的 `FLUTTER_BUILD_NAME=1.0.0` 和 `FLUTTER_BUILD_NUMBER=1` 是在 `flutter pub get` 时从 pubspec.yaml 解析后自动生成的。如果修改了 pubspec.yaml 的版本号，重新 `flutter pub get` 会自动更新这里。

---

## 二、教师端 (teacher_app)

| 属性 | 值 | 说明 |
|------|----|------|
| **项目名** | `teacher_app` | Dart 包名，仅内部使用 |
| **应用名** | `章鱼智学 · 教师端` | 用户看到的名称 |
| **应用描述** | `章鱼智学 v2 - 教师端（题库浏览 + 讲义阅读 + 选题导出）` | pubspec.yaml 描述字段 |
| **版本** | `1.0.0-alpha.2+1` | 与学生端同步发布 |
| **Android - 包名 (applicationId)** | `com.zhangyuzhixue.teacher` | 与学生端不同 |
| **Android - 显示名称** | `章鱼智学 · 教师端` | 桌面图标下方文字 |
| **iOS - Bundle ID** | `com.zhangyuzhixue.teacher` | 与学生端不同 |
| **iOS - 显示名称** | `章鱼智学 · 教师端` | `CFBundleDisplayName` |
| **iOS - 内部名称** | `章鱼智学 · 教师端` | `CFBundleName` |
| **Windows - MSIX 显示名** | `章鱼智学 · 教师端` | 开始菜单/任务栏显示 |
| **Windows - MSIX 标识** | `com.zhangyuzhixue.teacher` | 安装标识，不可更改 |
| **Windows - 窗口标题** | `章鱼智学 · 教师端` | `windows/runner/main.cpp` 中 `window.Create()` 的参数 |

> 教师端版本号格式与学生端完全一致，同步发布，版本号始终保持相同。

---

## 三、教师 Web 端

教师 Web 端是纯静态页面，没有独立版本号，与服务端 API 版本绑定：

| 属性 | 值 | 说明 |
|------|----|------|
| **入口 URL** | `https://zhangyuzhixue.top/teacher/` | 发布作业、学情管理 |
| **登录页** | `https://zhangyuzhixue.top/teacher/login.html` | JWT 认证 |
| **技术栈** | 纯静态 HTML/CSS/JS | nginx 直出，直接调 REST API |
| **版本号** | 不独立维护 | 跟随服务端发布节奏 |

---

## 四、共用基础设施

| 属性 | 值 | 说明 |
|------|----|------|
| **API 基础 URL** | `https://zhangyuzhixue.zhtec123.com/api/v1` | 两端共用 |
| **服务端根域名** | `https://zhangyuzhixue.zhtec123.com` | 用于构建 PDF URL 等 |
| **公网着陆页** | `https://zhangyuzhixue.top` | `landing/index.html`，Cloudflare Tunnel → nginx 直出 |
| **内测下载页** | `https://zhangyuzhixue.top/internal.html` | 无公开入口 |
| **API 服务器** | 腾讯云轻量应用服务器, 81.70.243.63 | 2C2G |
| **TLS** | API 域名：Let's Encrypt（nginx）；旧域名：Cloudflare Tunnel |

---

## 五、变更流程

修改任何基本信息时，需同步更新以下所有位置：

```
修改 pubspec.yaml 版本号
  → 重新运行 python scripts/generate_version.py    (更新两端 app_version.dart)
  → flutter pub get                                 (更新 iOS Generated.xcconfig)
  → 更新 landing/internal.html 中的版本号文案和下载链接
  → 更新本文档

修改显示名称
  → AndroidManifest.xml (android:label)
  → ios/Runner/Info.plist (CFBundleDisplayName / CFBundleName)
  → teacher_app: teacher_app/pubspec.yaml (msix_config.display_name)
  → Flutter main.dart 中的 title 字段
  → 更新本文档

修改包名/Bundle ID
  → android/app/build.gradle.kts (applicationId)
  → ios/Runner/Configs/AppInfo.xcconfig (PRODUCT_BUNDLE_IDENTIFIER)
  → flutter_app/pubspec.yaml (msix_config.identity_name)
  → teacher_app/pubspec.yaml (msix_config.identity_name)
  → 同步修改 MainActivity.kt 的包名和目录结构
  → 更新本文档
```
