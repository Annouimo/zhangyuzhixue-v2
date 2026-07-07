/// 章鱼智学 — SyncRepository
/// data-db: sync.*
/// 对应页面：sync_queue.html, profile.html(副标题状态)

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
  /// GET /api/sync/queue/
  static Future<List<SyncQueueItem>> getQueue() async {
    throw UnimplementedError('SyncRepository.getQueue');
  }

  /// 失败记录数（供 profile.html 判断）
  static Future<int> getFailedCount() async {
    throw UnimplementedError('SyncRepository.getFailedCount');
  }

  /// 同步队列是否全部完成
  static Future<bool> isEmpty() async {
    throw UnimplementedError('SyncRepository.isEmpty');
  }

  /// 是否有失败记录
  static Future<bool> hasFailed() async {
    throw UnimplementedError('SyncRepository.hasFailed');
  }

  /// 全部重试
  /// POST /api/sync/retry-all/
  static Future<void> retryAll() async {
    throw UnimplementedError('SyncRepository.retryAll');
  }

  /// 失败数文本（供 profile.html 副标题）
  static Future<String> failedCountText() async {
    throw UnimplementedError('SyncRepository.failedCountText');
  }

  /// 全部成功文本
  static Future<String> allSuccessText() async {
    throw UnimplementedError('SyncRepository.allSuccessText');
  }
}
