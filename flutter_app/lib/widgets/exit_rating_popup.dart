import 'dart:math';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import '../app_theme.dart';
import '../data/prefs/app_prefs.dart';
import '../data/sync/sync_manager.dart';
import '../data/sync/sync_types.dart';
import '../data/database/database_provider.dart';
import '../data/database/app_database.dart' as app_db;

// ── 硬编码配置（后续从 SystemConfig 读取）──
class _RatingConfig {
  static const double probability = 0.2;
  static const int minStaySeconds = 30;
  static const int rewardPoints = 5;
}

/// 判断指定页面是否应该展示评价弹层（概率+冷却+停留时间三条件）
bool shouldShowExitRating(String pageUrl, DateTime entryTime) {
  // 1. 概率检查
  if (Random().nextDouble() >= _RatingConfig.probability) return false;
  // 2. 冷却检查
  if (AppPrefs().isRatingCooldownActive(pageUrl)) return false;
  // 3. 停留时间检查
  final elapsed = DateTime.now().difference(entryTime).inSeconds;
  if (elapsed < _RatingConfig.minStaySeconds) return false;
  return true;
}

/// 提交退出评价：冷却写入 + sync 入队 + 积分赠送
Future<void> submitExitRating({
  required int score,
  String? feedback,
  required String pageUrl,
  DatabaseProvider? dbProvider,
}) async {
  await AppPrefs().setRatingCooldown(pageUrl);
  await SyncManager().enqueue(
    entityType: SyncEntityType.exitRating,
    operation: SyncOperationType.upsert,
    localId: 0,
    payload: '{"score":$score,"feedback":${feedback != null ? '"$feedback"' : 'null'},"page_url":"$pageUrl"}',
  );
  // 赠送积分
  final now = DateTime.now().toIso8601String();
  final provider = dbProvider ?? DatabaseProvider();
  await provider.appDb.into(provider.appDb.pointsTransactions).insert(
    app_db.PointsTransactionsCompanion(
      amount: const Value(_RatingConfig.rewardPoints),
      source: const Value('EXIT_RATING_REWARD'),
      transactionType: const Value('earn'),
      createdAt: Value(now),
    ),
  );
}

/// 外部入口：检查条件 → 条件满足时弹窗 → 弹窗结果处理
///
/// 返回 true 表示"已处理完弹窗（提交或跳过），调用方可继续返回"。
/// 返回 false 表示条件不满足，调用方可直接返回。
Future<bool> showExitRatingIfNeeded(
  BuildContext context,
  String pageUrl,
  DateTime entryTime,
) async {
  if (!shouldShowExitRating(pageUrl, entryTime)) return false;

  final result = await showDialog<ExitRatingResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const ExitRatingPopup(),
  );

  if (result != null && context.mounted) {
    await submitExitRating(
      score: result.score,
      feedback: result.feedback,
      pageUrl: pageUrl,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('感谢评价！+${_RatingConfig.rewardPoints}积分')),
      );
    }
  }
  return true;
}

// ── 弹层结果 ──
@visibleForTesting
class ExitRatingResult {
  final int score;
  final String? feedback;
  const ExitRatingResult({required this.score, this.feedback});
}

// ── 评价弹层 Widget ──
@visibleForTesting
class ExitRatingPopup extends StatefulWidget {
  const ExitRatingPopup({super.key});
  @override State<ExitRatingPopup> createState() => _ExitRatingPopupState();
}

class _ExitRatingPopupState extends State<ExitRatingPopup> {
  int? _selectedScore;
  final _feedbackController = TextEditingController();
  bool _submitting = false;

  static const _emojis = ['😡', '😕', '😐', '😊', '🤩'];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('🎉 感觉怎么样？', textAlign: TextAlign.center),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (i) {
          final selected = _selectedScore == i + 1;
          return GestureDetector(
            onTap: _submitting ? null : () => setState(() => _selectedScore = i + 1),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _selectedScore == null || selected ? 1.0 : 0.35,
              child: Text(_emojis[i], style: TextStyle(fontSize: selected ? 36 : 28)),
            ),
          );
        })),
        const SizedBox(height: 16),
        TextField(
          controller: _feedbackController,
          maxLines: 3,
          enabled: !_submitting,
          decoration: const InputDecoration(
            hintText: '说说你的想法...',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting || _selectedScore == null ? null : _onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _submitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('提交反馈 (+${_RatingConfig.rewardPoints}积分)'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('跳过', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ]),
    );
  }

  Future<void> _onSubmit() async {
    setState(() => _submitting = true);
    Navigator.of(context).pop(ExitRatingResult(
      score: _selectedScore!,
      feedback: _feedbackController.text.trim().isEmpty ? null : _feedbackController.text.trim(),
    ));
  }
}
