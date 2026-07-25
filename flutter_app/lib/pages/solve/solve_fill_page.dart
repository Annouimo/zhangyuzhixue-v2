import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/theme/app_icons.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/app_button.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_status_badge.dart';
import '../../domain/question_repository.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/daos/system_config_dao.dart';
import '../../data/database/database_provider.dart';
import 'widgets/solve_reveal_widget.dart';
import 'widgets/solve_question_surface.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

/// 填空题解题页 �?揭示答案模式
///
/// �?solve-fill.html 原型对齐�?
/// 冷却 �?查看答案 �?显示正确答案 �?🎉 已完�?
class SolveFillPage extends StatefulWidget {
  final int questionId;
  final int? nextQuestionId;
  final QuestionRepository? questionRepository;
  final String? mode;
  final int? attemptId;

  const SolveFillPage({
    super.key,
    required this.questionId,
    this.nextQuestionId,
    this.questionRepository,
    this.mode,
    this.attemptId,
  });

  @override
  State<SolveFillPage> createState() => _SolveFillPageState();
}

class _SolveFillPageState extends State<SolveFillPage> {
  bool _loading = true;
  bool _revealed = false;
  bool _feedbackGiven = false;
  bool _feedbackCorrect = false;
  bool _isReviewMode = false;
  int _coolDownSec = 10;
  QuestionDetail? _detail;
  String? _error;
  late final QuestionRepository _repo;

  // 作答次数
  List<SolveAttempt> _attempts = [];
  final PopBackGuard _popGuard = PopBackGuard();
  SolveAttempt? _currentAttempt;

  @override
  void initState() {
    super.initState();
    _repo = widget.questionRepository ?? QuestionRepository(
      QuestionDao(DatabaseProvider()),
      ProgressDao(DatabaseProvider()),
    );
    _load();
    _loadCooldown();
  }

  Future<void> _loadCooldown() async {
    try {
      final dao = SystemConfigDao(DatabaseProvider());
      final sec = await dao.getInt('solve_cooldown_fill', 10);
      if (!mounted) return;
      setState(() => _coolDownSec = sec);
    } catch (e) { OperationLog.instance.error('solve_fill_page_load', e); 
      AuditLogger.instance.error('SolveFillPage._loadCooldown', e);
    }
  }

  Future<void> _load() async {
    try {
      OperationLog.instance.action('solve_fill_page_load', 'T1 start');
      final detail = await _repo.getDetail(widget.questionId);
      OperationLog.instance.action('solve_fill_page_load', 'T2 after getDetail');
      var attempts = await _repo.getAttempts(widget.questionId);
      OperationLog.instance.action('solve_fill_page_load', 'T3 after getAttempts (${attempts.length})');

      // 首次访问且未指定存档时，自动创建
      if (attempts.isEmpty && widget.mode != 'review') {
        await _repo.startSolve(widget.questionId);
        OperationLog.instance.action('solve_fill_page_load', 'T4 after startSolve');
        attempts = await _repo.getAttempts(widget.questionId);
      }

      SolveAttempt? latest;
      if (widget.attemptId != null) {
        latest = attempts.where((a) => a.id == widget.attemptId).firstOrNull;
      }
      latest ??= attempts.isNotEmpty ? attempts.last : null;

      if (!mounted) return;
      setState(() {
        _detail = detail;
        _attempts = attempts;
        _currentAttempt = latest;
        _revealed = latest?.isCompleted ?? false;
        _isReviewMode = latest?.isCompleted ?? false;
        _loading = false;
      });
      AuditLogger.instance.page('SolveFillPage', {'qid': widget.questionId});
      OperationLog.instance.action('solve_fill_page_load', 'T5 complete');
    } catch (e) {
      OperationLog.instance.action('solve_fill_page_load', 'T6 catch: $e');
      OperationLog.instance.error('solve_fill_page_load', e);
      AuditLogger.instance.error('SolveFillPage._load', e);
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'choice': return '选择';
      case 'fill': return '填空';
      case 'solution': return '解答';
      default: return type;
    }
  }

