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
  bool _initialized = false;
  DateTime _lastPushTime = DateTime(2000);

  Future<void> init(SyncQueueDao queueDao, SyncApi api, DatabaseProvider dbProvider) async {
    if (_initialized) return;
    _queueDao = queueDao;
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

  /// App 启动时推送积压（版本检查由 UI 层调 UpdateManager）
  Future<void> onAppStart() async {
    _ensureInitialized();
    await pushNow();
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

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('SyncManager not initialized. Call init() first.');
    }
  }
}
