// 同步引擎类型定义

/// 实体类型
enum SyncEntityType {
  submission,
  stepFeedback,
  cardFeedback,
  rating,
  exam,
  exitRating,
  paperLike,
  paperCollect,
  preference,
}

/// 服务器期望的 entity_type 字符串
extension SyncEntityTypeServerName on SyncEntityType {
  String get serverName {
    switch (this) {
      case SyncEntityType.submission:
        return 'submission';
      case SyncEntityType.stepFeedback:
        return 'step_feedback';
      case SyncEntityType.cardFeedback:
        return 'card_feedback';
      case SyncEntityType.rating:
        return 'question_rating';
      case SyncEntityType.exam:
        return 'custom_paper';
      case SyncEntityType.exitRating:
        return 'exitRating';
      case SyncEntityType.paperLike:
        return 'paper_like';
      case SyncEntityType.paperCollect:
        return 'paper_collect';
      case SyncEntityType.preference:
        return 'preference';
    }
  }
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
