import '../daos/sync_queue_dao.dart';
import '../api/sync_api.dart';
import 'package:flutter_app/data/debug/audit_logger.dart';

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

  /// 推送所有待同步数据，逐批处理，逐条处理 server_ids
  Future<PushSummary> pushAll() async {
    var success = 0;
    var fail = 0;

    while (true) {
      final batch = await _dao.getPending(limit: batchSize);
      if (batch.isEmpty) break;

      for (final entry in batch) {
        await _dao.markInProgress(entry.id);
      }

      final items = batch.map((e) => {
        'entity_type': e.entityType,
        'operation': e.operationType,
        'local_id': e.entityId,
        'payload': e.payload,
      }).toList();

      try {
        final result = await _api.pushBatch(items);
        // 逐条查 server_ids 映射：有的→成功，没有的→失败
        for (final entry in batch) {
          final sid = result.serverIds[entry.entityId];
          await _dao.markSuccess(entry.id, serverId: sid);
          if (sid != null) {
            success++;
          } else {
            fail++;
          }
        }
      } catch (_) {
        for (final entry in batch) {
          await _dao.markFailed(entry.id);
          fail++;
        }
        break;
      }
    }

    await _dao.markPermanentFailures(maxRetries);
    await _dao.cleanup();

    AuditLogger.instance.sync('push', {'success': success, 'fail': fail, 'batchSize': batchSize});

    return PushSummary(successCount: success, failCount: fail);
  }
}
