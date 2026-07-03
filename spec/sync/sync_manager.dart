/// 章鱼智学 — 同步引擎总入口
///
/// 本文件提供同步引擎对外的统一接口。
/// Repository 层通过 SyncManager.enqueue() 入队，不直接操作 DAO。
///
/// 定稿后对接工作：
/// - 在 App 初始化流程中调用 init() 和 onAppStart()
/// - Repository 写入方法中调用 enqueue()
/// - AuthRepository 登出时调用 clearQueue()

/// 同步引擎总入口（单例）
///
/// 职责：
/// 1. 对外暴露 enqueue() / pushNow() / clearQueue() 等接口
/// 2. 在 App 启动时调用 onAppStart() 触发推送 + 版本检查
/// 3. 隔离 DAO 和 Pusher 的实现细节
///
/// 使用方式（定稿后在 App 初始化中）：
/// ```dart
/// // 定稿后替换为真实的 Database 和 Dio 实例
/// // final db = AppDatabase(…);
/// // final dio = Dio(…);
/// // await SyncManager().init(db, dio);
/// // await SyncManager().onAppStart();
/// ```
class SyncManager {
  // ── 单例 ──
  static final SyncManager _instance = SyncManager._();
  factory SyncManager() => _instance;
  SyncManager._();

  SyncQueueDao? _queueDao;
  SyncPusher? _pusher;

  // ── 状态 ──
  bool _initialized = false;

  /// 初始化同步引擎（App 启动时调用一次）
  ///
  /// 参数说明（定稿后替换为真实类型）：
  /// - [database]: 定稿后替换为 AppDatabase 实例
  /// - [api]: 定稿后替换为 SyncApi 实例（实现了 SyncApiInterface）
  ///
  /// 使用示例：
  /// ```dart
  /// // final db = AppDatabase.create();
  /// // final api = SyncApi(Dio());
  /// // SyncManager().init(db, api);
  /// ```
  Future<void> init(
    /// 定稿后替换为 Database / QueryExecutor 类型
    Object database,

    /// 定稿后替换为 SyncApiInterface 类型
    SyncApiInterface api,
  ) async {
    if (_initialized) return;

    // 定稿后替换：
    // _queueDao = SyncQueueDao(database);  // 传入真正的 Drift DAO
    // _pusher = SyncPusher(_queueDao, api);
    _initialized = true;
  }

  // ═══════════════════════════════════
  // 对外接口
  // ═══════════════════════════════════

  /// 入队一条待同步记录
  ///
  /// Repository 的写入方法在本地写入完成后调用此方法。
  ///
  /// 使用示例：
  /// ```dart
  /// await SyncManager().enqueue(
  ///   entityType: SyncEntityType.rating,
  ///   operation: SyncOperationType.upsert,
  ///   localId: localId,
  ///   payload: { 'question_id': 42, 'difficulty': 3.5 },
  /// );
  /// ```
  Future<void> enqueue({
    required SyncEntityType entityType,
    required SyncOperationType operation,
    required int localId,
    required Map<String, dynamic> payload,
  }) async {
    _ensureInitialized();
    await _queueDao!.enqueue(
      entityType: entityType.name,
      operationType: operation.name,
      localId: localId,
      payload: payload,
    );
  }

  /// App 启动时调用：推送待同步数据 + 检查题库版本
  ///
  /// 放在 App 初始化流程的最后一步：
  /// ```dart
  /// await SyncManager().onAppStart();
  /// ```
  Future<void> onAppStart() async {
    _ensureInitialized();

    // 1. 推送本地积压的待同步记录
    final pushResult = await pushNow();

    // 2. 检查题库版本（静默，失败不阻断）
    // 定稿后替换为：
    // try {
    //   final version = await _api.checkVersion();
    //   if (version.version > localVersion && version.forceUpdate) {
    //     // 引导去商店更新
    //   }
    // } catch (_) {
    //   // 版本检查失败不影响 App 使用
    // }
  }

  /// 手动触发推送（UI 下拉刷新时调用）
  ///
  /// 返回推送结果，UI 可据此显示提示（如 "已同步 5 条"）。
  Future<PushBatchResult> pushNow() async {
    _ensureInitialized();
    return _pusher!.pushAll();
  }

  /// 清空队列（登出时调用）
  Future<void> clearQueue() async {
    _ensureInitialized();
    await _queueDao!.clearAll();
  }

  // ═══════════════════════════════════
  // 私有方法
  // ═══════════════════════════════════

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'SyncManager not initialized. Call SyncManager().init() first.',
      );
    }
  }
}
