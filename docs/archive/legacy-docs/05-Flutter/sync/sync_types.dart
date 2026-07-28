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
///
/// 服务器返回格式匹配: {server_ids: {localId: serverId}}
class PushBatchResult {
  final Map<int, int> serverIds;

  const PushBatchResult({required this.serverIds});

  factory PushBatchResult.fromJson(Map<String, dynamic> json) {
    final raw = json['server_ids'] as Map<String, dynamic>? ?? {};
    return PushBatchResult(
      serverIds: raw.map((k, v) => MapEntry(int.parse(k), v as int)),
    );
  }
}

/// 版本检查响应
///
/// 详见 docs/本地数据方案.md#二更新机制
class VersionStatus {
  /// 数据库结构版本（Flutter 端硬编码，不匹配时强制去商店更新 App）
  final int schemaVersion;

  /// 数据版本（管理员上传 .db 时标注）
  final int dataVersion;

  /// 是否强制更新
  final bool forceUpdate;

  /// 更新说明文字
  final String? message;

  /// .db 文件下载地址
  final String? downloadUrl;

  /// SHA256 校验值
  final String? checksum;

  /// 文件大小（字节）
  final int? sizeBytes;

  const VersionStatus({
    required this.schemaVersion,
    required this.dataVersion,
    required this.forceUpdate,
    this.message,
    this.downloadUrl,
    this.checksum,
    this.sizeBytes,
  });

  factory VersionStatus.fromJson(Map<String, dynamic> json) => VersionStatus(
        schemaVersion: json['schema_version'] as int,
        dataVersion: json['data_version'] as int,
        forceUpdate: json['force_update'] as bool? ?? false,
        message: json['message'] as String?,
        downloadUrl: json['download_url'] as String?,
        checksum: json['checksum'] as String?,
        sizeBytes: json['size_bytes'] as int?,
      );
}
