import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;
import '../database/database_provider.dart';
import 'package:shared/debug/audit_logger.dart';

/// 同步队列数据访问层（user 库）
class SyncQueueDao {
  final DatabaseProvider _provider;
  SyncQueueDao(this._provider);
  db.AppDatabase get _db => _provider.appDb;

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
      status: const Value('pending'),
      createdAt: Value(now),
    ));
  }

  Future<List<db.SyncQueueRow>> getPending({int limit = 20}) async {
    final q = _db.select(_db.syncQueue)
      ..where((t) => t.status.isIn(['pending', 'inProgress', 'failed']));
    q.orderBy([(t) => OrderingTerm(expression: t.id)]);
    q.limit(limit);
    final rows = await q.get();
    AuditLogger.instance.dao('SyncQueueDao.getPending', rows.length, {'limit': limit});
    return rows;
  }

  Future<void> markInProgress(int id) async {
    final q = _db.update(_db.syncQueue)..where((t) => t.id.equals(id));
    await q.write(db.SyncQueueCompanion(status: const Value('inProgress')));
  }

  /// 标记成功，携带 serverId 写回
  Future<void> markSuccess(int id, {int? serverId}) async {
    final q = _db.update(_db.syncQueue)..where((t) => t.id.equals(id));
    await q.write(db.SyncQueueCompanion(
      status: const Value('done'),
      serverId: Value(serverId),
    ));
  }

  /// 标记失败，附带错误信息
  Future<void> markFailed(int id, {String? errorMessage}) async {
    final existing = await (_db.select(_db.syncQueue)
      ..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) return;
    final q = _db.update(_db.syncQueue)..where((t) => t.id.equals(id));
    await q.write(db.SyncQueueCompanion(
      status: const Value('failed'),
      retryCount: Value(existing.retryCount + 1),
      errorMessage: Value(errorMessage),
    ));
  }

  /// 将单条记录标记为永久失败
  Future<void> markPermanentFailure(int id) async {
    final q = _db.update(_db.syncQueue)..where((t) => t.id.equals(id));
    await q.write(db.SyncQueueCompanion(status: const Value('permanentFailure')));
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

  /// 清理：删除 7 天前的 done 和过期的 permanentFailure
  Future<void> cleanup() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    await (_db.delete(_db.syncQueue)
      ..where((t) =>
        (t.status.equals('done') & t.createdAt.isSmallerThanValue(sevenDaysAgo)) |
        (t.status.equals('permanentFailure') & t.createdAt.isSmallerThanValue(sevenDaysAgo))))
      .go();
  }

  Future<void> clearAll() async {
    await _db.delete(_db.syncQueue).go();
  }

  Future<int> getFailedCount() async {
    final rows = await (_db.select(_db.syncQueue)
      ..where((t) => t.status.isIn(['failed', 'permanentFailure']))).get();
    AuditLogger.instance.dao('SyncQueueDao.getFailedCount', rows.length, {});
    return rows.length;
  }

  Future<bool> isEmpty() async {
    final rows = await _db.select(_db.syncQueue).get();
    AuditLogger.instance.dao('SyncQueueDao.isEmpty', rows.length, {});
    return rows.isEmpty;
  }

  Future<int> getPendingCount() async {
    final rows = await (_db.select(_db.syncQueue)
      ..where((t) => t.status.isIn(['pending', 'inProgress', 'failed']))).get();
    AuditLogger.instance.dao('SyncQueueDao.getPendingCount', rows.length, {});
    return rows.length;
  }

  Future<bool> hasFailed() async {
    final rows = await (_db.select(_db.syncQueue)
      ..where((t) => t.status.isIn(['failed', 'permanentFailure']))).get();
    AuditLogger.instance.dao('SyncQueueDao.hasFailed', rows.length, {});
    return rows.isNotEmpty;
  }

  /// 获取最新上传日期（最近完成的 sync 记录）
  Future<DateTime?> getLatestUploadDate() async {
    final rows = await (_db.select(_db.syncQueue)
      ..where((t) => t.status.equals('done'))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
      ..limit(1)
    ).get();
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first.createdAt);
  }

  /// 重置所有 failed 项为 pending（重试计数归零）
  Future<void> resetFailed() async {
    final rows = await (_db.select(_db.syncQueue)
      ..where((t) => t.status.equals('failed'))).get();
    for (final row in rows) {
      final q = _db.update(_db.syncQueue)..where((t) => t.id.equals(row.id));
      await q.write(db.SyncQueueCompanion(
        status: const Value('pending'),
        retryCount: const Value(0),
      ));
    }
  }
}
