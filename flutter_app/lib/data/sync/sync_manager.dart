import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared/debug/audit_logger.dart';
import '../api/sync_api.dart';
import '../daos/sync_queue_dao.dart';
import '../database/database_provider.dart';
import '../prefs/app_prefs.dart';
import 'sync_pusher.dart';
import 'sync_types.dart';
import 'update_manager.dart';

class PendingSyncException implements Exception {
  const PendingSyncException(this.count);
  final int count;

  @override
  String toString() => '仍有 $count 条本地数据尚未同步';
}

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
  final Set<String> _backgroundUpdatesInFlight = <String>{};

  /// 并发锁 — 防止 pushNow 重叠（定时器 tick 和主动调用之间）
  bool _pushing = false;

  /// 后台重试定时器（30 秒间隔，首次 enqueue 启动，队列空后停止）
  Timer? _retryTimer;

  /// 最近一次版本检查中需要用户操作的更新项
  List<UpdateSummary> _pendingUpdates = [];

  /// 上次版本检查是否因网络/连接错误失败。若不为 null 则包含错误原因。
  String? lastCheckError;

  Future<void> init(
    SyncQueueDao queueDao,
    SyncApi api,
    DatabaseProvider dbProvider,
  ) async {
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

  /// 入队后立即尝试推送，并确保后台定时器已启动
  Future<void> enqueue({
    required SyncEntityType entityType,
    required SyncOperationType operation,
    required int localId,
    required String payload,
  }) async {
    _ensureInitialized();
    await _queueDao!.enqueue(
      entityType: entityType.serverName,
      operationType: operation.name,
      entityId: localId,
      payload: payload,
    );
    _ensureRetryTimer();
    try {
      await pushNow();
    } catch (_) {
      // 推送失败静默处理，定时器会在 30s 后自动重试
    }
  }

  /// Writes an outbox entry without starting network work. Call this inside
  /// the same database transaction as the business mutation.
  Future<int> addToOutbox({
    required SyncEntityType entityType,
    required SyncOperationType operation,
    required int localId,
    required String payload,
  }) async {
    _ensureInitialized();
    return _queueDao!.enqueue(
      entityType: entityType.serverName,
      operationType: operation.name,
      entityId: localId,
      payload: payload,
    );
  }

  /// Starts best-effort delivery after the surrounding local transaction has
  /// committed. The durable outbox entry already exists at this point.
  void scheduleOutboxPush() {
    _ensureInitialized();
    _ensureRetryTimer();
    unawaited(pushNow());
  }

  /// App 启动时推送积压并发起版本检查
  ///
  /// 返回需要用户操作的更新项（force 弹窗 / banner 提示）。
  /// 调用方可据此展示更新 UI。
  Future<List<UpdateSummary>> onAppStart() async {
    _ensureInitialized();
    // 启动后台定时器兜底重试
    _ensureRetryTimer();
    await pushNow();
    try {
      return await checkUpdates();
    } catch (e) {
      AuditLogger.instance.error('SyncManager.onAppStart', e);
      lastCheckError = '版本检查失败: $e';
      _pendingUpdates = [];
      return [];
    }
  }

  /// 检查并登记可执行的数据更新。
  ///
  /// 启动流程和关于页必须共用此入口，避免界面显示了更新但执行器没有
  /// 对应的下载元数据。
  Future<List<UpdateSummary>> checkUpdates() async {
    _ensureInitialized();
    final results = await _updateManager!.checkAll();
    _pendingUpdates = results
        .where((s) => s.hasUpdate && !s.checkFailed)
        .toList();
    final failures = results.where((s) => s.checkFailed).toList();
    lastCheckError = failures.isEmpty
        ? null
        : '${failures.map((item) => item.type).join('、')}版本检查失败';
    if (failures.isEmpty) {
      await AppPrefs().setLastVersionCheckTime(DateTime.now());
    }
    return List.unmodifiable(results);
  }

  /// 前台高频检查仅查询用户数据版本，不下载或替换数据库。
  Future<UpdateSummary> checkUserUpdate() async {
    _ensureInitialized();
    final result = await _updateManager!.checkUser();
    _pendingUpdates.removeWhere((item) => item.type == 'user');
    if (!result.checkFailed && result.hasUpdate) {
      _pendingUpdates.add(result);
    }
    lastCheckError = result.checkFailed ? 'user版本检查失败' : null;
    return result;
  }

  /// 执行指定类型的数据库更新（下载 → 校验 → 替换）
  Future<void> runUpdate(
    String type, {
    void Function(double progress)? onProgress,
  }) async {
    _ensureInitialized();
    if (type == 'user') {
      await _ensureOutboxDrained();
      final info = await _api!.fetchUserPullInfo();
      await _dbProvider!.backupUserDb(_currentUserIdentity);
      try {
        await _updateManager!.downloadAndReplace(
          type: type,
          url: info.downloadUrl,
          expectedChecksum: info.checksum,
          newVersion: info.version,
          onProgress: onProgress,
        );
        await _dbProvider!.deleteUserDbBackup();
        await AppPrefs().setLastSyncTime(DateTime.now().toIso8601String());
      } catch (e) {
        final restored = await _dbProvider!.restoreUserDb(_currentUserIdentity);
        if (!restored) {
          await _dbProvider!.clearUserDb();
          await AppPrefs().setUserVersion(0);
        }
        rethrow;
      }
      _pendingUpdates.removeWhere((s) => s.type == type);
      return;
    }
    final pending = _pendingUpdates.where((s) => s.type == type).toList();
    if (pending.isEmpty) {
      throw StateError('No pending update for type: $type');
    }
    final summary = pending.first;
    if (!summary.canDownload) {
      throw StateError('$type update metadata is incomplete');
    }
    await _updateManager!.downloadAndReplace(
      type: type,
      url: summary.downloadUrl!,
      expectedChecksum: summary.checksum!,
      newVersion: summary.serverVersion,
      onProgress: onProgress,
    );
    _pendingUpdates.removeWhere((s) => s.type == type);
  }

  /// Runs an ordinary update without UI. Duplicate requests for the same
  /// database share the in-flight operation and return immediately.
  Future<bool> runBackgroundUpdate(UpdateSummary summary) async {
    _ensureInitialized();
    if (!UpdateManager.shouldUpdateSilently(summary)) return false;
    if (!_backgroundUpdatesInFlight.add(summary.type)) return false;
    try {
      await runUpdate(summary.type);
      return true;
    } finally {
      _backgroundUpdatesInFlight.remove(summary.type);
    }
  }

  /// 立即推送所有待同步数据。
  /// 并发锁：[_pushing] 防止重叠调用，重叠时返回 null。
  Future<PushSummary?> pushNow() async {
    _ensureInitialized();
    if (_pushing) return null;
    _pushing = true;
    try {
      final summary = await _pusher!.pushAll();

      if (summary.batchesPushed > 0) {
        final authoritativeVersion = summary.serverDataVersion;
        if (authoritativeVersion != null) {
          await AppPrefs().setUserVersion(authoritativeVersion);
        } else {
          // Backward compatibility while older servers are still deployed.
          final current = AppPrefs().userVersion;
          await AppPrefs().setUserVersion(current + summary.batchesPushed);
        }
        await AppPrefs().setLastSyncTime(DateTime.now().toIso8601String());
      }

      AuditLogger.instance.sync('pushAll', {
        'success': summary.successCount,
        'fail': summary.failCount,
        'batchesPushed': summary.batchesPushed,
      });
      return summary;
    } finally {
      _pushing = false;
    }
  }

  /// 启动后台定时器：每 30 秒巡查一次，队列空则自动停止。
  /// 首次 enqueue 或 onAppStart 时调用，可重入。
  void _ensureRetryTimer() {
    if (_retryTimer != null) return;
    _retryTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _onTimerTick(),
    );
    AuditLogger.instance.sync('retry_timer', {'action': 'started'});
  }

  Future<void> _onTimerTick() async {
    if (_pushing) return;
    await pushNow();

    // 队列空 → 停掉定时器，避免空转
    if (_queueDao == null) return;
    try {
      final remaining = await _queueDao!.getPendingCount();
      if (remaining == 0 && _retryTimer != null) {
        _retryTimer!.cancel();
        _retryTimer = null;
        AuditLogger.instance.sync('retry_timer', {'action': 'stopped_empty'});
      }
    } catch (_) {
      // 查询失败不中断
    }
  }

  Future<void> clearQueue() async {
    _ensureInitialized();
    await _queueDao!.clearAll();
  }

  /// 登录时使用的用户身份标识（refresh token 的 hash，稳定可跨 session 校验）
  String get _currentUserIdentity {
    final token = AppPrefs().refreshToken ?? '';
    return sha256.convert(utf8.encode(token)).toString();
  }

  /// 登录后调用：推送积压 → 备份当前 user.db → 拉取并替换 → 成功后清理备份
  Future<void> onLogin({void Function(double progress)? onProgress}) async {
    try {
      final summary = await _ensureOutboxDrained();
      final info = await _api!.fetchUserPullInfo();

      await _dbProvider!.backupUserDb(_currentUserIdentity);

      try {
        await _updateManager!.downloadAndReplace(
          type: 'user',
          url: info.downloadUrl,
          expectedChecksum: info.checksum,
          newVersion: info.version,
          onProgress: onProgress,
        );
        await _dbProvider!.deleteUserDbBackup();
        await AppPrefs().setLastSyncTime(DateTime.now().toIso8601String());
      } catch (e) {
        final restored = await _dbProvider!.restoreUserDb(_currentUserIdentity);
        if (!restored) {
          await _dbProvider!.clearUserDb();
          await AppPrefs().setUserVersion(0);
        }
        rethrow;
      }

      AuditLogger.instance.sync('syncAll', {
        'pushSuccess': summary?.successCount ?? 0,
        'pushFail': summary?.failCount ?? 0,
        'pullType': 'user',
      });
    } catch (e) {
      AuditLogger.instance.error('SyncManager.onLogin', e);
      rethrow;
    }
  }

  /// 退登前调用：推送积压 → 停定时器 → 清空 sync_queue
  Future<void> onLogout() async {
    // 停定时器，避免 logout 后还在尝试推送
    _retryTimer?.cancel();
    _retryTimer = null;
    _pushing = false;

    try {
      await pushNow();
    } catch (e) {
      AuditLogger.instance.error('SyncManager.onLogout_pending', e);
    }
    try {
      await clearQueue();
    } catch (e) {
      AuditLogger.instance.error('SyncManager.onLogout_clear', e);
    }
  }

  /// 手动强制拉取（关于页按钮用）
  Future<void> forcePull({
    void Function(double progress)? onProgress,
    bool discardPending = false,
  }) async {
    _ensureInitialized();
    if (!discardPending) {
      await _ensureOutboxDrained();
    }
    final info = await _api!.fetchUserPullInfo();

    await _dbProvider!.backupUserDb(_currentUserIdentity);

    try {
      await _updateManager!.downloadAndReplace(
        type: 'user',
        url: info.downloadUrl,
        expectedChecksum: info.checksum,
        newVersion: info.version,
        onProgress: onProgress,
      );
      await _dbProvider!.deleteUserDbBackup();
      await AppPrefs().setLastSyncTime(DateTime.now().toIso8601String());
    } catch (e) {
      final restored = await _dbProvider!.restoreUserDb(_currentUserIdentity);
      if (!restored) {
        await _dbProvider!.clearUserDb();
        await AppPrefs().setUserVersion(0);
      }
      rethrow;
    }
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('SyncManager not initialized. Call init() first.');
    }
  }

  Future<PushSummary?> _ensureOutboxDrained() async {
    final summary = await pushNow();
    final remaining = await _queueDao!.getUnresolvedCount();
    if (remaining > 0) throw PendingSyncException(remaining);
    return summary;
  }

  /// 重置单例状态（仅测试用）
  @visibleForTesting
  static Future<void> resetForTesting() async {
    _instance._retryTimer?.cancel();
    _instance._retryTimer = null;
    _instance._pushing = false;
    _instance._queueDao = null;
    _instance._pusher = null;
    _instance._updateManager = null;
    _instance._api = null;
    _instance._dbProvider = null;
    _instance._initialized = false;
    _instance._backgroundUpdatesInFlight.clear();
    _instance._pendingUpdates = [];
  }
}
