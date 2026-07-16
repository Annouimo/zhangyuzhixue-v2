import '../daos/sync_queue_dao.dart';
import '../api/sync_api.dart';
import '../database/database_provider.dart';
import 'sync_types.dart';
import 'sync_pusher.dart';
import 'update_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/data/debug/audit_logger.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../prefs/app_prefs.dart';
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
      entityType: entityType.serverName,
      operationType: operation.name,
      entityId: localId,
      payload: payload,
    );
    // 入队后自动尝试推送（pushNow 自带 30 秒冷却，不会过度推送）
    try {
      await pushNow();
    } catch (_) {
      // 推送失败静默处理，队列项目保持 pending，下次推送机会再试
    }
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
    } catch (e) {
      AuditLogger.instance.error('SyncManager.onAppStart', e);
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
    if (type == 'user') {
      // 用户数据更新：运行时调 fetchUserPullInfo 获取下载信息
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
    AuditLogger.instance.sync('pushAll', {'success': summary.successCount, 'fail': summary.failCount});
    return summary;
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
  Future<void> onLogin({
    void Function(double progress)? onProgress,
  }) async {
    try {
      final summary = await pushNow();
      final info = await _api!.fetchUserPullInfo();

      // 备份当前 user.db（替换前，用于下载失败时回滚）
      await _dbProvider!.backupUserDb(_currentUserIdentity);

      try {
        await _updateManager!.downloadAndReplace(
          type: 'user',
          url: info.downloadUrl,
          expectedChecksum: info.checksum,
          newVersion: info.version,
          onProgress: onProgress,
        );
        // 下载成功 → 删备份
        await _dbProvider!.deleteUserDbBackup();
        await AppPrefs().setLastSyncTime(DateTime.now().toIso8601String());
      } catch (e) {
        // 下载失败 → 尝试恢复备份
        final restored = await _dbProvider!.restoreUserDb(_currentUserIdentity);
        if (!restored) {
          // 身份不匹配或无备份 → 清空 user.db 防止残留旧数据
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
      // 失败由 UI 层弹窗展示
      rethrow;
    }
  }

  /// 退登前调用：推送积压 → 清空 user.db + sync_queue
  Future<void> onLogout() async {
    try {
      await pushNow();
    } catch (e) {
      AuditLogger.instance.error('SyncManager.onLogout_pending', e);
      // 无网络则跳过，不清 queue（下次启动自动重推）
    }
    try {
      await clearQueue();
    } catch (e) {
      AuditLogger.instance.error('SyncManager.onLogout_clear', e);
      // 未初始化则跳过
    }
  }

  /// 手动强制拉取（关于页按钮用）
  Future<void> forcePull({
    void Function(double progress)? onProgress,
  }) async {
    _ensureInitialized();
    try {
      await pushNow();
    } catch (_) {
      // 推送失败不阻塞强制拉取
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

  /// 重置单例状态（仅测试用）
  @visibleForTesting
  static Future<void> resetForTesting() async {
    _instance._queueDao = null;
    _instance._pusher = null;
    _instance._updateManager = null;
    _instance._api = null;
    _instance._dbProvider = null;
    _instance._initialized = false;
    _instance._lastPushTime = DateTime(2000);
    _instance._pendingUpdates = [];
  }
}
