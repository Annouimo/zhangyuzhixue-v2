import 'dart:convert';
import '../daos/sync_queue_dao.dart';
import '../api/sync_api.dart';
import '../network/connectivity_monitor.dart';
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
    // 离线时跳过推送
    if (!ConnectivityMonitor().isOnline) {
      AuditLogger.instance.sync('push_offline', {'skip': true});
      return PushSummary(successCount: 0, failCount: 0);
    }

    var success = 0;
    var fail = 0;

    while (true) {
      // 每批推送前检查网络状态
      if (!ConnectivityMonitor().isOnline) {
        AuditLogger.instance.sync('push_offline', {'skip_remaining': true});
        break;
      }

      final batch = await _dao.getPending(limit: batchSize);
      if (batch.isEmpty) break;

      for (final entry in batch) {
        await _dao.markInProgress(entry.id);
      }

      final items = batch.map((e) => <String, dynamic>{
        'entity_type': e.entityType,
        'local_id': e.entityId,
        'data': jsonDecode(e.payload),
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
      } catch (e) {
        AuditLogger.instance.error('SyncPusher.pushAll', e);
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
