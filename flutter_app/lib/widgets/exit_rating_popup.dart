import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_button.dart';
import '../data/prefs/app_prefs.dart';
import '../data/sync/sync_manager.dart';
import '../data/sync/sync_types.dart';
import '../data/database/database_provider.dart';
import '../data/database/app_database.dart' as app_db;
import '../data/daos/system_config_dao.dart';

// ── 配置键名 ──
const _kProbability = 'exit_rating_probability';
const _kMinStaySeconds = 'exit_rating_min_stay_seconds';
const _kRewardPoints = 'exit_rating_reward_points';

/// 评价弹层配置（从 assets.db system_config 表读取，带内存缓存）
class ExitRatingConfig {
  final SystemConfigDao _dao;
  double? _probability;
  int? _minStaySeconds;
  double? _rewardPoints;

  ExitRatingConfig(this._dao);

  Future<double> get probability async =>
      _probability ??= await _dao.getDouble(_kProbability, 0.05);
  Future<int> get minStaySeconds async =>
      _minStaySeconds ??= await _dao.getInt(_kMinStaySeconds, 30);
  Future<double> get rewardPoints async =>
      _rewardPoints ??= await _dao.getDouble(_kRewardPoints, 0.5);

  void clearCache() {
    _probability = null;
    _minStaySeconds = null;
    _rewardPoints = null;
  }
}

/// 判断指定页面是否应该展示评价弹层（概率+冷却+停留时间三条件）
Future<bool> shouldShowExitRating(
  String pageUrl,
  DateTime entryTime,
  ExitRatingConfig config,
) async {
  // 1. 概率检查
  if (Random().nextDouble() >= await config.probability) return false;
  // 2. 冷却检查
  if (AppPrefs().isRatingCooldownActive(pageUrl)) return false;
  // 3. 停留时间检查
  final elapsed = DateTime.now().difference(entryTime).inSeconds;
  if (elapsed < await config.minStaySeconds) return false;
  return true;
}

/// 提交退出评价：冷却写入 + sync 入队 + 积分赠送
Future<bool> submitExitRating({
  required int score,
  String? feedback,
  required String pageUrl,
  DatabaseProvider? dbProvider,
  ExitRatingConfig? config,
}) async {
  try {
    await SyncManager().enqueue(
      entityType: SyncEntityType.exitRating,
      operation: SyncOperationType.upsert,
      localId: 0,
      payload: jsonEncode({
        'score': score,
        'feedback': feedback,
        'page_url': pageUrl,
      }),
    );
    // 赠送积分
    final now = DateTime.now().toIso8601String();
    final provider = dbProvider ?? DatabaseProvider();
    final cfg = config ?? ExitRatingConfig(SystemConfigDao(provider));
    final pts = await cfg.rewardPoints;
    final newId = await provider.appDb
        .into(provider.appDb.pointsTransactions)
        .insert(
          app_db.PointsTransactionsCompanion(
            amount: Value(pts),
            source: const Value('REVIEW_REWARD'),
            transactionType: const Value('EARN'),
            createdAt: Value(now),
          ),
        );
    // 入同步队列
    try {
      await SyncManager().enqueue(
        entityType: SyncEntityType.pointsTransaction,
        operation: SyncOperationType.upsert,
        localId: newId,
        payload: jsonEncode({
          'amount': pts,
          'source': 'REVIEW_REWARD',
          'transaction_type': 'EARN',
          'created_at': now,
        }),
      );
    } catch (_) {}
    // 所有操作成功后，再设冷却
    await AppPrefs().setRatingCooldown(pageUrl);
    return true;
  } catch (_) {
    // 任意步骤失败，冷却未被设置，用户下次可重试
    return false;
  }
}

/// 外部入口：检查条件 → 条件满足时弹窗 → 弹窗结果处理
///
/// 返回 true 表示"已处理完弹窗（提交或跳过），调用方可继续返回"。
/// 返回 false 表示条件不满足，调用方可直接返回。
Future<bool> showExitRatingIfNeeded(
  BuildContext context,
  String pageUrl,
  DateTime entryTime, {
  ExitRatingConfig? config,
}) async {
  final cfg = config ?? ExitRatingConfig(SystemConfigDao(DatabaseProvider()));

  if (!await shouldShowExitRating(pageUrl, entryTime, cfg)) return false;

  if (!context.mounted) return true;
  final result = await showDialog<ExitRatingResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ExitRatingPopup(rewardPoints: cfg.rewardPoints),
  );

  if (result != null && context.mounted) {
    final ok = await submitExitRating(
      score: result.score,
      feedback: result.feedback,
      pageUrl: pageUrl,
      config: cfg,
    );
    if (context.mounted) {
      if (ok) {
        final pts = await cfg.rewardPoints;
        if (!context.mounted) return false;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('感谢评价！+$pts积分')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('提交失败，请重试'),
            backgroundColor: context.colors.error,
          ),
        );
      }
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
  final Future<double> rewardPoints;
  const ExitRatingPopup({super.key, required this.rewardPoints});

  @override
  State<ExitRatingPopup> createState() => _ExitRatingPopupState();
}

class _ExitRatingPopupState extends State<ExitRatingPopup> {
  int? _selectedScore;
  final _feedbackController = TextEditingController();
  bool _submitting = false;
  double? _cachedReward;

  static const _emojis = ['😡', '😕', '😐', '😊', '🤩'];

  @override
  void initState() {
    super.initState();
    _loadReward();
  }

  Future<void> _loadReward() async {
    final v = await widget.rewardPoints;
    if (mounted) setState(() => _cachedReward = v);
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rp = _cachedReward ?? 5;
    return AlertDialog(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 24,
            color: context.colors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text('感觉怎么样？', textAlign: TextAlign.center),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final selected = _selectedScore == i + 1;
              return GestureDetector(
                onTap: _submitting
                    ? null
                    : () => setState(() => _selectedScore = i + 1),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _selectedScore == null || selected ? 1.0 : 0.35,
                  child: Text(
                    _emojis[i],
                    style: TextStyle(fontSize: selected ? 36 : 28),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.md),
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
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            onPressed: _submitting || _selectedScore == null ? null : _onSubmit,
            label: '提交反馈 (+$rp积分)',
            loading: _submitting,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            child: Text(
              '跳过',
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSubmit() async {
    setState(() => _submitting = true);
    Navigator.of(context).pop(
      ExitRatingResult(
        score: _selectedScore!,
        feedback: _feedbackController.text.trim().isEmpty
            ? null
            : _feedbackController.text.trim(),
      ),
    );
  }
}
