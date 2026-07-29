import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/app_button.dart';
import 'package:shared/widgets/app_page_layout.dart';
import '../../domain/question_repository.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/daos/system_config_dao.dart';
import '../../data/database/database_provider.dart';
import 'widgets/solve_flow_widget.dart';
import 'widgets/solve_question_surface.dart';
import 'widgets/question_contribution_actions.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import '../../widgets/pop_back_guard.dart';
import '../exam/exam_session_timer.dart';

/// 选择题解题页
class SolveChoicePage extends StatefulWidget {
  final int questionId;
  final int? nextQuestionId;
  final List<int> sequence;
  final List<int> quickPracticeSeen;
  final QuestionRepository? questionRepository;
  final String? mode;
  final int? attemptId;
  final bool embedded;
  final bool forceNewAttempt;
  final VoidCallback? onNext;

  const SolveChoicePage({
    super.key,
    required this.questionId,
    this.nextQuestionId,
    this.sequence = const [],
    this.quickPracticeSeen = const [],
    this.questionRepository,
    this.mode,
    this.attemptId,
    this.embedded = false,
    this.forceNewAttempt = false,
    this.onNext,
  });

  @override
  State<SolveChoicePage> createState() => _SolveChoicePageState();
}

class _SolveChoicePageState extends State<SolveChoicePage> {
  String? _selected;
  bool _submitted = false;
  bool _isCorrect = false;
  bool _submitting = false;
  bool _loading = true;
  bool _showResult = false;
  bool _newAttemptCreated = false;
  int _coolDownSec = 10;
  QuestionDetail? _detail;
  String? _error;
  late final QuestionRepository _repo;

  // 作答次数选择器
  List<SolveAttempt> _attempts = [];
  final PopBackGuard _popGuard = PopBackGuard();
  SolveAttempt? _currentAttempt;

  @override
  void initState() {
    super.initState();
    _repo =
        widget.questionRepository ??
        QuestionRepository(
          QuestionDao(DatabaseProvider()),
          ProgressDao(DatabaseProvider()),
        );
    _load();
    _loadCooldown();
  }

  Future<void> _loadCooldown() async {
    try {
      final dao = SystemConfigDao(DatabaseProvider());
      final sec = await dao.getInt('solve_cooldown_choice', 10);
      if (!mounted) return;
      setState(() => _coolDownSec = sec);
    } catch (e) {
      OperationLog.instance.error('solve_choice_page_load', e);
      AuditLogger.instance.error('SolveChoicePage._loadCooldown', e);
    }
  }

  /// 根据存档恢复选择状态
  Future<void> _restoreAttemptState(SolveAttempt attempt) async {
    if (attempt.isCompleted) {
      final dao = ProgressDao(DatabaseProvider());
      final rows = await dao.getAttempts(widget.questionId);
      final match = rows
          .where((r) => r.attemptNumber == attempt.attemptNumber)
          .toList();
      if (match.isNotEmpty && mounted) {
        setState(() {
          _selected = match.first.answerText;
          _submitted = true;
          _isCorrect = match.first.isCorrect == 1;
          _showResult = true;
        });
      }
    } else {
      setState(() {
        _selected = null;
        _submitted = false;
        _isCorrect = false;
        _showResult = false;
      });
    }
  }

