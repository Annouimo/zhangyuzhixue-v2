/// 章鱼智学 — SyncRepository
/// 对应页面：sync_queue.html, profile.html（副标题状态）
/// data-db: sync.*

class SyncQueueItem {
  /// 实体类型：submissionDetail / stepFeedback / cardFeedback / rating / exam
  final String entityType;

  /// 界面用中文名
  final String entityTypeName;

  /// 图标 emoji
  final String icon;

  /// 状态：pending / inProgress / failed / permanentFailure
  final String status;

  /// 创建时间（ISO 字符串）
  final String createdAt;

  /// 界面用相对时间
  final String timeAgo;

  /// 已重试次数
  final int retryCount;

  const SyncQueueItem({
    required this.entityType,
    required this.entityTypeName,
    required this.icon,
    required this.status,
    required this.createdAt,
    required this.timeAgo,
    required this.retryCount,
  });

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
        entityType: json['entity_type'] as String,
        entityTypeName: json['entity_type_name'] as String,
        icon: json['icon'] as String? ?? '📝',
        status: json['status'] as String,
        createdAt: json['created_at'] as String,
        timeAgo: json['time_ago'] as String,
        retryCount: json['retry_count'] as int? ?? 0,
      );
}

class SyncRepository {
  /// 获取同步队列中所有待同步/失败/进行中的记录
  /// GET /api/sync/queue/
  static Future<List<SyncQueueItem>> getQueue() async {
    throw UnimplementedError('SyncRepository.getQueue');
  }

  /// 是否有同步失败的记录（供 profile.html 副标题判断）
  static Future<int> getFailedCount() async {
    throw UnimplementedError('SyncRepository.getFailedCount');
  }

  /// 同步队列是否为空（全部已同步）
  static Future<bool> isEmpty() async {
    throw UnimplementedError('SyncRepository.isEmpty');
  }

  /// 是否有失败记录（供按钮显示判断）
  static Future<bool> hasFailed() async {
    throw UnimplementedError('SyncRepository.hasFailed');
  }

  /// 全部重试：重新推送所有 failed 状态的记录
  /// POST /api/sync/retry-all/
  /// 实际触发 SyncManager().pushNow() 重推失败项
  static Future<void> retryAll() async {
    throw UnimplementedError('SyncRepository.retryAll');
  }
}
