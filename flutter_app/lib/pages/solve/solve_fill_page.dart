import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/widgets/md_latex_body.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/question_image.dart';
import '../../widgets/exit_rating_popup.dart';
import '../../domain/question_repository.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/daos/system_config_dao.dart';
import '../../data/database/database_provider.dart';
import 'widgets/solve_reveal_widget.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

/// 填空题解题页 — 揭示答案模式
///
/// 与 solve-fill.html 原型对齐：
/// 冷却 → 查看答案 → 显示正确答案 → 🎉 已完成
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
  SolveAttempt? _currentAttempt;

  DateTime? _entryTime;

  @override
  void initState() {
    super.initState();
    _entryTime = DateTime.now();
    _repo = widget.questionRepository ?? QuestionRepository(
      QuestionDao(DatabaseProvider()),
      ProgressDao(DatabaseProvider()),
    );
    _load();
    _loadCooldown();
  }

  Future<void> _loadCooldown() async {
      final colors = context.colors;
    try {
      final dao = SystemConfigDao(DatabaseProvider());
      final sec = await dao.getInt('solve_cooldown_fill', 10);
      if (!mounted) return;
      setState(() => _coolDownSec = sec);
    } catch (e) { OperationLog.instance.error('solve_fill_page_load', e); 
      AuditLogger.instance.error('SolveFillPage._loadCooldown', e);
    }
  }

  @override
  void dispose() {
      final colors = context.colors;
    super.dispose();
  }

  Future<void> _load() async {
      final colors = context.colors;
    try {
      final detail = await _repo.getDetail(widget.questionId);
      var attempts = await _repo.getAttempts(widget.questionId);

      // 首次访问且未指定存档时，自动创建
      if (attempts.isEmpty && widget.mode != 'review') {
        await _repo.startSolve(widget.questionId);
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
    } catch (e) { OperationLog.instance.error('solve_fill_page_load', e); 
      AuditLogger.instance.error('SolveFillPage._load', e);
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
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

  /// 存档选择器
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
              Text('第 ${a.attemptNumber} 次作答',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: a.id == _currentAttempt?.id ? FontWeight.w600 : FontWeight.normal,
                  color: a.id == _currentAttempt?.id ? colors.primary : colors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                a.isCompleted ? '回顾' : (a.isStarted ? '进行中' : '未开始'),
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
      final colors = context.colors;
    setState(() {
      _currentAttempt = attempt;
      _revealed = attempt.isCompleted;
      _isReviewMode = attempt.isCompleted;
    });
  }

  Future<void> _createNewAttempt() async {
      final colors = context.colors;
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

  /// 揭示答案时展开结果区域，等待用户自评
  Future<void> _onReveal() async {
      final colors = context.colors;
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

  /// 用户自评后保存记录
  Future<void> _submitFeedback(bool correct) async {
      final colors = context.colors;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('你觉得自己答对了吗？',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () => _submitFeedback(true),
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('正确'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 100,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () => _submitFeedback(false),
                icon: const Icon(Icons.cancel, size: 18),
                label: const Text('错误'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
      final colors = context.colors;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('解题模式')),
        body: const LoadingIndicator(),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('解题模式')),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('加载失败', style: TextStyle(color: colors.textSecondary)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () { setState(() { _error = null; _loading = true; }); _load(); }, child: const Text('重试') ),
        ])),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (_entryTime == null) return;
        await showExitRatingIfNeeded(context, 'solve_fill', _entryTime!);
        if (context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('解题模式')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SolveRevealWidget(
                cooldownSeconds: _coolDownSec,
                isRevisit: _isReviewMode,
                revealed: _revealed,
                answerValue: _detail?.answer,
                explanation: _detail?.explanation,
                onReveal: _onReveal,
                feedbackWidget: !_feedbackGiven ? _buildFeedbackButtons() : null,
                feedbackResult: _feedbackGiven ? _buildFeedbackResult() : null,
                onNext: widget.nextQuestionId != null
                    ? () {
                        SolveRouteHelper.navigateTo(context, widget.nextQuestionId!, _detail!.questionType);
                      }
                    : null,
                onRate: () async {
                  await context.push('${AppRoutes.solveRate}?id=${widget.questionId}');
                },
                child: _buildContent(),
              ),
              if (_attempts.isNotEmpty) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _createNewAttempt,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('重新作答'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackResult() {
      final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _feedbackCorrect
            ? colors.success.withValues(alpha: 0.08)
            : colors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _feedbackCorrect
              ? colors.success.withValues(alpha: 0.3)
              : colors.textSecondary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _feedbackCorrect ? Icons.check_circle : Icons.cancel,
                size: 20,
                color: _feedbackCorrect ? colors.success : colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                _feedbackCorrect ? '回答正确！' : '回答有误',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _feedbackCorrect ? colors.success : colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _feedbackCorrect ? '' : '继续加油 💪',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
      final colors = context.colors;
    final detail = _detail;
    if (detail == null) {
      return Text('题目数据不存在',
        style: TextStyle(color: colors.textSecondary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 题目元信息栏
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (detail.number.isNotEmpty)
                Text('第 ${detail.number} 题',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              if (detail.number.isNotEmpty && detail.title.isNotEmpty)
                const SizedBox(width: 4),
              if (detail.title.isNotEmpty)
                Expanded(
                  child: Text(detail.title,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('[${_typeLabel(detail.questionType)}]',
                  style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              _buildAttemptSelector(),
            ],
          ),
        ),
        // 回顾横幅
        if (_isReviewMode) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
            ),
            child: Text('📋 回顾模式 · 只读浏览，不可修改',
              style: TextStyle(fontSize: 13, color: colors.primary),
            ),
          ),
        ],
        // 概念标签
        if (detail.conceptTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text('\u{1F3F7}\u{FE0F}',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                ...detail.conceptTags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(tag, style: TextStyle(fontSize: 12, color: colors.primary)),
                )),
              ],
            ),
          ),
        // 题干（含 LaTeX）
        MdLatexBody(detail.stem, fontSize: 15),
        const SizedBox(height: 16),
        // 图片
        ...detail.images.map((url) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: QuestionImage(relativePath: url),
        )),
      ],
    );
  }
}