  Future<void> _load() async {
    try {
      OperationLog.instance.action('solve_choice_page_load', 'T1 start');
      final detail = await _repo.getDetail(widget.questionId);
      OperationLog.instance.action(
        'solve_choice_page_load',
        'T2 after getDetail',
      );
      var attempts = await _repo.getAttempts(widget.questionId);
      OperationLog.instance.action(
        'solve_choice_page_load',
        'T3 after getAttempts (${attempts.length})',
      );

      // 首次访问且未指定回顾模式时，自动创建存档
      if (attempts.isEmpty &&
          widget.mode != 'review' &&
          !widget.forceNewAttempt) {
        await _repo.startSolve(widget.questionId);
        OperationLog.instance.action(
          'solve_choice_page_load',
          'T4 after startSolve',
        );
        attempts = await _repo.getAttempts(widget.questionId);
      }

      SolveAttempt? latest;
      if (widget.attemptId != null) {
        latest = attempts.where((a) => a.id == widget.attemptId).firstOrNull;
      }
      if (!widget.forceNewAttempt) {
        latest ??= attempts.isNotEmpty ? attempts.last : null;
      }
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _attempts = attempts;
        _currentAttempt = latest;
        _loading = false;
      });
      // 恢复选择状态
      if (latest != null) {
        await _restoreAttemptState(latest);
      }
      AuditLogger.instance.page('SolveChoicePage', {
        'qid': widget.questionId,
        'optionsCount': _detail?.options?.length,
      });
      OperationLog.instance.action('solve_choice_page_load', 'T5 complete');
    } catch (e) {
      OperationLog.instance.action('solve_choice_page_load', 'T6 catch: $e');
      OperationLog.instance.error('solve_choice_page_load', e);
      AuditLogger.instance.error('SolveChoicePage._load', e);
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_selected == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      if (widget.forceNewAttempt && !_newAttemptCreated) {
        await _repo.startSolve(widget.questionId);
        _newAttemptCreated = true;
      }
      await _repo.saveAttempt(
        widget.questionId,
        answerText: _selected!,
        isCorrect: _selected == _detail?.answer,
      );
      if (!mounted) return;
      OperationLog.instance.action(
        'solve_choice',
        'submitted qid=${widget.questionId}',
      );
      setState(() {
        _submitted = true;
        _isCorrect = _selected == _detail?.answer;
        _submitting = false;
        _showResult = true;
      });
    } catch (e) {
      setState(() => _submitting = false);
      AuditLogger.instance.error('SolveChoicePage._submit', e);
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'choice':
        return '选择';
      case 'fill':
        return '填空';
      case 'solution':
        return '解答';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      if (widget.embedded) {
        return const LoadingIndicator(message: '正在加载题目');
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('选择题'),
          actions: [
            ...questionContributionActions(context, widget.questionId),
            const ExamTimerAction(),
          ],
        ),
        body: const LoadingIndicator(message: '正在加载题目'),
      );
    }
    if (_error != null) {
      final error = ErrorPlaceholder(
        message: '题目加载失败，请检查后重试',
        onRetry: () {
          setState(() {
            _error = null;
            _loading = true;
          });
          _load();
        },
      );
      if (widget.embedded) return error;
      return Scaffold(
        appBar: AppBar(
          title: const Text('选择题'),
          actions: [
            ...questionContributionActions(context, widget.questionId),
            const ExamTimerAction(),
          ],
        ),
        body: error,
      );
    }

    final body = _buildSolveBody();
    if (widget.embedded) return body;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        final shouldPop = await _popGuard.consume(context, 'solve_choice');
        if (shouldPop && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('选择题'),
          actions: [
            ...questionContributionActions(context, widget.questionId),
            const ExamTimerAction(),
          ],
        ),
        body: body,
      ),
    );
  }

  Widget _buildSolveBody() {
    return AppContentContainer(
      maxWidth: AppContentWidth.reading,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SolveFlowWidget(
              cooldownSeconds: _coolDownSec,
              isRevisit: _submitted,
              showResult: _showResult,
              isCorrect: _isCorrect,
              correctAnswer: _detail?.answer,
              explanation: _detail?.explanation,
              onSubmit: _selected == null ? null : _submit,
              submitLoading: _submitting,
              onNext:
                  widget.onNext ??
                  (_isQuickPractice
                      ? _continueQuickPractice
                      : _nextQuestionId != null
                      ? () {
                          SolveRouteHelper.navigateToNext(
                            context,
                            _nextQuestionId!,
                            widget.sequence,
                          );
                        }
                      : null),
              nextLabel: _isQuickPractice ? '再来一题' : '下一题',
              onRate: () async {
                await context.push('/solve/rate?id=${widget.questionId}');
                _load();
              },
              onFinish: !_isQuickPractice && _nextQuestionId == null
                  ? () => context.pop()
                  : null,
              child: _buildContent(),
            ),
            if (_attempts.isNotEmpty && !widget.embedded) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: '重新作答',
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.secondary,
                fullWidth: true,
                onPressed: _createNewAttempt,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  int? get _nextQuestionId {
    final index = widget.sequence.indexOf(widget.questionId);
    if (index >= 0 && index + 1 < widget.sequence.length) {
      return widget.sequence[index + 1];
    }
    return widget.nextQuestionId;
  }

  bool get _isQuickPractice => widget.quickPracticeSeen.isNotEmpty;

  Future<void> _continueQuickPractice() async {
    final navigated = await SolveRouteHelper.navigateToNextQuickPractice(
      context,
      widget.quickPracticeSeen,
    );
    if (!navigated && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('本轮题目已全部完成')));
      context.pop();
    }
  }

  /// 构建作答次数选择器
  Widget _buildAttemptSelector() {
    final colors = context.colors;
    if (_attempts.isEmpty) return const SizedBox.shrink();

    final label = _currentAttempt != null
        ? '第 ${_currentAttempt!.attemptNumber} 次作答'
        : '第 ${_attempts.length + 1} 次作答';

    if (_attempts.length <= 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.primary),
        ),
      );
    }

    return PopupMenuButton<Object>(
      onSelected: (value) async {
        if (value is SolveAttempt) {
          await _switchAttempt(value);
        }
      },
      offset: const Offset(0, 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) => [
        ..._attempts.map(
          (a) => PopupMenuItem<Object>(
            value: a,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '第 ${a.attemptNumber} 次作答',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: a.id == _currentAttempt?.id
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: a.id == _currentAttempt?.id
                        ? colors.primary
                        : colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  a.isCompleted ? '回顾' : (a.isStarted ? '进行中' : '未开始'),
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: colors.primary)),
            Icon(Icons.expand_more, size: 14, color: colors.primary),
          ],
        ),
      ),
    );
  }

  /// 切换作答次数
  Future<void> _switchAttempt(SolveAttempt attempt) async {
    setState(() {
      _currentAttempt = attempt;
    });
    await _restoreAttemptState(attempt);
  }

  /// 创建新作答
  Future<void> _createNewAttempt() async {
    try {
      await _repo.startSolve(widget.questionId);
      final attempts = await _repo.getAttempts(widget.questionId);
      if (!mounted) return;
      setState(() {
        _attempts = attempts;
        _currentAttempt = attempts.isNotEmpty ? attempts.last : null;
        _selected = null;
        _submitted = false;
        _isCorrect = false;
        _showResult = false;
      });
    } catch (e) {
      OperationLog.instance.error('solve_choice_page_load', e);
      AuditLogger.instance.error('SolveChoicePage._createNewAttempt', e);
    }
  }

  Widget _buildContent() {
    final detail = _detail;
    if (detail == null) {
      return ErrorPlaceholder(message: '题目数据不存在', onRetry: _load);
    }

    final options =
        detail.options?.entries.toList() ?? const <MapEntry<String, String>>[];
    return SolveQuestionSurface(
      number: detail.number,
      title: detail.title,
      questionTypeLabel: _typeLabel(detail.questionType),
      attemptSelector: widget.embedded ? null : _buildAttemptSelector(),
      isReviewMode: _submitted,
      conceptTags: detail.conceptTags,
      stem: detail.stem,
      imagePaths: detail.images,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _submitted ? '作答结果' : '请选择一个答案',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < options.length; i++) ...[
            SolveAnswerOption(
              label: options[i].key,
              content: options[i].value,
              state: _optionState(options[i].key, detail.answer),
              onTap: _submitted
                  ? null
                  : () => setState(() => _selected = options[i].key),
            ),
            if (i != options.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  SolveOptionState _optionState(String key, String? correctAnswer) {
    final selected = _selected == key;
    if (_submitted && key == correctAnswer) return SolveOptionState.correct;
    if (_submitted && selected && !_isCorrect) {
      return SolveOptionState.incorrect;
    }
    if (selected) return SolveOptionState.selected;
    if (_submitted) return SolveOptionState.disabled;
    return SolveOptionState.idle;
  }
}
