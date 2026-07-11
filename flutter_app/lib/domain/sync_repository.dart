import '../data/daos/sync_queue_dao.dart';

/// 同步队列状态 — 委托 SyncQueueDao + SyncApi
class SyncQueueItem {
  final String entityType;
  final String entityTypeName;
  final String icon;
  final String status;
  final String createdAt;
  final String timeAgo;
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
}

class SyncRepository {
  final SyncQueueDao _dao;
  
  const SyncRepository(this._dao);

  Future<List<SyncQueueItem>> getQueue() async {
    final rows = await _dao.getPending(limit: 100);
    return rows.map((r) {
      final createdAt = r.createdAt;
      final ago = _timeAgo(createdAt);
      return SyncQueueItem(
        entityType: r.entityType,
        entityTypeName: _entityTypeName(r.entityType),
        icon: _entityIcon(r.entityType),
        status: r.status,
        createdAt: createdAt,
        timeAgo: ago,
        retryCount: r.retryCount,
      );
    }).toList();
  }

  Future<int> getFailedCount() => _dao.getFailedCount();

  Future<bool> isEmpty() => _dao.isEmpty();

  Future<bool> hasFailed() => _dao.hasFailed();

  Future<void> retryAll() async {
    await _dao.resetFailed();
  }

  Future<String> failedCountText() async {
    final count = await _dao.getFailedCount();
    return count > 0 ? '$count 条同步失败' : '';
  }

  Future<String> allSuccessText() async {
    final empty = await _dao.isEmpty();
    return empty ? '全部已同步' : '';
  }

  // ── 辅助 ──

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      return '${diff.inDays}天前';
    } catch (_) {
      return iso;
    }
  }

  String _entityTypeName(String type) {
    switch (type) {
      case 'submission': return '提交';
      case 'step_feedback': return '步骤反馈';
      case 'card_feedback': return '卡片反馈';
      case 'rating': return '评分';
      case 'exam': return '组卷';
      default: return type;
    }
  }

  String _entityIcon(String type) {
    switch (type) {
      case 'submission': return '📝';
      case 'step_feedback': return '👣';
      case 'card_feedback': return '🃏';
      case 'rating': return '⭐';
      case 'exam': return '📄';
      default: return '📌';
    }
  }
}

