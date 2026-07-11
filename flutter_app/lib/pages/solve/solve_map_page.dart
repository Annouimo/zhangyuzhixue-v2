import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../app_theme.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/progress_repository.dart' as progress;

/// 解答题地图页 — 步骤概览（匹配 solve-map.html）
class SolveMapPage extends StatefulWidget {
  final int questionId;
  const SolveMapPage({super.key, required this.questionId});

  @override
  State<SolveMapPage> createState() => _SolveMapPageState();
}

class _SolveMapPageState extends State<SolveMapPage> {
  progress.SolveProgressState? _state;
  Set<int> _completedSteps = {};
  bool _loading = true;
  bool _isFresh = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = progress.ProgressRepository(
      ProgressDao(DatabaseProvider().appDb),
      QuestionDao(DatabaseProvider().assetsDb),
    );
    try {
      final s = await repo.getSolveState(widget.questionId);
      final attempts = await repo.getAttempts(widget.questionId);
      Set<int> doneSteps = {};
      if (attempts.isNotEmpty) {
        final last = attempts.last;
        final prevState = await repo.getAttemptState(
          widget.questionId, last.attemptNumber,
        );
        if (prevState != null) {
          doneSteps = prevState.subQRecords
              .expand((sq) => sq.methods)
              .expand((m) => m.steps)
              .where((s) => s.feedbackGiven)
              .map((s) => s.stepOrder)
              .toSet();
        }
      }
      final fresh = s.subQuestions.isEmpty;
      if (!mounted) return;
      setState(() {
        _state = s;
        _completedSteps = doneSteps;
        _isFresh = fresh;
        _loading = false;
      });
    } catch (e) {
      debugPrint('_load error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('解答题')),
      body: _loading
          ? const LoadingIndicator()
          : _isFresh
              ? _buildFreshView()
              : _buildMapView(),
    );
  }

  /// 首次欢迎视图
  Widget _buildFreshView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📝', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              '准备开始答题',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              '本题为解答题，支持多种解法。\n点击下方按钮开始你的首次作答。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/solve/step?id=${widget.questionId}&method=0&step=0'),
              icon: const Text('▶'),
              label: const Text('开始答题'),
            ),
          ],
        ),
      ),
    );
  }

  /// 地图视图
  Widget _buildMapView() {
    if (_state == null || _state!.subQuestions.isEmpty) {
      return const Center(child: Text('暂无步骤数据'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._state!.subQuestions.map((sq) {
          // 推算状态
          final allMethodsSteps = sq.solutions.expand((m) => m.steps);
          final totalSteps = allMethodsSteps.length;
          final doneStepsLocal = allMethodsSteps.where((s) => _completedSteps.contains(s.stepNumber)).length;
          final anyInProgress = allMethodsSteps.any((s) => s.stepNumber == (doneStepsLocal + 1) && !_completedSteps.contains(s.stepNumber));

          String statusLabel;
          Color statusColor;
          if (doneStepsLocal == totalSteps && totalSteps > 0) {
            statusLabel = '已完成';
            statusColor = AppColors.success;
          } else if (doneStepsLocal > 0 || anyInProgress) {
            statusLabel = '进行中...';
            statusColor = AppColors.warning;
          } else {
            statusLabel = '🔒 未解锁';
            statusColor = AppColors.textSecondary;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sq.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 方法列表
                ...sq.solutions.asMap().entries.map((mEntry) {
                  final mi = mEntry.key;
                  final m = mEntry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 方法名
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Text(
                                m.methodName != null && m.methodName!.isNotEmpty
                                    ? '📐 ${m.methodName}'
                                    : '唯一解法',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${m.steps.where((s) => _completedSteps.contains(s.stepNumber)).length}/${m.steps.length} 步',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        // 步骤列表
                        ...m.steps.asMap().entries.map((sEntry) {
                          final si = sEntry.key;
                          final s = sEntry.value;
                          final isStepDone = _completedSteps.contains(s.stepNumber);
                          // 如果前一步未完成且当前步未完成，锁定
                          final stepLocked = !isStepDone && si > 0 &&
                              m.steps.take(si).every((ps) => !_completedSteps.contains(ps.stepNumber));

                          return InkWell(
                            onTap: stepLocked
                                ? null
                                : () => context.push(
                                    '/solve/step?id=${widget.questionId}&method=$mi&step=$si',
                                  ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  // 步骤圆点
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isStepDone
                                          ? AppColors.success
                                          : (stepLocked
                                              ? Colors.grey[200]
                                              : AppColors.primaryLight),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: isStepDone
                                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                                          : (stepLocked
                                              ? const Text('🔒', style: TextStyle(fontSize: 11))
                                              : Text(
                                                  '${s.stepNumber}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.primary,
                                                  ),
                                                )),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      s.title.isNotEmpty ? s.title : '第 ${s.stepNumber} 步',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isStepDone
                                            ? AppColors.success
                                            : (stepLocked
                                                ? AppColors.textSecondary
                                                : AppColors.textPrimary),
                                      ),
                                    ),
                                  ),
                                  if (!stepLocked)
                                    const Icon(Icons.arrow_forward_ios,
                                      size: 12, color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
        // 底部操作
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('返回'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/solve/rate?id=${widget.questionId}'),
                icon: const Text('⭐'),
                label: const Text('评分'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
