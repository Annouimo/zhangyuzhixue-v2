# Phase 2 — Flutter 数据层（4.5 天，每步测）

> 本文档是 [00-落地计划.md](../00-落地计划.md) 中 Phase 2 的细化执行方案总入口。
> 各子步骤的详细方案见对应的拆分文档。
> 状态：**进行中（2.1~2.4 已完成）** | 最后更新：2026-07-10

---

## 总览

| 子步骤 | 内容 | 工时 | 状态 | 细化文档 |
|--------|------|------|------|---------|
| **2.1** 🔧CI | 3 个 Drift Database（assets/lectures/user）+ 11 个 DAO | 1.5 天 | ✅ | [Phase-2.1-DB+DAO.md](./Phase-2.1-DB+DAO.md) |
| **2.2** | DatabaseProvider（生命周期）+ ApiClient（3 拦截器） | 0.5 天 | ✅ | [Phase-2.2-2.3-ApiClient+Prefs.md](./Phase-2.2-2.3-ApiClient+Prefs.md) |
| **2.3** | AppPrefs + ConnectivityMonitor | 0.5 天 | ✅ | ↑ 同上 |
| **2.4** | 13 个 Repository 全部实现 | 1.5 天 | ✅ | [Phase-2.4-Repository.md](./Phase-2.4-Repository.md) |
| **2.5** | 同步引擎 + 更新机制 | 1 天 | ⬜ | 见下文 §2.5 |

### 前置条件

- [x] 服务端已部署到 staging（Phase 1.5），API 端点可用
- [x] Flutter SDK（3.44+）和 Drift 环境就绪
- [x] 已读取 `docs/02-数据/数据库结构设计.md` 全部表定义
- [x] 已读取 `docs/05-Flutter/` 下所有 Repository 设计稿（13 个文件）

### 关键设计文档索引

| 文档 | 用途 |
|------|------|
| [`数据库结构设计.md`](../02-数据/数据库结构设计.md) | 所有表定义（assets + user） |
| [`Flutter代码规范.md`](../05-Flutter/Flutter代码规范.md) | 目录结构、Repository 规范、Widget 复用 |
| [`数据访问层设计.md`](../05-Flutter/数据访问层设计.md) | DAO→Database、Repository→DAO 层间契约 |
| [`同步引擎设计.md`](../05-Flutter/同步引擎设计.md) | 同步队列状态机 + 重试策略 |
| [`docs/05-Flutter/Repository/*.dart`](../05-Flutter/Repository/) | 13 个 Repository 接口 + 数据模型定义 |
| [`docs/05-Flutter/sync/*.dart`](../05-Flutter/sync/) | 同步引擎 4 个 Dart 设计稿 |
| [`更新机制.md`](../02-数据/更新机制.md) | 版本号体系与启动流程 |
| [`构建脚本设计.md`](../02-数据/构建脚本设计.md) | assets.db/lectures.db 表结构定义 |
| [`本地数据架构.md`](../02-数据/本地数据架构.md) | 三库方案和网络失败处理 |

### 当前 Flutter 端状态（Phase 2 2.1~2.4 完成后）

```
flutter_app/lib/
├── main.dart              # 仅骨架
├── pubspec.yaml           # ✅ 依赖已定义
├── lib/data/
│   ├── api/               # ✅ ApiClient（3 拦截器）+ AuthApi/SyncApi/UserApi
│   ├── daos/              # ✅ 11 个 DAO（memory DB CRUD，88 条测试）
│   ├── database/          # ✅ 3 个 Drift Database + DatabaseProvider
│   ├── helpers/           # ✅ 工具方法（PDF 下载、题目状态推算）
│   ├── network/           # ✅ ConnectivityMonitor
│   ├── prefs/             # ✅ AppPrefs
│   └── sync/              # ⚠️ 骨架就位（Phase 2.5 待完成）
├── lib/domain/            # ✅ 13 个 Repository（57 条集成测试）
└── test/
    ├── data/api/          # ✅ 拦截器链 + API mock 测试
    ├── data/daos/         # ✅ 11 个 DAO 测试文件
    ├── data/database/     # ✅ DatabaseProvider 测试
    ├── data/domain/       # ✅ 13 个 Repository 测试
    ├── data/helpers/      # ✅ Helper 单元测试
    ├── data/network/      # ✅ ConnectivityMonitor 测试
    ├── data/prefs/        # ✅ AppPrefs 测试
    └── data/sync/         # ⚠️ 4 个测试失败（update_manager 未实现）
```

### 🔧CI 更新说明

| 子步骤 | CI 变更 |
|--------|---------|
| **2.1** | CI 中 Flutter job 的 `flutter test` 开始包含 DAO 测试。配置已就位无需改动 |
| **2.2–2.5** | CI 无变更，增量测试已在 `flutter test` 中覆盖 |

> 详细实现方案：
> - [Phase-2.1-DB+DAO.md](./Phase-2.1-DB+DAO.md) — 3 个 Database + 11 个 DAO
> - [Phase-2.2-2.3-ApiClient+Prefs.md](./Phase-2.2-2.3-ApiClient+Prefs.md) — DatabaseProvider + ApiClient + Prefs + ConnectivityMonitor
> - [Phase-2.4-Repository.md](./Phase-2.4-Repository.md) — 13 个 Repository

---

## 2.5 — 同步引擎 + 更新机制（1 天）

### 涉及文件

```
flutter_app/lib/data/sync/
├── sync_types.dart            # 枚举 + 数据模型
├── sync_queue_dao.dart        # 队列 DAO（已在 2.1 中创建）
├── sync_pusher.dart           # 推送核心
└── sync_manager.dart          # 总入口

flutter_app/lib/data/sync/update_manager.dart  # 版本检查 + .db 下载 + 替换
```

