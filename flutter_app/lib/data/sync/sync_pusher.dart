import 'dart:convert';
import '../daos/sync_queue_dao.dart';
import '../api/sync_api.dart';
import '../api/api_client.dart';
import '../network/connectivity_monitor.dart';
import 'package:drift/drift.dart';
import '../database/database_provider.dart';
import '../database/app_database.dart' as db;
import 'package:shared/debug/audit_logger.dart';

/// 推送结果汇总
class PushSummary {
  final int successCount;
  final int failCount;
  final int batchesPushed;
  final String? message;

  const PushSummary({
    required this.successCount,
    required this.failCount,
    this.batchesPushed = 0,
    this.message,
  });
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
    var batchesPushed = 0;

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

      final items = batch
          .map(
            (e) => <String, dynamic>{
              'entity_type': e.entityType,
              'local_id': e.entityId,
              'data': jsonDecode(e.payload),
            },
          )
          .toList();

      try {
        final result = await _api.pushBatch(items);
        batchesPushed++;
        var hasIncompleteResponse = false;
        // 逐条查 server_ids 映射：有的→成功，没有的→失败
        for (final entry in batch) {
          final sid = result.serverIds[entry.entityId];
          if (sid == null) {
            await _dao.markFailed(
              entry.id,
              errorMessage: 'Server response missing server_id',
            );
            fail++;
            hasIncompleteResponse = true;
            continue;
          }

          await _dao.markSuccess(entry.id, serverId: sid);
          // 写回 server_id 到实体表
          try {
            final db_ = DatabaseProvider();
            if (entry.entityType == 'submission') {
              await (db_.appDb.update(db_.appDb.submissionDetails)
                    ..where((t) => t.id.equals(entry.entityId)))
                  .write(db.SubmissionDetailsCompanion(serverId: Value(sid)));
            } else if (entry.entityType == 'custom_paper') {
              await (db_.appDb.update(db_.appDb.customPapers)
                    ..where((t) => t.id.equals(entry.entityId)))
                  .write(db.CustomPapersCompanion(serverId: Value(sid)));
            }
          } catch (_) {}
          success++;
        }
        // A successful HTTP response with missing IDs is incomplete. Leave the
        // affected items retryable, but do not retry them in a tight loop.
        if (hasIncompleteResponse) break;
      } catch (e) {
        AuditLogger.instance.error('SyncPusher.pushAll', e);
        for (final entry in batch) {
          // 4xx 业务错误 → permanentFailure（不可重试）
          // 网络错误（DioException） → markFailed（可重试）
          if (e is ApiException) {
            await _dao.markPermanentFailure(entry.id);
          } else {
            await _dao.markFailed(entry.id, errorMessage: e.toString());
          }
          fail++;
        }
        // 网络错误时中断后续批次，4xx 不中断
        if (e is! ApiException) break;
      }
    }

    await _dao.markPermanentFailures(maxRetries);
    await _dao.cleanup();

    AuditLogger.instance.sync('push', {
      'success': success,
      'fail': fail,
      'batchSize': batchSize,
    });

    return PushSummary(
      successCount: success,
      failCount: fail,
      batchesPushed: batchesPushed,
    );
  }
}
