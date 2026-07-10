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
    final q = _db.select(_db.syncQueue)
      ..where((t) => t.status.isIn(['pending', 'inProgress']));
    q.orderBy([(t) => OrderingTerm(expression: t.id)]);
    q.limit(limit);
    return q.get();
  }

  Future<void> markInProgress(int id) async {
    final q = _db.update(_db.syncQueue)..where((t) => t.id.equals(id));
    await q.write(db.SyncQueueCompanion(status: Value('inProgress')));
  }

  Future<void> markSuccess(int id) async {
    final q = _db.delete(_db.syncQueue)..where((t) => t.id.equals(id));
    await q.go();
  }

  /// 清理：删除已 done 和过期的永久失败记录（保留 7 天）
  Future<void> cleanup() async {
    final all = await _db.select(_db.syncQueue).get();
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    for (final row in all) {
      if (row.status == 'done' || (row.status == 'permanentFailure' && row.createdAt.compareTo(sevenDaysAgo) < 0)) {
        final q = _db.delete(_db.syncQueue)..where((t) => t.id.equals(row.id));
        await q.go();
      }
    }
  }

  /// 将超过最大重试次数的 failed 标记为 permanentFailure
  Future<void> markPermanentFailures(int maxRetries) async {
    final rows = await (_db.select(_db.syncQueue)
      ..where((t) => t.status.equals('failed'))).get();
    for (final row in rows) {
      if (row.retryCount >= maxRetries) {
        final q = _db.update(_db.syncQueue)..where((t) => t.id.equals(row.id));
        await q.write(db.SyncQueueCompanion(status: const Value('permanentFailure')));
      }
    }
  }

  Future<void> markFailed(int id) async {
    final existing = await (_db.select(_db.syncQueue)
      ..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) return;
    final q = _db.update(_db.syncQueue)..where((t) => t.id.equals(id));
    await q.write(db.SyncQueueCompanion(
      status: Value('failed'),
      retryCount: Value(existing.retryCount + 1),
    ));
  }

  Future<void> clearAll() async {
    await _db.delete(_db.syncQueue).go();
  }

  Future<int> getFailedCount() async {
    final rows = await (_db.select(_db.syncQueue)
      ..where((t) => t.status.isIn(['failed', 'permanentFailure']))).get();
    return rows.length;
  }

  Future<bool> isEmpty() async {
    final rows = await _db.select(_db.syncQueue).get();
    return rows.isEmpty;
  }

  Future<bool> hasFailed() async {
    final rows = await (_db.select(_db.syncQueue)
      ..where((t) => t.status.isIn(['failed', 'permanentFailure']))).get();
    return rows.isNotEmpty;
  }
}
