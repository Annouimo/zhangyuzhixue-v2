/// 章鱼智学 — 同步引擎类型定义
///
/// 本文件定义同步引擎使用的所有枚举、数据模型和响应体。
/// 不依赖任何其他模块，可独立阅读。
///
/// 定稿后对接工作：
/// 1. 将实体存入 SQLite 的 sync_queue 表（见 database 层的表定义）
/// 2. 实际的 HTTP 请求在 api/sync_api.dart 中实现

// ═══════════════════════════════════════════════
// 枚举
// ═══════════════════════════════════════════════

/// 实体类型：当前端有哪些数据需要同步到服务器
enum SyncEntityType {
  /// 提交明细（学生答案）
  submissionDetail,

  /// 步骤反馈（学生对每一步的自我评价）
  stepFeedback,

  /// 卡片反馈（学生对知识卡片的掌握程度）
  cardFeedback,

  /// 题目评分（难度/计算量/优美度打分）
  rating,

  /// 组卷（学生自组试卷）
  exam,
}

/// 操作类型
enum SyncOperationType {
  /// 新增或更新
  upsert,

  /// 删除
  delete,
}

/// 记录同步状态
enum SyncStatus {
  /// 待推送
  pending,

  /// 正在推送中
  inProgress,

  /// 推送失败，可重试
  failed,

  /// 超过最大重试次数，放弃
  permanentFailure,
}

// ═══════════════════════════════════════════════
// 核心数据模型
// ═══════════════════════════════════════════════

/// 同步队列中的一条记录
///
/// 设计说明：对应 database 层 sync_queue 表中的一行。
/// 定稿后应将此结构替换为 drift 生成的 DataClass。
class SyncQueueEntry {
  final int id;
  final SyncEntityType entityType;
  final SyncOperationType operationType;
  final int localId; // 本地 SQLite 中的主键
  final int? serverId; // 同步成功后服务器返回的 ID
  final Map<String, dynamic> payload; // 要发送的数据体
  final SyncStatus status;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastAttempt;

  const SyncQueueEntry({
    required this.id,
    required this.entityType,
    required this.operationType,
    required this.localId,
    this.serverId,
    required this.payload,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    this.lastAttempt,
  });

  /// 最大重试次数（与 sync_pusher.dart 中的常量保持一致）
  static const int maxRetries = 5;

  /// 是否超过最大重试次数
  bool get isExpired => retryCount >= maxRetries;

  /// 转换为推送到服务器的请求项
  Map<String, dynamic> toPushItem() => {
        'entity_type': entityType.name,
        'operation': operationType.name,
        'local_id': localId,
        'payload': payload,
      };
}

// ═══════════════════════════════════════════════
// API 响应模型
// ═══════════════════════════════════════════════

/// 服务器对单条记录的推送结果
class PushItemResult {
  final int localId;
  final String status; // 'created' | 'updated' | 'conflict' | 'error'
  final int? serverId;
  final String? message;

  const PushItemResult({
    required this.localId,
    required this.status,
    this.serverId,
    this.message,
  });

  bool get isSuccess =>
      status == 'created' || status == 'updated' || status == 'conflict';

  factory PushItemResult.fromJson(Map<String, dynamic> json) =>
      PushItemResult(
        localId: json['local_id'] as int,
        status: json['status'] as String,
        serverId: json['server_id'] as int?,
        message: json['message'] as String?,
      );
}

/// 推送请求的汇总结果
class PushBatchResult {
  final int successCount;
  final int failCount;
  final List<PushItemResult> details;

  const PushBatchResult({
    required this.successCount,
    required this.failCount,
    required this.details,
  });

  factory PushBatchResult.fromJson(Map<String, dynamic> json) =>
      PushBatchResult(
        successCount: json['success_count'] as int,
        failCount: json['fail_count'] as int,
        details: (json['details'] as List)
            .map((e) => PushItemResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 版本检查响应
class VersionStatus {
  final int version;
  final bool forceUpdate;
  final String? message;

  const VersionStatus({
    required this.version,
    required this.forceUpdate,
    this.message,
  });

  factory VersionStatus.fromJson(Map<String, dynamic> json) => VersionStatus(
        version: json['version'] as int,
        forceUpdate: json['force_update'] as bool? ?? false,
        message: json['message'] as String?,
      );
}