### 2.5.1 — SyncPusher

从 `docs/05-Flutter/sync/sync_pusher.dart` 设计稿复制，替换抽象接口为真实实现：

```dart
class SyncPusher {
  static const int maxRetries = 5;
  static const int batchSize = 20;

  final SyncQueueDao _dao;
  final SyncApi _api;

  SyncPusher(this._dao, this._api);

  /// 推送所有待同步数据
  Future<PushBatchResult> pushAll() async {
    // 1. 取一批 (pending + inProgress 的"孤儿记录")
    // 2. 标记 inProgress
    // 3. 调用 _api.pushBatch()
    // 4. 逐条处理结果（成功→markSuccess，失败→markFailed）
    // 5. cleanup()
    // 6. 重复直到队列空
    ...
  }
}
```

### 2.5.2 — SyncManager（总入口）

```dart
class SyncManager {
  static final SyncManager _instance = SyncManager._();
  factory SyncManager() => _instance;

  SyncQueueDao? _queueDao;
  SyncPusher? _pusher;
  DateTime _lastPushTime = DateTime(2000);

  Future<void> init(SyncQueueDao queueDao, SyncApi api) async { ... }

  // 外部接口
  Future<void> enqueue({entityType, operation, localId, payload}) async { ... }
  Future<PushBatchResult> pushNow() async { ... }
  Future<void> onAppStart() async { ... }  // 推送积压 + 检查版本
  Future<void> clearQueue() async { ... }
}
```

### 2.5.3 — UpdateManager（版本检查 + .db 下载 + 替换）

```dart
class UpdateManager {
  final SyncApi _syncApi;
  final DatabaseProvider _dbProvider;

  UpdateManager(this._syncApi, this._dbProvider);

  /// 入口：并发检查 qbank 和 lecture 版本
  Future<UpdateSummary> checkAll() async { ... }

  /// 下载 .db.gz → 解压 → checksum 验证 → 替换
  Future<void> downloadAndReplace(...) async { ... }

  /// 判断是否需要强制更新
  bool shouldForceUpdate({int localVersion, int serverVersion, bool serverForceUpdate}) {
    return serverForceUpdate || (serverVersion - localVersion >= 3);
  }

  /// 判断是否更新横幅
  bool shouldShowBanner({int localVersion, int serverVersion}) {
    return serverVersion > localVersion;
  }
}
```

### 2.5.4 — 启动流程整合

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

### 2.5.5 — 测试计划

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

### 2.5.6 — 操作清单

1. 将设计稿 `sync_types.dart` 中的类型定义整合到 `lib/data/sync/sync_types.dart`
2. 实现 `sync_pusher.dart`（已依赖 2.1 中的 sync_queue_dao）
3. 实现 `sync_manager.dart`
4. 实现 `update_manager.dart`
5. 整合 `main.dart` 初始化流程
6. 编写同步引擎全部测试（28+ 场景）
7. 编写更新机制测试
8. `flutter test` 全部通过

---

## 依赖关系说明

```
2.1 Drift Databases + DAOs
  │
  ├─ 2.2 DatabaseProvider ─────────────────────┐
  │                                            │
  ├─ 2.2 ApiClient ────────────────────────────┤
  │                                            │
  ├─ 2.3 AppPrefs ────────────────────────────┼┤
  │                                            ││
  ├─ 2.3 ConnectivityMonitor ──────────────────┼┤
  │                                             │
  └─────────────────────────────────────────────┘
       ↓                                        ↓
  2.4 Repositories（依赖 DAO + Api）        2.5 Sync Engine（依赖 DAO + Api）
                                                │
                                            UpdateManager（依赖 SyncApi + DatabaseProvider）
```

| 步骤 | 依赖 | 可并行 |
|------|------|-------|
| 2.1 | 无 | — |
| 2.2 | 2.1（DatabaseProvider 需要 Database） | — |
| 2.3 | 无 | ✅ 与 2.1/2.2 并行 |
| 2.4 | 2.1 + 2.2 + 2.3 | — |
| 2.5 | 2.1 + 2.2 + 2.3 | ✅ 与 2.4 并行 |

---

## 测试汇总

| 层级 | 测试项 | 测试数 |
|------|-------|-------|
| L1: DAO 单元测试 | 11 个 DAO × memory DB | ~59 |
| L2: 基础设施 | DatabaseProvider + ApiClient 拦截器 + AppPrefs + Connectivity | ~19 |
| L3: 基础设施 | AppPrefs + ConnectivityMonitor | ~8 |
| L4: Repository 集成 | 13 个 Repository + 5 个尾部算法类 | ~75 |
| L5: 同步引擎 | SyncPusher + SyncManager + UpdateManager | ~28 |
| **合计** | | **~189 个测试** |

> 测试嵌入到每个子步骤中，做到哪步测到哪步，不攒到最后。

---

## 验收标准

1. `flutter test` 全部通过（~189 个测试）
2. 3 个 Drift Database 均能正确打开 assets.db / lectures.db / user.db
3. 11 个 DAO 对各自表完成 CRUD 覆盖
4. DatabaseProvider 能成功替换 assets.db 和 lectures.db
5. ApiClient 三个拦截器链在 mock 测试中完整通过
6. Token 刷新同步锁机制在并发 401 场景下正确排队
7. 13 个 Repository 从本地 DB 读取并安全组合数据
8. 5 个尾部算法类的算法逻辑测试通过
9. SyncPusher 能完成队列推送 + 重试 + cleanup 全流程
10. UpdateManager 能判断强制/非强制更新规则
11. App 启动流程不阻塞主界面
