import '../daos/sync_queue_dao.dart';
import '../api/sync_api.dart';
import '../database/database_provider.dart';
import 'sync_types.dart';
import 'sync_pusher.dart';
import 'update_manager.dart';
import 'package:flutter_app/data/debug/audit_logger.dart';

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

  /// 最近一次版本检查中需要用户操作的更新项
  List<UpdateSummary> _pendingUpdates = [];

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

  /// 待处理的更新项（force 或 banner）
  List<UpdateSummary> get pendingUpdates => List.unmodifiable(_pendingUpdates);

  bool get hasPendingUpdates => _pendingUpdates.isNotEmpty;

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
  ///
  /// 返回需要用户操作的更新项（force 弹窗 / banner 提示）。
  /// 调用方可据此展示更新 UI。
  Future<List<UpdateSummary>> onAppStart() async {
    _ensureInitialized();
    await pushNow();
    try {
      final results = await _updateManager!.checkAll();
      _pendingUpdates = results.where((s) =>
        s.forceUpdate || UpdateManager.shouldShowBanner(
          localVersion: s.localVersion,
          serverVersion: s.serverVersion,
        )
      ).toList();
      return List.unmodifiable(_pendingUpdates);
    } catch (_) {
      _pendingUpdates = [];
      return [];
    }
  }

  /// 执行指定类型的数据库更新（下载 → 校验 → 替换）
  Future<void> runUpdate(
    String type, {
    void Function(double progress)? onProgress,
  }) async {
    _ensureInitialized();
    final pending = _pendingUpdates.where((s) => s.type == type).toList();
    if (pending.isEmpty) {
      throw StateError('No pending update for type: $type');
    }
    final summary = pending.first;
    await _updateManager!.downloadAndReplace(
      type: type,
      url: summary.downloadUrl!,
      expectedChecksum: summary.checksum!,
      newVersion: summary.serverVersion,
      onProgress: onProgress,
    );
    // 替换成功后从待处理列表中移除
    _pendingUpdates.removeWhere((s) => s.type == type);
  }

  Future<PushSummary?> pushNow() async {
    _ensureInitialized();
    final now = DateTime.now();
    if (now.difference(_lastPushTime).inSeconds < 30) return null;
    _lastPushTime = now;
    final summary = await _pusher!.pushAll();
    if (summary != null) {
      AuditLogger.instance.sync('pushAll', {'success': summary.successCount, 'fail': summary.failCount});
    }
    return summary;
  }

  Future<void> clearQueue() async {
    _ensureInitialized();
    await _queueDao!.clearAll();
  }

  /// 登录后调用：推送积压 → 拉取并替换 user.db
  Future<void> onLogin({
    void Function(double progress)? onProgress,
  }) async {
    try {
      await pushNow();
      final info = await _api!.fetchUserPullInfo();
      await _updateManager!.downloadAndReplace(
        type: 'user',
        url: info.downloadUrl,
        expectedChecksum: info.checksum,
        newVersion: info.version,
        onProgress: onProgress,
      );
    } catch (_) {
      // 失败由 UI 层弹窗展示
      rethrow;
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
  Future<void> forcePull({
    void Function(double progress)? onProgress,
  }) async {
    _ensureInitialized();
    final info = await _api!.fetchUserPullInfo();
    await _updateManager!.downloadAndReplace(
      type: 'user',
      url: info.downloadUrl,
      expectedChecksum: info.checksum,
      newVersion: info.version,
      onProgress: onProgress,
    );
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('SyncManager not initialized. Call init() first.');
    }
  }
}
