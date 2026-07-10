import '../daos/sync_queue_dao.dart';
import '../api/sync_api.dart';

/// 推送结果汇总
class PushSummary {
  final int successCount;
  final int failCount;
  final String? message;

  const PushSummary({required this.successCount, required this.failCount, this.message});
}

/// 推送引擎核心
class SyncPusher {
  static const int maxRetries = 5;
  static const int batchSize = 20;

  final SyncQueueDao _dao;
  final SyncApi _api;

  SyncPusher(this._dao, this._api);

  /// 推送所有待同步数据，逐批处理
  Future<PushSummary> pushAll() async {
    var success = 0;
    var fail = 0;

    while (true) {
      // 1. 取一批
      final batch = await _dao.getPending(limit: batchSize);
      if (batch.isEmpty) break;

      // 2. 标记 inProgress
      for (final entry in batch) {
        await _dao.markInProgress(entry.id);
      }

      // 3. 发送到服务器
      final items = batch.map((e) => {
        'entity_type': e.entityType,
        'operation': e.operationType,
        'local_id': e.entityId,
        'payload': e.payload,
      }).toList();

      try {
        await _api.pushBatch(items);

        // 4. 逐条标记成功
        for (final entry in batch) {
          await _dao.markSuccess(entry.id);
          success++;
        }
      } catch (_) {
        // 网络错误：全部标记失败
        for (final entry in batch) {
          await _dao.markFailed(entry.id);
          fail++;
        }
        // 网络失败时停止后续批次
        break;
      }
    }

    // 5. 标记永久失败
    await _dao.markPermanentFailures(maxRetries);

    // 6. 清理
    await _dao.cleanup();

    return PushSummary(successCount: success, failCount: fail);
  }
}
