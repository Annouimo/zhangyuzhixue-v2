import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/theme/app_theme.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/progress_repository.dart' as progress;
import '../../domain/question_repository.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

/// 解答题地图页 — 步骤概览（匹配 solve-map.html）
class SolveMapPage extends StatefulWidget {
  final int questionId;
  final String? mode;
  final int? attemptId;

  SolveMapPage({
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
  Set<String> _completedSteps = {};
  bool _loading = true;
  String? _error;
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
      ProgressDao(DatabaseProvider()),
      QuestionDao(DatabaseProvider()),
    );
    final qRepo = QuestionRepository(
      QuestionDao(DatabaseProvider()),
      ProgressDao(DatabaseProvider()),
    );
    try {
      OperationLog.instance.action('solve_map_page_load', 'T1 start');
      final s = await repo.getSolveState(widget.questionId);
      OperationLog.instance.action('solve_map_page_load', 'T2 after getSolveState (subQCount=${s.subQuestions.length})');
      var attempts = await repo.getAttempts(widget.questionId);
      OperationLog.instance.action('solve_map_page_load', 'T3 after getAttempts (${attempts.length})');

      // 加载题目元信息
      QuestionDetail? detail;
      try {
        detail = await qRepo.getDetail(widget.questionId);
        OperationLog.instance.action('solve_map_page_load', 'T4 after getDetail');
      } catch (e) {
        OperationLog.instance.action('solve_map_page_load', 'T4 getDetail error: $e');
      }

      // 首次访问自动创建存档
      if (attempts.isEmpty && widget.mode != 'review') {
        await repo.createAttempt(widget.questionId);
        OperationLog.instance.action('solve_map_page_load', 'T5 after createAttempt');
        attempts = await repo.getAttempts(widget.questionId);
      }

      // 判断回顾模式: mode=review 或 attempts.last.completed 且不是最新
      final lastStarted = attempts.isNotEmpty ? attempts.last : null;
      final review = widget.mode == 'review' ||
          (lastStarted != null && lastStarted.status == 'completed' &&
           widget.attemptId != null && widget.attemptId != lastStarted.id);

      // 计算已完成步骤（按当前 attemptId 或最新存档）
      Set<String> doneSteps = {};
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
          try {
            doneSteps = prevState.subQRecords
                .expand((sq) => sq.methods.asMap().entries
                    .expand((mEntry) => mEntry.value.steps
                        .where((s) => s.feedbackGiven)
                        .map((s) => '${sq.index}_${mEntry.key}_${s.stepOrder}')))
                .toSet();
          } catch (e1) {
            AuditLogger.instance.error('SolveMapPage._load.doneSteps', e1);
            rethrow;
          }
        }
      }
      OperationLog.instance.action('solve_map_page_load', 'T6 before setState');

