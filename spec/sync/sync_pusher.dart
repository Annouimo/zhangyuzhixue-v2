/// 章鱼智学 — 推送引擎核心
///
/// 本文件实现从 sync_queue 逐批出队、调用 API 推送、
/// 处理服务器返回结果的完整流程。
///
/// 定稿后对接工作：
/// - 替换 SyncApi 为真实的 api/sync_api.dart 实现
/// - 传入真实的 Dio 或 HTTP 客户端实例

/// ──────────────────────────────────────────────
/// 推送 API 接口（占位）
///
/// 定稿后在 api/sync_api.dart 中实现。
/// ──────────────────────────────────────────────

/// 单条推送请求项，发送给服务器
class PushItem {
  final String entityType;
  final String operation;
  final int localId;
  final Map<String, dynamic> payload;

  const PushItem({
    required this.entityType,
    required this.operation,
    required this.localId,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
        'entity_type': entityType,
        'operation': operation,
        'local_id': localId,
        'payload': payload,
      };
}

/// 同步引擎调用的 API 接口
///
/// 定稿后对接：在 api/sync_api.dart 中实现此接口。
abstract class SyncApiInterface {
  /// 批量推送用户操作数据
  Future<PushBatchResult> pushBatch(List<PushItem> items);

  /// 检查题库版本号
  Future<VersionStatus> checkVersion();
}

/// ──────────────────────────────────────────────
/// SyncPusher
/// ──────────────────────────────────────────────

/// 推送引擎核心
///
/// 职责：
/// 1. 从 SyncQueueDao 取待推送记录
/// 2. 调用 SyncApiInterface 发送到服务器
/// 3. 根据结果标记成功/失败
/// 4. 失败记录自动重试（指数退避）
class SyncPusher {
  /// 最大重试次数（与 sync_types.dart 中的常量保持一致）
  static const int maxRetries = 5;

  /// 单次推送的最大条数
  static const int batchSize = 20;

  final SyncQueueDao _dao;
  final SyncApiInterface _api;

  SyncPusher(this._dao, this._api);

  /// 推送所有待同步数据
  ///
  /// 逐批处理，每批 batchSize 条，直到队列为空或全部失败。
  /// 返回推送结果汇总。
  Future<PushBatchResult> pushAll() async {
    var totalSuccess = 0;
    var totalFail = 0;
    final details = <PushItemResult>[];
    var hasMore = true;

    while (hasMore) {
      // 1. 取一批待推送记录
      final batch = await _dao.getPending(limit: batchSize);
      if (batch.isEmpty) break;

      // 2. 标记 in_progress
      for (final entry in batch) {
        await _dao.markInProgress(entry.id);
      }

      // 3. 发送到服务器
      final PushBatchResult result;
      try {
        result = await _api.pushBatch(
          batch.map((e) => PushItem(
                entityType: e.entityType.name,
                operation: e.operationType.name,
                localId: e.localId,
                payload: e.payload,
              )).toList(),
        );
      } catch (e) {
        // 网络错误：全部标记为失败，留待下次重试
        for (final entry in batch) {
          await _dao.markFailed(entry.id);
          totalFail++;
          details.add(PushItemResult(
            localId: entry.id,
            status: 'error',
            message: 'Network error: $e',
          ));
        }
        // 网络失败时不继续尝试后续批次
        break;
      }

      // 4. 逐条处理服务端返回结果
      for (final itemResult in result.details) {
        if (itemResult.isSuccess) {
          await _dao.markSuccess(itemResult.localId, itemResult.serverId!);
          totalSuccess++;
        } else {
          await _dao.markFailed(itemResult.localId);
          totalFail++;
        }
        details.add(itemResult);
      }

      // 5. 检查是否还有待处理的记录
      hasMore = await _hasMorePending();
    }

    // 6. 清理已完成和过期的记录
    await _dao.cleanup();

    return PushBatchResult(
      successCount: totalSuccess,
      failCount: totalFail,
      details: details,
    );
  }

  /// 检查队列中是否还有待推送的记录
  Future<bool> _hasMorePending() async {
    final remaining = await _dao.getPending(limit: 1);
    return remaining.isNotEmpty;
  }
}
