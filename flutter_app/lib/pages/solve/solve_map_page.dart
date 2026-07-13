import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../app_theme.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/progress_repository.dart' as progress;
import '../../domain/question_repository.dart';
import '../../data/debug/audit_logger.dart';

/// 解答题地图页 — 步骤概览（匹配 solve-map.html）
class SolveMapPage extends StatefulWidget {
  final int questionId;
  final String? mode;
  final int? attemptId;

  const SolveMapPage({
    super.key,
    required this.questionId,
    this.mode,
    this.attemptId,
  });

  @override
  State<SolveMapPage> createState() => _SolveMapPageState();
}

class _SolveMapPageState extends State<SolveMapPage> {
  progress.SolveProgressState? _state;
  Set<int> _completedSteps = {};
  bool _loading = true;
  String? _error;
  bool _isFresh = false;
  bool _reviewMode = false;

  // 存档选择器
  List<progress.AttemptSummary> _attempts = [];
  int? _currentAttemptNumber;
  int? _currentSubmissionDetailId;

  // 题目信息
  QuestionDetail? _detail;

  // 解法折叠状态: methodIndex->collapsed
  final Set<String> _collapsedMethods = {};

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
    final qRepo = QuestionRepository(
      QuestionDao(DatabaseProvider().assetsDb),
      ProgressDao(DatabaseProvider().appDb),
    );
    try {
      final s = await repo.getSolveState(widget.questionId);
      final attempts = await repo.getAttempts(widget.questionId);

      // 加载题目元信息
      QuestionDetail? detail;
      try {
        detail = await qRepo.getDetail(widget.questionId);
      } catch (_) {}

      // 判断是否首次 (/fresh)
      final fresh = attempts.isEmpty;
      // 判断回顾模式: mode=review 或 attempts.last.completed 且不是最新
      final lastStarted = attempts.isNotEmpty ? attempts.last : null;
      final review = widget.mode == 'review' ||
          (lastStarted != null && lastStarted.status == 'completed' &&
           widget.attemptId != null && widget.attemptId != lastStarted.id);

      // 计算已完成步骤（按当前 attemptId 或最新存档）
      Set<int> doneSteps = {};
      int? currentSubmissionDetailId;
      int? currentAttemptNumber;

      if (attempts.isNotEmpty) {
        final targetAttemptNumber = widget.attemptId != null
            ? attempts.where((a) => a.id == widget.attemptId).firstOrNull?.attemptNumber
            : attempts.last.attemptNumber;
        currentAttemptNumber = targetAttemptNumber ?? attempts.last.attemptNumber;
        currentSubmissionDetailId = attempts
            .where((a) => a.attemptNumber == currentAttemptNumber)
            .firstOrNull?.id;

        final prevState = await repo.getAttemptState(
          widget.questionId, currentAttemptNumber,
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

      if (!mounted) return;
      setState(() {
        _state = s;
        _completedSteps = doneSteps;
        _isFresh = fresh;
        _reviewMode = review;
        _attempts = attempts;
        _currentAttemptNumber = currentAttemptNumber;
        _currentSubmissionDetailId = currentSubmissionDetailId;
        _detail = detail;
        _loading = false;
      });
      AuditLogger.instance.page('SolveMapPage', {
        'subQCount': _state?.subQuestions.length,
        'completedSteps': _completedSteps.length,
        'isFresh': _isFresh,
        'reviewMode': _reviewMode,
      });
    } catch (e) {
      AuditLogger.instance.error('SolveMapPage._load', e);
      debugPrint('_load error: $e');
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  // 入口分流路由构造
  String _buildStepRoute(int methodIndex, int stepIndex) {
    final buf = StringBuffer('/solve/step?id=${widget.questionId}'
        '&method=$methodIndex&step=$stepIndex');
    if (_currentAttemptNumber != null) {
      buf.write('&attemptId=$_currentSubmissionDetailId');
    }
    return buf.toString();
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'choice': return '选择';
      case 'fill': return '填空';
      case 'solution': return '解答';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('解答题')),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('加载失败', style: TextStyle(color: Color(0xFF6B7280))),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () { setState(() { _error = null; _loading = true; }); _load(); }, child: const Text('重试')),
                ]))
              : _isFresh
                  ? _buildFreshView()
                  : _buildMapView(),
    );
  }

  Widget _buildFreshView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\u{1F4DD}', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('准备开始答题',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            const Text('本题为解答题，支持多种解法。\n点击下方按钮开始你的首次作答。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                // 创建新存档
                final repo = progress.ProgressRepository(
                  ProgressDao(DatabaseProvider().appDb),
                  QuestionDao(DatabaseProvider().assetsDb),
                );
                await repo.createAttempt(widget.questionId);
                if (!context.mounted) return;
                await context.push(_buildStepRoute(0, 0));
                _load();
              },
              icon: const Text('\u25B6'),
              label: const Text('开始答题'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttemptSelector() {
    if (_attempts.isEmpty) return const SizedBox.shrink();

    final label = _currentAttemptNumber != null
        ? '第 $_currentAttemptNumber 次作答'
        : '第 ${_attempts.length + 1} 次作答';

    if (_attempts.length <= 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
          style: const TextStyle(fontSize: 11, color: AppColors.primary),
        ),
      );
    }

    return PopupMenuButton<Object>(
      onSelected: (value) async {
        if (value is progress.AttemptSummary) {
          // 切换到其他存档
          final repo = progress.ProgressRepository(
            ProgressDao(DatabaseProvider().appDb),
            QuestionDao(DatabaseProvider().assetsDb),
          );
          final prevState = await repo.getAttemptState(
            widget.questionId, value.attemptNumber,
          );
          Set<int> doneSteps = {};
          if (prevState != null) {
            doneSteps = prevState.subQRecords
                .expand((sq) => sq.methods)
                .expand((m) => m.steps)
                .where((s) => s.feedbackGiven)
                .map((s) => s.stepOrder)
                .toSet();
          }
          if (!mounted) return;
          setState(() {
            _currentAttemptNumber = value.attemptNumber;
            _currentSubmissionDetailId = value.id;
            _completedSteps = doneSteps;
            _reviewMode = value.status == 'completed';
          });
        } else if (value is String && value == 'new') {
          final repo = progress.ProgressRepository(
            ProgressDao(DatabaseProvider().appDb),
            QuestionDao(DatabaseProvider().assetsDb),
          );
          await repo.createAttempt(widget.questionId);
          final attempts = await repo.getAttempts(widget.questionId);
          if (!mounted) return;
          setState(() {
            _attempts = attempts;
            if (attempts.isNotEmpty) {
              _currentAttemptNumber = attempts.last.attemptNumber;
              _currentSubmissionDetailId = attempts.last.id;
            }
            _completedSteps = {};
            _reviewMode = false;
          });
        }
      },
      offset: const Offset(0, 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) => [
        ..._attempts.map((a) => PopupMenuItem<Object>(
          value: a,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('第 ${a.attemptNumber} 次作答',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: a.attemptNumber == _currentAttemptNumber ? FontWeight.w600 : FontWeight.normal,
                  color: a.attemptNumber == _currentAttemptNumber ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                a.status == 'completed' ? '回顾' : '进行中',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        )),
        const PopupMenuDivider(),
        PopupMenuItem<Object>(
          value: 'new',
          child: const Text('重新作答',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.primary),
            ),
            const Icon(Icons.expand_more, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    if (_state == null || _state!.subQuestions.isEmpty) {
      return const Center(child: Text('暂无步骤数据'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 题目元信息栏
        if (_detail != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (_detail!.number.isNotEmpty)
                  Text('第 ${_detail!.number} 题',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                if (_detail!.number.isNotEmpty && _detail!.title.isNotEmpty)
                  const SizedBox(width: 4),
                if (_detail!.title.isNotEmpty)
                  Expanded(
                    child: Text(_detail!.title,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('[${_typeLabel(_detail!.questionType)}]',
                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                _buildAttemptSelector(),
              ],
            ),
          ),

        // 回顾横幅
        if (_reviewMode)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Text('\u{1F4CB} 回顾模式 \u00B7 只读浏览，不可修改',
              style: TextStyle(fontSize: 13, color: AppColors.primary),
            ),
          ),

        // 解题树
        ..._state!.subQuestions.map((sq) {
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
            statusLabel = '未解锁';
            statusColor = AppColors.textSecondary;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(sq.label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500)),
                ),
              ]),
              const SizedBox(height: 10),
              ...sq.solutions.asMap().entries.map((mEntry) {
                final mi = mEntry.key;
                final m = mEntry.value;
                final methodKey = '${sq.index}_$mi';
                final isCollapsed = _collapsedMethods.contains(methodKey);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // 解法标题（可点击折叠）
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isCollapsed) {
                            _collapsedMethods.remove(methodKey);
                          } else {
                            _collapsedMethods.add(methodKey);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          Text(m.methodName?.isNotEmpty == true ? '\u{1F4D0} ${m.methodName}' : '唯一解法',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                          const Spacer(),
                          Text('${m.steps.where((s) => _completedSteps.contains(s.stepNumber)).length}/${m.steps.length} 步',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(width: 4),
                          Icon(isCollapsed ? Icons.expand_more : Icons.expand_less,
                            size: 16, color: AppColors.textSecondary),
                        ]),
                      ),
                    ),
                    // 步骤列表（折叠时隐藏）
                    if (!isCollapsed)
                      ...m.steps.asMap().entries.map((sEntry) {
                        final si = sEntry.key;
                        final st = sEntry.value;
                        final isStepDone = _completedSteps.contains(st.stepNumber);
                        final stepLocked = !isStepDone && si > 0 &&
                            m.steps.take(si).every((ps) => !_completedSteps.contains(ps.stepNumber));
                        return InkWell(
                          onTap: stepLocked ? null : () async {
                            await context.push(_buildStepRoute(mi, si));
                            _load();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(children: [
                              Container(width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: isStepDone ? AppColors.success : (stepLocked ? Colors.grey[200] : AppColors.primaryLight),
                                  borderRadius: BorderRadius.circular(12)),
                                child: Center(child: isStepDone
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : (stepLocked
                                    ? const Text('\u{1F512}', style: TextStyle(fontSize: 11))
                                    : Text('${st.stepNumber}', style: const TextStyle(fontSize: 11, color: AppColors.primary))))),
                              const SizedBox(width: 10),
                              Expanded(child: Text(st.title.isNotEmpty ? st.title : '第 ${st.stepNumber} 步',
                                style: TextStyle(fontSize: 13, color: isStepDone ? AppColors.success : (stepLocked ? AppColors.textSecondary : AppColors.textPrimary)))),
                              if (!stepLocked) const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textSecondary),
                            ]),
                          ),
                        );
                      }),
                  ]),
                );
              }),
            ]),
          );
        }),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('返回'))),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton.icon(
            onPressed: () => context.push('/solve/rate?id=${widget.questionId}'),
            icon: const Text('\u2B50'),
            label: const Text('评分'))),
        ]),
      ],
    );
  }
}
