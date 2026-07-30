import 'package:flutter/material.dart';
import 'package:shared/widgets/sync_progress_dialog.dart';

import '../data/daos/sync_queue_dao.dart';
import '../data/database/database_provider.dart';
import '../data/sync/sync_manager.dart';

Future<bool> showUserSyncProgress(
  BuildContext context,
  Future<void> Function(void Function(double) onProgress) task, {
  Future<bool> Function()? dataVerifier,
  String title = '同步数据',
  String message = '正在同步…',
}) {
  return showSyncProgress(
    context,
    task,
    dataVerifier: dataVerifier,
    unresolvedDetails: _unresolvedSyncDetails,
    forceTask: (onProgress) => SyncManager().forcePull(
      onProgress: onProgress,
      discardPending: true,
    ),
    title: title,
    message: message,
  );
}

Future<List<String>> _unresolvedSyncDetails() async {
  final rows = await SyncQueueDao(DatabaseProvider()).getUnresolved();
  final counts = <String, int>{};
  for (final row in rows) {
    final label = switch (row.entityType) {
      'submission' => '答题记录',
      'step_feedback' => '步骤反馈',
      'card_feedback' => '卡片反馈',
      'question_rating' => '题目评分',
      'custom_paper' => '组卷',
      'paper_folder' => '试题篮',
      'paper_like' => '点赞',
      'paper_collect' => '收藏',
      'exitRating' => '退出评价',
      'preference' => '筛选方案',
      'points_transaction' => '积分流水',
      _ => '其他记录',
    };
    counts[label] = (counts[label] ?? 0) + 1;
  }
  return counts.entries
      .map((entry) => '${entry.key} ${entry.value} 条')
      .toList();
}
