import '../daos/sync_queue_dao.dart';
import '../api/sync_api.dart';
import '../database/database_provider.dart';
import 'sync_types.dart';
import 'sync_pusher.dart';
import 'update_manager.dart';

/// 同步引擎总入口（单例）
class SyncManager {
  static final SyncManager _instance = SyncManager._();
  factory SyncManager() => _instance;
  SyncManager._();

  SyncQueueDao? _queueDao;
  SyncPusher? _pusher;
  UpdateManager? _updateManager;
  SyncApi? _api;
  DatabaseProvider? _dbProvider;
  bool _initialized = false;
  DateTime _lastPushTime = DateTime(2000);

  Future<void> init(SyncQueueDao queueDao, SyncApi api, DatabaseProvider dbProvider) async {
    if (_initialized) return;
    _queueDao = queueDao;
    _api = api;
    _dbProvider = dbProvider;
    _pusher = SyncPusher(queueDao, api);
    _updateManager = UpdateManager(api, dbProvider);
    _initialized = true;
  }

  UpdateManager? get updateManager => _updateManager;

  Future<void> enqueue({
    required SyncEntityType entityType,
    required SyncOperationType operation,
    required int localId,
    required String payload,
  }) async {
    _ensureInitialized();
    await _queueDao!.enqueue(
      entityType: entityType.name,
      operationType: operation.name,
      entityId: localId,
      payload: payload,
    );
  }

  /// App 启动时推送积压并发起版本检查
  Future<void> onAppStart() async {
    _ensureInitialized();
    await pushNow();
    // 版本检查非阻塞，失败不影响 App 启动
    try {
      await _updateManager!.checkAll();
    } catch (_) {
      // 静默失败，版本检查由 UI 层择机重试
    }
  }

  Future<PushSummary?> pushNow() async {
    _ensureInitialized();
    final now = DateTime.now();
    if (now.difference(_lastPushTime).inSeconds < 30) return null;
    _lastPushTime = now;
    return _pusher!.pushAll();
  }

  Future<void> clearQueue() async {
    _ensureInitialized();
    await _queueDao!.clearAll();
  }

  /// 登录后调用：推送积压 → 拉取并替换 user.db
  Future<void> onLogin() async {
    try {
      await pushNow();
      final info = await _api!.fetchUserPullInfo();
      await _updateManager!.downloadAndReplace(
        type: 'user',
        url: info.downloadUrl,
        expectedChecksum: info.checksum,
        newVersion: info.version,
      );
    } catch (_) {
      // 静默失败：未初始化、网络异常等均不阻塞登录
    }
  }

  /// 退登前调用：推送积压 → 清空 user.db + sync_queue
  Future<void> onLogout() async {
    try {
      await pushNow();
    } catch (_) {
      // 无网络则跳过，不清 queue（下次启动自动重推）
    }
    try {
      await _dbProvider!.clearUserDb();
      await clearQueue();
    } catch (_) {
      // 未初始化则跳过
    }
  }

  /// 手动强制拉取（关于页按钮用）
  Future<void> forcePull() async {
    _ensureInitialized();
    final info = await _api!.fetchUserPullInfo();
    await _updateManager!.downloadAndReplace(
      type: 'user',
      url: info.downloadUrl,
      expectedChecksum: info.checksum,
      newVersion: info.version,
    );
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('SyncManager not initialized. Call init() first.');
    }
  }
}
