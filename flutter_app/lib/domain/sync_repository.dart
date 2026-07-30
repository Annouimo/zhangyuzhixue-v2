import '../data/daos/sync_queue_dao.dart';
import 'package:flutter/material.dart';

/// 同步队列状态 — 委托 SyncQueueDao + SyncApi
class SyncQueueItem {
  final String entityType;
  final String entityTypeName;
  final IconData icon;
  final String status;
  final String createdAt;
  final String timeAgo;
  final int retryCount;
  final String? errorMessage;

  const SyncQueueItem({
    required this.entityType,
    required this.entityTypeName,
    required this.icon,
    required this.status,
    required this.createdAt,
    required this.timeAgo,
    required this.retryCount,
    this.errorMessage,
  });
}

class SyncRepository {
  final SyncQueueDao _dao;
  
  const SyncRepository(this._dao);

  Future<List<SyncQueueItem>> getQueue() async {
    final rows = await _dao.getPending(limit: 500);
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
        errorMessage: r.errorMessage,
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
      case 'question_rating': return '评分';
      case 'custom_paper': return '组卷';
      case 'exitRating': return '退出评价';
      case 'paper_like': return '点赞';
      case 'paper_collect': return '收藏';
      case 'preference': return '筛选方案';
      case 'points_transaction': return '积分流水';
      default: return type;
    }
  }

  IconData _entityIcon(String type) {
    switch (type) {
      case 'submission': return Icons.assignment;
      case 'step_feedback': return Icons.directions_walk;
      case 'card_feedback': return Icons.style;
      case 'question_rating': return Icons.star;
      case 'custom_paper': return Icons.description;
      case 'exitRating': return Icons.chat;
      case 'paper_like': return Icons.thumb_up;
      case 'paper_collect': return Icons.push_pin;
      case 'preference': return Icons.tune;
      case 'points_transaction': return Icons.account_balance_wallet;
      default: return Icons.push_pin;
    }
  }
}
