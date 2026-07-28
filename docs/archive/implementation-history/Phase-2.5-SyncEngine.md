# Phase 2.5 — 同步引擎 + 更新机制

> 本文档是 [Phase-2-Flutter数据层.md](./Phase-2-Flutter数据层.md) 中 2.5 子步骤的细化执行方案。
> 状态：**进行中** | 最后更新：2026-07-11

---

## 总览

| 子步骤 | 内容 | 工时 | 状态 |
|--------|------|------|------|
| **2.5** | 同步引擎 + 更新机制 | 1 天 | ⬜ |

### 前置条件

- [x] Phase 2.1 完成：3 个 Drift Database + SyncQueueDao 就绪
- [x] Phase 2.2 完成：ApiClient + SyncApi 就绪
- [x] Phase 2.3 完成：AppPrefs + ConnectivityMonitor 就绪
- [ ] `docs/05-Flutter/sync/*.dart` 4 个设计稿已审阅

### 关键设计文档索引

| 文档 | 用途 |
|------|------|
| [`同步引擎设计.md`](../05-Flutter/同步引擎设计.md) | 同步队列状态机 + 重试策略 |
| [`更新机制.md`](../02-数据/更新机制.md) | 版本号体系与启动流程 |
| [`docs/05-Flutter/sync/*.dart`](../05-Flutter/sync/) | 同步引擎 4 个 Dart 设计稿 |
| [`flutter_app/lib/data/sync/`](../../flutter_app/lib/data/sync/) | 实现文件目录 |

---

## 2.5 — 同步引擎 + 更新机制

### 涉及文件

```
flutter_app/lib/data/sync/
├── sync_types.dart            # 枚举 + 数据模型
├── sync_queue_dao.dart        # 队列 DAO（已在 2.1 中创建）
├── sync_pusher.dart           # 推送核心
└── sync_manager.dart          # 总入口

flutter_app/lib/data/sync/update_manager.dart  # 版本检查 + .db 下载 + 替换
```

### 实现要点

#### SyncPusher

从 `docs/05-Flutter/sync/sync_pusher.dart` 设计稿复制，替换抽象接口为真实实现：

```dart
class SyncPusher {
  static const int maxRetries = 5;
  static const int batchSize = 20;

  final SyncQueueDao _dao;
  final SyncApi _api;

  SyncPusher(this._dao, this._api);

  Future<PushBatchResult> pushAll() async {
    // 1. 取一批 (pending + inProgress 的"孤儿记录")
    // 2. 标记 inProgress
    // 3. 调用 _api.pushBatch()
    // 4. 逐条处理结果（成功→markSuccess，失败→markFailed）
    // 5. cleanup()
    // 6. 重复直到队列空
  }
}
```

#### SyncManager（总入口）

```dart
class SyncManager {
  static final SyncManager _instance = SyncManager._();
  factory SyncManager() => _instance;

  SyncQueueDao? _queueDao;
  SyncPusher? _pusher;
  DateTime _lastPushTime = DateTime(2000);

  Future<void> init(SyncQueueDao queueDao, SyncApi api) async { ... }

  Future<void> enqueue({entityType, operation, localId, payload}) async { ... }
  Future<PushBatchResult> pushNow() async { ... }
  Future<void> onAppStart() async { ... }  // 推送积压 + 检查版本
  Future<void> clearQueue() async { ... }
}
```

#### UpdateManager

```dart
class UpdateManager {
  final SyncApi _syncApi;
  final DatabaseProvider _dbProvider;

  UpdateManager(this._syncApi, this._dbProvider);

  Future<UpdateSummary> checkAll() async { ... }
  Future<void> downloadAndReplace(...) async { ... }

  bool shouldForceUpdate({int localVersion, int serverVersion, bool serverForceUpdate}) {
    return serverForceUpdate || (serverVersion - localVersion >= 3);
  }

  bool shouldShowBanner({int localVersion, int serverVersion}) {
    return serverVersion > localVersion;
  }
}
```

#### 启动流程整合

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPrefs().init();
  ApiClient().init(baseUrl: 'https://zhangyuzhixue.top/api/v1/');
  await DatabaseProvider().init();
  ConnectivityMonitor().init();

  final syncQueueDao = SyncQueueDao(DatabaseProvider().appDb);
  final syncApi = SyncApi(ApiClient());
  SyncManager().init(syncQueueDao, syncApi);

  // 启动后异步检查更新 + 推送积压（不阻塞主界面）
  SyncManager().onAppStart();

  runApp(const ZhangyuzhixueApp());
}
```

### 验证方式

```bash
flutter test
# 期望：28+ 同步引擎测试全部通过
```

### 注意事项

- `SyncPusher.pushAll()` 需处理孤儿记录（App 被杀时 inProgress 的记录）
- 同步锁：防止并发推送导致重复上传
- 更新流程中 .db 替换需要先关闭旧库再复制文件

---

## 测试计划

| 测试 | 场景 | 数量 |
|------|------|------|
| SyncPusher.pushAll | 空队列、单批推送成功、分批推送、网络错误全部失败、部分成功部分失败 | 6 |
| SyncPusher.pushAll | 失败记录重试（retryCount < maxRetries） | 2 |
| SyncPusher.pushAll | 永久失败处理（retryCount >= maxRetries） | 2 |
| SyncPusher.pushAll | 孤儿记录（inProgress 重新出队） | 1 |
| SyncPusher.pushAll | cleanup 规则 | 2 |
| SyncManager | onAppStart 调用 push 和 version check | 2 |
| SyncManager | enqueue → pushNow → 队列为空 | 2 |
| SyncManager | 冷却检查（30 秒内重复调用跳过） | 2 |
| UpdateManager | checkAll 并发调两个 version 接口 | 2 |
| UpdateManager | shouldForceUpdate 判断逻辑 | 4 |
| UpdateManager | shouldShowBanner 判断逻辑 | 3 |

**合计：~28 个测试用例**

## 操作清单

1. 将设计稿 `sync_types.dart` 中的类型定义整合到 `lib/data/sync/sync_types.dart`
2. 实现 `sync_pusher.dart`（已依赖 2.1 中的 sync_queue_dao）
3. 实现 `sync_manager.dart`
4. 实现 `update_manager.dart`
5. 整合 `main.dart` 初始化流程
6. 编写同步引擎全部测试（28+ 场景）
7. 编写更新机制测试
8. `flutter test` 全部通过
