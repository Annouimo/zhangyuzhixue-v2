# Phase 2.2–2.3 — DatabaseProvider + ApiClient + AppPrefs + ConnectivityMonitor

> 本文档是 [Phase-2-Flutter数据层.md](./Phase-2-Flutter数据层.md) 中 2.2–2.3 子步骤的细化执行方案。
> 状态：**已完成** | 最后更新：2026-07-10

---

## 总览

| 子步骤 | 内容 | 工时 | 状态 |
|--------|------|------|------|
| **2.2** | DatabaseProvider（生命周期）+ ApiClient（3 拦截器） | 0.5 天 | ✅ |
| **2.3** | AppPrefs + ConnectivityMonitor | 0.5 天 | ✅ |

### 前置条件

- [x] Phase 2.1 已完成：3 个 Drift Database + 11 个 DAO 就绪
- [x] 依赖包已添加：dio, shared_preferences, connectivity_plus

### 关键设计文档索引

| 文档 | 用途 |
|------|------|
| [`数据访问层设计.md`](../05-Flutter/数据访问层设计.md) | DAO→Database、Repository→DAO 层间契约 |
| [`Flutter代码规范.md`](../05-Flutter/Flutter代码规范.md) | Prefs 前缀规范 |
| [`flutter_app/lib/data/database/database_provider.dart`](../../flutter_app/lib/data/database/database_provider.dart) | 实现文件 |
| [`flutter_app/lib/data/api/api_client.dart`](../../flutter_app/lib/data/api/api_client.dart) | 实现文件 |
| [`flutter_app/lib/data/prefs/app_prefs.dart`](../../flutter_app/lib/data/prefs/app_prefs.dart) | 实现文件 |
| [`flutter_app/lib/data/network/connectivity_monitor.dart`](../../flutter_app/lib/data/network/connectivity_monitor.dart) | 实现文件 |

---

## 2.2 — DatabaseProvider + ApiClient

### 涉及文件

```
flutter_app/lib/data/database/database_provider.dart
flutter_app/lib/data/api/
├── api_client.dart          # Dio 单例 + 3 拦截器
├── auth_api.dart            # login/register/refresh/logout
├── sync_api.dart            # push/version check
└── user_api.dart            # me/update/avatar
```

### 2.2.1 — DatabaseProvider

**位置：** `lib/data/database/database_provider.dart`

三库生命周期管理，唯一单例：

```dart
class DatabaseProvider {
  static final DatabaseProvider _instance = DatabaseProvider._();
  factory DatabaseProvider() => _instance;

  AppDatabase? _appDb;
  AssetsDatabase? _assetsDb;
  LecturesDatabase? _lecturesDb;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    await _ensureDefaultAssets();  // 首次从 bundle 复制
    _assetsDb = AssetsDatabase(NativeDatabase(File('${dir.path}/assets.db')));
    _lecturesDb = LecturesDatabase(NativeDatabase(File('${dir.path}/lectures.db')));
    _appDb = AppDatabase(NativeDatabase(File('${dir.path}/user.db')));
    await _appDb!.customStatement('PRAGMA journal_mode=WAL');
  }

  Future<void> replaceAssetsDb(String newPath) async { ... }  // 更新时调用
  Future<void> replaceLecturesDb(String newPath) async { ... }
  Future<void> clearUserDb() async { ... }  // 登出时调用
}
```

**首次启动：** `_ensureDefaultAssets()` 从 Flutter bundle（`assets/db/assets.db`）复制到应用文档目录。

### 2.2.2 — ApiClient + 三个拦截器

**位置：** `lib/data/api/api_client.dart`

```dart
class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio _dio;

  void init({String baseUrl = 'https://zhangyuzhixue.top/api/v1/'}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.addAll([
      _AuthInterceptor(),      // 请求前加 Authorization header
      _RefreshInterceptor(),   // 401 → 刷新 → 重试
      _ErrorInterceptor(),     // 统一解析 {code, message, data}
    ]);
  }
}
```

**三个拦截器职责：**

1. **`_AuthInterceptor`** — 在 `onRequest` 中从 `AppPrefs().accessToken` 读取 token，添加到 `Authorization: Bearer` header
2. **`_RefreshInterceptor`** — 在 `onError` 中捕获 401：
   - 带同步锁（`_isRefreshing`），防止并发多个刷新请求
   - 排队等待的请求在刷新完成后用新 token 重试
   - 刷新失败（refresh token 过期或网络错误）→ `AppPrefs().clearAll()` → 跳登录页
3. **`_ErrorInterceptor`** — 在 `onResponse` 中检查 `body['code']`：
   - `code=0` → 正常通过
   - `code≠0` → 转为 `ApiException(code, message, httpStatus)`

### 2.2.3 — API 类

**auth_api.dart：** `login(LoginRequest)` → `LoginResult`、`register(RegisterRequest)` → void、`refresh(String)` → `RefreshResult`

**sync_api.dart：** `checkVersion(String type)` → `VersionStatus`、`pushBatch(List<Map>)` → `PushBatchResult`