      if (!mounted) return;
      setState(() {
        _state = s;
        _attempts = attempts;
        _detail = detail;
        _completedSteps = doneSteps;
        _reviewMode = review;
        _currentAttemptNumber = currentAttemptNumber;
        _currentSubmissionDetailId = currentSubmissionDetailId;
        _loading = false;
      });
      AuditLogger.instance.page('SolveMapPage', {
        'qid': widget.questionId,
        'subQCount': s.subQuestions.length,
      });
      OperationLog.instance.action('solve_map_page_load', 'T7 complete');
    } catch (e) {
      OperationLog.instance.action('solve_map_page_load', 'T8 catch: $e');
      OperationLog.instance.error('solve_map_page_load', e);
      AuditLogger.instance.error('SolveMapPage._load', e);
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  // 入口分流路由构造
  String _buildStepRoute(int subQIndex, int methodIndex, int stepIndex) {
      final colors = context.colors;
    final buf = StringBuffer('${AppRoutes.solveStep}?id=${widget.questionId}'
        '&subQ=$subQIndex&method=$methodIndex&step=$stepIndex');
    if (_currentAttemptNumber != null) {
      buf.write('&attemptId=$_currentSubmissionDetailId');
    }
    return buf.toString();
  }

  String _typeLabel(String type) {
      final colors = context.colors;
    switch (type) {
      case 'choice': return '选择';
      case 'fill': return '填空';
      case 'solution': return '解答';
      default: return type;
    }
  }

  String _formatCardLabels(List<String> cards) {
      final colors = context.colors;
    if (cards.isEmpty) return '';
    if (cards.length == 1) return cards.first;
    return '${cards.first} 等 ${cards.length} 个';
  }

  @override
  Widget build(BuildContext context) {
      final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text('解题地图')),
      body: _loading
          ? LoadingIndicator()
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('加载失败', style: TextStyle(color: colors.textSecondary)),
                  SizedBox(height: 8),
                  ElevatedButton(onPressed: () { setState(() { _error = null; _loading = true; }); _load(); }, child: Text('重试')),
                ]))
              : _buildMapView(),
    );
  }


  Widget _buildAttemptSelector() {
      final colors = context.colors;
    if (_attempts.isEmpty) return SizedBox.shrink();

    final label = _currentAttemptNumber != null
        ? '第 $_currentAttemptNumber 次作答'
        : '第 ${_attempts.length + 1} 次作答';

    if (_attempts.length <= 1) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
          style: TextStyle(fontSize: 11, color: colors.primary),
        ),
      );
    }

    return PopupMenuButton<Object>(
      onSelected: (value) async {
        if (value is progress.AttemptSummary) {
          // 切换到其他存档
          final repo = progress.ProgressRepository(
            ProgressDao(DatabaseProvider()),
            QuestionDao(DatabaseProvider()),
          );
          final prevState = await repo.getAttemptState(
            widget.questionId, value.attemptNumber,
          );
          Set<String> doneSteps = {};
          if (prevState != null) {
            doneSteps = prevState.subQRecords
                .expand((sq) => sq.methods.asMap().entries
                    .expand((mEntry) => mEntry.value.steps
                        .where((s) => s.feedbackGiven)
                        .map((s) => '${sq.index}_${mEntry.key}_${s.stepOrder}')))
                .toSet();
          }
          if (!mounted) return;
          setState(() {
            _currentAttemptNumber = value.attemptNumber;
            _currentSubmissionDetailId = value.id;
            _completedSteps = doneSteps;
            _reviewMode = value.status == 'completed';
          });
        }
      },
      offset: Offset(0, 28),
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
                  color: a.attemptNumber == _currentAttemptNumber ? colors.primary : colors.textPrimary,
                ),
              ),
              SizedBox(width: 8),
              Text(
                a.status == 'completed' ? '回顾' : '进行中',
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
            ],
          ),
        )),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
              style: TextStyle(fontSize: 11, color: colors.primary),
            ),
            Icon(Icons.expand_more, size: 14, color: colors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
      final colors = context.colors;
    if (_state == null || _state!.subQuestions.isEmpty) {
      return Center(child: Text('暂无步骤数据'));
    }
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // 题目元信息栏
        if (_detail != null)
          Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (_detail!.number.isNotEmpty)
                  Text('第 ${_detail!.number} 题',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                if (_detail!.number.isNotEmpty && _detail!.title.isNotEmpty)
                  SizedBox(width: 4),
                if (_detail!.title.isNotEmpty)
                  Expanded(
                    child: Text(_detail!.title,
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('[${_typeLabel(_detail!.questionType)}]',
                    style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(width: 8),
                _buildAttemptSelector(),
              ],
            ),
          ),

        // 回顾横幅
        if (_reviewMode)
          Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
            ),
            child: Text('\u{1F4CB} 回顾模式 \u00B7 只读浏览，不可修改',
              style: TextStyle(fontSize: 13, color: colors.primary),
            ),
          ),

        // 解题树
        ..._state!.subQuestions.asMap().entries.map((sqEntry) {
          final subQIdx = sqEntry.key; // 0-based
          final sq = sqEntry.value;
          // 方法级完成检测
          bool anyMethodFullyDone = false;
          bool allMethodsFullyDone = true;
          bool hasAnyStepDone = false;

          for (final mEntry in sq.solutions.asMap().entries) {
            final mi = mEntry.key;
            final m = mEntry.value;
            bool thisMethodAllDone = true;
            for (final s in m.steps) {
              final isDone = _completedSteps.contains('${sq.index}_${mi}_${s.stepNumber}');
              if (isDone) { hasAnyStepDone = true; } else { thisMethodAllDone = false; }
            }
            if (thisMethodAllDone) { anyMethodFullyDone = true; } else { allMethodsFullyDone = false; }
          }
          // 没有方法（空题）
          if (sq.solutions.isEmpty) allMethodsFullyDone = false;

          String statusLabel;
          Color statusColor;
          if (allMethodsFullyDone && sq.solutions.isNotEmpty) {
            statusLabel = '完全掌握';
            statusColor = colors.warning; // 金色
          } else if (anyMethodFullyDone) {
            statusLabel = '已完成';
            statusColor = colors.success;
          } else if (hasAnyStepDone) {
            statusLabel = '进行中...';
            statusColor = colors.warning;
          } else {
            statusLabel = '未解锁';
            statusColor = colors.textSecondary;
          }

          return Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(sq.label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary))),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500)),
                ),
              ]),
              SizedBox(height: 10),
              ...sq.solutions.asMap().entries.map((mEntry) {
                final mi = mEntry.key;
                final m = mEntry.value;
                final methodKey = '${sq.index}_$mi';
                final isCollapsed = _collapsedMethods.contains(methodKey);

                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
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
                        padding: EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          Text(m.methodName?.isNotEmpty == true ? '\u{1F4D0} ${m.methodName}' : '唯一解法',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
                          Spacer(),
                          Text('${m.steps.where((s) => _completedSteps.contains('${sq.index}_${mi}_${s.stepNumber}')).length}/${m.steps.length} 步',
                            style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                          SizedBox(width: 4),
                          Icon(isCollapsed ? Icons.expand_more : Icons.expand_less,
                            size: 16, color: colors.textSecondary),
                        ]),
                      ),
                    ),
                    // 步骤列表（折叠时隐藏）
                    if (!isCollapsed)
                      ...m.steps.asMap().entries.map((sEntry) {
                        final si = sEntry.key;
                        final st = sEntry.value;
                        final stepKey = '${sq.index}_${mi}_${st.stepNumber}';
                        final isStepDone = _completedSteps.contains(stepKey);
                        final stepLocked = !isStepDone && si > 0 &&
                            m.steps.take(si).every((ps) => !_completedSteps.contains('${sq.index}_${mi}_${ps.stepNumber}'));
                        return InkWell(
                          onTap: stepLocked ? null : () async {
                            await RouterUtils.push(context,_buildStepRoute(subQIdx, mi, si));
                            _load();
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(children: [
                              Container(width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: isStepDone ? colors.success : (stepLocked ? colors.disabledBackground : colors.primaryContainer),
                                  borderRadius: BorderRadius.circular(12)),
                                child: Center(child: isStepDone
                                  ? Icon(Icons.check, size: 14, color: Colors.white)
                                  : (stepLocked
                                    ? Text('\u{1F512}', style: TextStyle(fontSize: 11))
                                    : Text('${st.stepNumber}', style: TextStyle(fontSize: 11, color: colors.primary))))),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('第 ${st.stepNumber} 步',
                                      style: TextStyle(fontSize: 13, color: isStepDone ? colors.success : (stepLocked ? colors.textSecondary : colors.textPrimary))),
                                    if (!stepLocked && st.cardTitles.isNotEmpty)
                                      Text(_formatCardLabels(st.cardTitles),
                                        style: TextStyle(fontSize: 10, color: colors.textSecondary)),
                                  ],
                                ),
                              ),
                              if (!stepLocked) Icon(Icons.arrow_forward_ios, size: 12, color: colors.textSecondary),
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
        SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => safePop(context),
            icon: Icon(Icons.arrow_back, size: 16),
            label: Text('返回'))),
          SizedBox(width: 12),
          Expanded(child: OutlinedButton.icon(
            onPressed: _onRetry,
            icon: Icon(Icons.refresh, size: 16),
            label: Text('重新作答'))),
          SizedBox(width: 12),
          Expanded(child: OutlinedButton.icon(
            onPressed: () => RouterUtils.push(context,'${AppRoutes.solveRate}?id=${widget.questionId}'),
            icon: Icon(Icons.star, size: 16),
            label: Text('评分'))),
        ]),
      ],
    );
  }

  Future<void> _onRetry() async {
    final repo = progress.ProgressRepository(
      ProgressDao(DatabaseProvider()),
      QuestionDao(DatabaseProvider()),
    );
    await repo.createAttempt(widget.questionId);
    _load();
  }
}