  /// 存档选择�?
  Widget _buildAttemptSelector() {
      final colors = context.colors;
    if (_attempts.isEmpty) return const SizedBox.shrink();

    final label = _currentAttempt != null
        ? '�?${_currentAttempt!.attemptNumber} 次作�?
        : '�?${_attempts.length + 1} 次作�?;

    if (_attempts.length <= 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
      onSelected: (value) {
        if (value is SolveAttempt) {
          _switchAttempt(value);
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
              Text('�?${a.attemptNumber} 次作�?,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: a.id == _currentAttempt?.id ? FontWeight.w600 : FontWeight.normal,
                  color: a.id == _currentAttempt?.id ? colors.primary : colors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                a.isCompleted ? '回顾' : (a.isStarted ? '进行�? : '未开�?),
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
            ],
          ),
        )),
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
            Text(label,
              style: TextStyle(fontSize: 11, color: colors.primary),
            ),
            Icon(Icons.expand_more, size: 14, color: colors.primary),
          ],
        ),
      ),
    );
  }

  void _switchAttempt(SolveAttempt attempt) {
    setState(() {
      _currentAttempt = attempt;
      _revealed = attempt.isCompleted;
      _isReviewMode = attempt.isCompleted;
    });
  }

  Future<void> _createNewAttempt() async {
    try {
      await _repo.startSolve(widget.questionId);
      final attempts = await _repo.getAttempts(widget.questionId);
      if (!mounted) return;
      setState(() {
        _attempts = attempts;
        _currentAttempt = attempts.isNotEmpty ? attempts.last : null;
        _revealed = false;
        _isReviewMode = false;
        _feedbackGiven = false;
        _feedbackCorrect = false;
      });
    } catch (e) { OperationLog.instance.error('solve_fill_page_load', e); 
      AuditLogger.instance.error('SolveFillPage._createNewAttempt', e);
    }
  }

  /// 揭示答案时展开结果区域，等待用户自�?
  Future<void> _onReveal() async {
    setState(() => _revealed = true);
    if (_currentAttempt == null) {
      await _repo.startSolve(widget.questionId);
      final attempts = await _repo.getAttempts(widget.questionId);
      if (!mounted) return;
      setState(() {
        _attempts = attempts;
        _currentAttempt = attempts.isNotEmpty ? attempts.last : null;
      });
    }
    OperationLog.instance.action('solve_fill', 'revealed qid=${widget.questionId}');
  }

  /// 用户自评后保存记�?
  Future<void> _submitFeedback(bool correct) async {
    if (!_revealed || _feedbackGiven) return;
    // 乐观锁定：立即阻断后续点击，用户瞬时看到反馈
    if (!mounted) return;
    setState(() {
      _feedbackGiven = true;
      _feedbackCorrect = correct;
    });
    if (_detail?.answer != null && _currentAttempt != null) {
      try {
        await _repo.saveAttempt(
          widget.questionId,
          answerText: _detail!.answer!,
          isCorrect: correct,
        );
      } catch (_) {}
    }
  }

  Widget _buildFeedbackButtons() {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '对照答案后，你认为自己答对了吗？',
            style: Theme.of(context).textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '请根据完整推导过程自评，而不只是最终结果�?,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final correctButton = FilledButton.icon(
                onPressed: () => _submitFeedback(true),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('答对�?),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.success,
                  foregroundColor: colors.onSuccess,
                ),
              );
              final retryButton = OutlinedButton.icon(
                onPressed: () => _submitFeedback(false),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('还没答对'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(color: colors.error),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    correctButton,
                    const SizedBox(height: AppSpacing.xs),
                    retryButton,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: correctButton),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: retryButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('填空�?)),
        body: const LoadingIndicator(message: '正在加载题目'),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('填空�?)),
        body: ErrorPlaceholder(
          message: '题目加载失败，请检查后重试',
          onRetry: () {
            setState(() {
              _error = null;
              _loading = true;
            });
            _load();
          },
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (await _popGuard.consume(context, 'solve_fill')) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('填空�?)),
        body: AppContentContainer(
          maxWidth: AppContentWidth.reading,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SolveRevealWidget(
                  cooldownSeconds: _coolDownSec,
                  isRevisit: _isReviewMode,
                  revealed: _revealed,
                  answerValue: _detail?.answer,
                  explanation: _detail?.explanation,
                  onReveal: _onReveal,
                  feedbackWidget: !_feedbackGiven && !_isReviewMode
                      ? _buildFeedbackButtons()
                      : null,
                  feedbackResult:
                      _feedbackGiven ? _buildFeedbackResult() : null,
                  onNext: widget.nextQuestionId != null
                      ? () {
                          SolveRouteHelper.navigateTo(
                            context,
                            widget.nextQuestionId!,
                            _detail!.questionType,
                          );
                        }
                      : null,
                  onRate: () async {
                    await RouterUtils.push(
                      context,
                      '${AppRoutes.solveRate}?id=${widget.questionId}',
                    );
                  },
                  child: _buildContent(),
                ),
                if (_attempts.isNotEmpty) ...[
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
        ),
      ),
    );
  }

  Widget _buildFeedbackResult() {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          AppStatusBadge(
            label: _feedbackCorrect ? '自评：回答正�? : '自评：仍需巩固',
            tone: _feedbackCorrect
                ? AppStatusTone.success
                : AppStatusTone.warning,
            icon: _feedbackCorrect
                ? Icons.check_circle_rounded
                : Icons.replay_rounded,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _feedbackCorrect ? '这道题已经掌握，可以继续下一题�? : '建议结合解析再梳理一遍关键步骤�?,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final detail = _detail;
    if (detail == null) {
      return ErrorPlaceholder(
        message: '题目数据不存�?,
        onRetry: _load,
      );
    }

    return SolveQuestionSurface(
      number: detail.number,
      title: detail.title,
      questionTypeLabel: _typeLabel(detail.questionType),
      attemptSelector: _buildAttemptSelector(),
      isReviewMode: _isReviewMode,
      conceptTags: detail.conceptTags,
      stem: detail.stem,
      imagePaths: detail.images,
      footer: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 22,
              color: context.colors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '请先独立完成推导或计算。阅读时间结束后，再查看标准答案并进行自评�?,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