**user_api.dart：** `getInfo()` → `UserInfo`、`updateProfile(Map)` → void、`uploadAvatar(String localPath)` → String（URL）

### 2.2.4 — 测试计划

| 测试 | 场景 | 数量 |
|------|------|------|
| DatabaseProvider | init() 成功打开三库、replaceAssetsDb 后数据可读、clearUserDb 后为空 | 4 |
| ApiClient | init() 后 dio 配置正确、setMockAdapter 生效 | 2 |
| AuthInterceptor | 有 token 时加 header、无 token 不加 | 2 |
| RefreshInterceptor | 401 触发刷新成功、401 触发刷新失败（跳登录）、并发 401 排队 | 4 |
| ErrorInterceptor | code=0 正常通过、code≠0 转为 ApiException | 2 |
| AuthApi | login/register/refresh 各一个 mock 测试 | 3 |
| SyncApi | checkVersion/pushBatch 各一个 mock 测试 | 2 |

**合计：~19 个测试用例**

### 2.2.5 — 操作清单

1. 创建 `database_provider.dart`，实现三库生命周期
2. 创建 `api_client.dart`，实现 Dio 单例 + 三个拦截器
3. 创建 `auth_api.dart` / `sync_api.dart` / `user_api.dart`
4. 编写拦截器链测试（重点：RefreshInterceptor 的同步锁 + 排队）
5. 编写 API mock 测试
6. `flutter test` 全部通过

---

## 2.3 — AppPrefs + ConnectivityMonitor

### 涉及文件

```
flutter_app/lib/data/prefs/app_prefs.dart
flutter_app/lib/data/network/connectivity_monitor.dart
```

### 2.3.1 — AppPrefs

**位置：** `lib/data/prefs/app_prefs.dart`

封装全局 key（`app_` 前缀），页面级 key 前缀规范在 Flutter 代码规范 §1.5 和 §2.2 中定义。

```dart
class AppPrefs {
  static final AppPrefs _instance = AppPrefs._();
  factory AppPrefs() => _instance;

  SharedPreferences? _prefs;

  Future<void> init() async { _prefs = await SharedPreferences.getInstance(); }

  // Token
  String? get accessToken => _prefs!.getString(Keys.accessToken);
  String? get refreshToken => _prefs!.getString(Keys.refreshToken);
  Future<bool> saveAccessToken(String token) => _prefs!.setString(Keys.accessToken, token);
  Future<bool> saveRefreshToken(String token) => _prefs!.setString(Keys.refreshToken, token);

  // User cache
  Map<String, dynamic>? get userCache { ... }
  Future<bool> saveUserCache(Map<String, dynamic> data) { ... }

  // DB versions
  int get qbankVersion => _prefs!.getInt(Keys.qbankVersion) ?? 0;
  int get lectureVersion => _prefs!.getInt(Keys.lectureVersion) ?? 0;

  // Course access cache
  List<int> get accessibleCourseIds { ... }
  Future<bool> saveAccessibleCourseIds(List<int> ids) { ... }

  // Update flow cooldown
  int? get lastUpdatePromptTimestamp { ... }
  Future<bool> saveLastUpdatePromptTimestamp(int ts) { ... }

  // Rating cooldown
  bool isRatingCooldownActive(String pageUrl) { ... }
  Future<void> setRatingCooldown(String pageUrl) { ... }

  Future<bool> clearAll() => _prefs!.clear();
}

class Keys {
  static const accessToken = 'app_auth_token';
  static const refreshToken = 'app_refresh_token';
  static const userCache = 'app_user_cache';
  static const qbankVersion = 'app_qbank_version';
  static const lectureVersion = 'app_lecture_version';
  static const accessibleCourses = 'app_accessible_courses';
  static const lastUpdatePrompt = 'app_last_update_prompt';
  static const ratingCooldownPrefix = 'app_rating_cooldown_';
  static const firstLaunchComplete = 'app_first_launch';
}
```

### 2.3.2 — ConnectivityMonitor

**位置：** `lib/data/network/connectivity_monitor.dart`

```dart
class ConnectivityMonitor {
  static final ConnectivityMonitor _instance = ConnectivityMonitor._();
  factory ConnectivityMonitor() => _instance;

  final _connectivity = Connectivity();
  final _stateController = BehaviorSubject<bool>.seeded(true);

  bool get isOnline => _stateController.value;
  Stream<bool> get onConnectivityChanged => _stateController.stream;

  void init() {
    _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      _stateController.add(online);
    });
  }

  void dispose() => _stateController.close();
}
```

### 2.3.3 — 测试计划

| 测试 | 数量 |
|------|------|
| AppPrefs: token 读写 | 2 |
| AppPrefs: version 读写 | 2 |
| AppPrefs: clearAll 清空 | 1 |
| AppPrefs: userCache | 2 |
| ConnectivityMonitor: init 后状态 | 1 |

**合计：~8 个测试用例**

### 2.3.4 — 操作清单

1. 创建 `app_prefs.dart`，实现所有全局 key 的读写
2. 创建 `connectivity_monitor.dart`
3. 编写 AppPrefs 和 ConnectivityMonitor 测试
4. `flutter test` 全部通过
