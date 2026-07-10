import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;

/// 同步队列数据访问层（user 库）
class SyncQueueDao {
  final db.AppDatabase _db;
  const SyncQueueDao(this._db);

  Future<int> enqueue({
    required String entityType,
    required String operationType,
    required int entityId,
    required String payload,
  }) async {
    final now = DateTime.now().toIso8601String();
    return _db.into(_db.syncQueue).insert(db.SyncQueueCompanion(
      entityType: Value(entityType),
      operationType: Value(operationType),
      entityId: Value(entityId),
      payload: Value(payload),
      status: Value('pending'),
      createdAt: Value(now),
    ));
  }

  Future<List<db.SyncQueueRow>> getPending({int limit = 20}) async {
    final rows = await _db.customSelect(
      "SELECT * FROM sync_queue WHERE status IN ('pending', 'inProgress') ORDER BY id LIMIT ?",
      variables: [Variable(limit)],
      readsFrom: {_db.syncQueue},
    ).get();
    return rows.map((r) => _db.syncQueue.map(r.data)).toList();
  }

  Future<void> markInProgress(int id) async {
    await _db.customUpdate(
      'UPDATE sync_queue SET status = ? WHERE id = ?',
      variables: [Variable('inProgress'), Variable(id)],
    );
  }

  Future<void> markSuccess(int id) async {
    await _db.customUpdate('DELETE FROM sync_queue WHERE id = ?', variables: [Variable(id)]);
  }

  Future<void> markFailed(int id) async {
    await _db.customUpdate(
      'UPDATE sync_queue SET status = ?, retry_count = retry_count + 1 WHERE id = ?',
      variables: [Variable('failed'), Variable(id)],
    );
  }

  Future<void> clearAll() async {
    await _db.customUpdate('DELETE FROM sync_queue');
  }

  Future<void> cleanup() async {
    // 清理 done 和过期永久失败
    await _db.customUpdate("DELETE FROM sync_queue WHERE status = 'done'");
    await _db.customUpdate(
      "DELETE FROM sync_queue WHERE status = 'permanentFailure' AND created_at < datetime('now', '-7 days')",
    );
    // failed 超次数 → permanentFailure
    await _db.customUpdate(
      "UPDATE sync_queue SET status = 'permanentFailure' WHERE status = 'failed' AND retry_count >= 5",
    );
  }

  Future<int> getFailedCount() async {
    final row = await _db.customSelect(
      "SELECT COUNT(*) AS c FROM sync_queue WHERE status = 'failed' OR status = 'permanentFailure'",
      readsFrom: {_db.syncQueue},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<bool> isEmpty() async {
    final rows = await _db.customSelect(
      'SELECT 1 FROM sync_queue LIMIT 1',
      readsFrom: {_db.syncQueue},
    ).get();
    return rows.isEmpty;
  }

  Future<bool> hasFailed() async {
    final rows = await _db.customSelect(
      "SELECT 1 FROM sync_queue WHERE status IN ('failed', 'permanentFailure') LIMIT 1",
      readsFrom: {_db.syncQueue},
    ).get();
    return rows.isNotEmpty;
  }
}
