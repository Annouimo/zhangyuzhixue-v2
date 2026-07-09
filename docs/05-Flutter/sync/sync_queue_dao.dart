/// 章鱼智学 — 同步队列表 DAO
///
/// 本文件定义 sync_queue 表的数据访问层。
/// 提供入队、出队、标记状态等操作方法。
///
/// 定稿后对接工作：
/// - 将本文件中的 SyncQueueEntry 替换为 drift 生成的 DataClass
/// - 传入真正的 Database 实例（而非抽象的存储接口）

/// ──────────────────────────────────────────────
/// 队列存储接口（占位）
///
/// 定稿后替换为实际的 Drift DAO 实现。
/// 当前仅用于阐明 sync_queue_dao 需要哪些 DB 操作。
/// ──────────────────────────────────────────────

/// sync_queue 表需要支持的数据库操作
///
/// 定稿后对接：在 database/tables/sync_tables.dart 中定义 SyncQueuesTable，
/// 在 database/daos/ 中创建 SyncQueueDao 实现此接口。
abstract class SyncQueueStore {
  /// 插入一条新记录，返回自增 ID
  Future<int> insert({
    required String entityType,
    required String operationType,
    required int localId,
    required String payload,
    required String status,
    required DateTime createdAt,
  });

  /// 查询待推送的记录（按创建时间正序，限制条数）
  Future<List<FetchedQueueRow>> getPending({required int limit});

  /// 更新状态为 in_progress
  Future<void> markInProgress(int id);

  /// 标记成功：写入 serverId，删除记录
  Future<void> markSuccess(int id, int serverId);

  /// 标记失败：增加重试次数
  Future<void> markFailed(int id);

  /// 清空所有记录（登出时调用）
  Future<void> clearAll();

  /// 清理已成功或过期的记录
  Future<void> cleanup();
}

/// 从数据库查出的原始行（占位）
///
/// 定稿后替换为 drift 生成的 SyncQueue 数据类。
class FetchedQueueRow {
  final int id;
  final String entityType;
  final String operationType;
  final int localId;
  final int? serverId;
  final String payload; // JSON 字符串
  final String status;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastAttempt;

  const FetchedQueueRow({
    required this.id,
    required this.entityType,
    required this.operationType,
    required this.localId,
    this.serverId,
    required this.payload,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    this.lastAttempt,
  });
}

/// ──────────────────────────────────────────────
/// SyncQueueDao
/// ──────────────────────────────────────────────

/// 同步队列的数据访问层
///
/// 职责：封装队列表的所有读写操作。
/// Repository 层不直接调用此 DAO，而是通过 SyncManager.enqueue() 写入。
class SyncQueueDao {
  final SyncQueueStore _store;

  SyncQueueDao(this._store);

  /// 入队：追加一条待同步记录
  Future<int> enqueue({
    required String entityType,
    required String operationType,
    required int localId,
    required Map<String, dynamic> payload,
  }) async {
    return _store.insert(
      entityType: entityType,
      operationType: operationType,
      localId: localId,
      payload: encodePayload(payload),
      status: 'pending',
      createdAt: DateTime.now(),
    );
  }

  /// 获取下一批待推送记录
  Future<List<SyncQueueEntry>> getPending({int limit = 20}) async {
    final rows = await _store.getPending(limit: limit);
    return rows.map(_toEntry).toList();
  }

  /// 标记为正在推送
  Future<void> markInProgress(int id) => _store.markInProgress(id);

  /// 标记成功
  Future<void> markSuccess(int id, int serverId) =>
      _store.markSuccess(id, serverId);

  /// 标记失败
  Future<void> markFailed(int id) => _store.markFailed(id);

  /// 清空队列
  Future<void> clearAll() => _store.clearAll();

  /// 清理
  Future<void> cleanup() => _store.cleanup();

  // ── 辅助方法 ──

  Map<String, dynamic> decodePayload(String raw) => Map<String, dynamic>.from(
        // 定稿后替换为: jsonDecode(raw) as Map<String, dynamic>
        {},
      );

  String encodePayload(Map<String, dynamic> data) =>
      // 定稿后替换为: jsonEncode(data)
      data.toString();

  SyncQueueEntry _toEntry(FetchedQueueRow row) => SyncQueueEntry(
        id: row.id,
        entityType: SyncEntityType.values.firstWhere(
          (e) => e.name == row.entityType,
        ),
        operationType: SyncOperationType.values.firstWhere(
          (e) => e.name == row.operationType,
        ),
        localId: row.localId,
        serverId: row.serverId,
        payload: decodePayload(row.payload),
        status: SyncStatus.values.firstWhere((s) => s.name == row.status),
        retryCount: row.retryCount,
        createdAt: row.createdAt,
        lastAttempt: row.lastAttempt,
      );
}
