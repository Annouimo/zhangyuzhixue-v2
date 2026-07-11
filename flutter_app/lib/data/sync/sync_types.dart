// 同步引擎类型定义

/// 实体类型
enum SyncEntityType {
  submissionDetail,
  stepFeedback,
  cardFeedback,
  rating,
  exam,
  exitRating,
}

/// 操作类型
enum SyncOperationType {
  upsert,
  delete,
}

/// 同步状态
enum SyncStatus {
  pending,
  inProgress,
  failed,
  permanentFailure,
}
