import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../../app_theme.dart';
import '../../widgets/md_latex_body.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/question_image.dart';
import '../../widgets/exit_rating_popup.dart';
import '../../domain/question_repository.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/daos/system_config_dao.dart';
import '../../data/database/database_provider.dart';
import 'widgets/solve_flow_widget.dart';
import '../../data/debug/audit_logger.dart';
import '../../../data/debug/operation_log.dart';

/// 选择题解题页
class SolveChoicePage extends StatefulWidget {
  final int questionId;
  final int? nextQuestionId;
  final QuestionRepository? questionRepository;
  final String? mode;
  final int? attemptId;

  const SolveChoicePage({
    super.key,
    required this.questionId,
    this.nextQuestionId,
    this.questionRepository,
    this.mode,
    this.attemptId,
  });

  @override
  State<SolveChoicePage> createState() => _SolveChoicePageState();
}

class _SolveChoicePageState extends State<SolveChoicePage> {
  String? _selected;
  bool _submitted = false;
  bool _isCorrect = false;
  bool _loading = true;
  int _coolDownSec = 10;
  QuestionDetail? _detail;
  String? _error;
  late final QuestionRepository _repo;

  // 作答次数选择器
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
    try {
      final dao = SystemConfigDao(DatabaseProvider());
      final sec = await dao.getInt('solve_cooldown_choice', 10);
      if (!mounted) return;
      setState(() => _coolDownSec = sec);
    } catch (e) { OperationLog.instance.error('solve_choice_page_load', e); 
      AuditLogger.instance.error('SolveChoicePage._loadCooldown', e);
    }
  }

  /// 根据存档恢复选择状态
  Future<void> _restoreAttemptState(SolveAttempt attempt) async {
    if (attempt.isCompleted) {
      final dao = ProgressDao(DatabaseProvider());
      final rows = await dao.getAttempts(widget.questionId);
      final match = rows.where((r) => r.attemptNumber == attempt.attemptNumber).toList();
      if (match.isNotEmpty && mounted) {
        setState(() {
          _selected = match.first.answerText;
          _submitted = true;
          _isCorrect = match.first.isCorrect == 1;
        });
      }
    } else {
      setState(() {
        _selected = null;
        _submitted = false;
        _isCorrect = false;
      });
    }
  }

  Future<void> _load() async {
    try {
      final detail = await _repo.getDetail(widget.questionId);
      var attempts = await _repo.getAttempts(widget.questionId);

      // 首次访问且未指定回顾模式时，自动创建存档
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
        _loading = false;
      });
      // 恢复选择状态
      if (latest != null) {
        await _restoreAttemptState(latest);
      }
      AuditLogger.instance.page('SolveChoicePage', {'qid': widget.questionId, 'optionsCount': _detail?.options?.length});
    } catch (e) { OperationLog.instance.error('solve_choice_page_load', e); 
      AuditLogger.instance.error('SolveChoicePage._load', e);
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _submit() async {
    if (_selected == null) return;
    try {
      await _repo.saveAttempt(
        widget.questionId,
        answerText: _selected!,
        isCorrect: _selected == _detail?.answer,
      );
      if (!mounted) return;
      OperationLog.instance.action('solve_choice', 'submitted qid=${widget.questionId}');
      setState(() {
        _submitted = true;
        _isCorrect = _selected == _detail?.answer;
      });
    } catch (e) {
      AuditLogger.instance.error('SolveChoicePage._submit', e);
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

  @override
  Widget build(BuildContext context) {
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
          const Text('加载失败', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () { setState(() { _error = null; _loading = true; }); _load(); }, child: const Text('重试')),
        ])),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (_entryTime == null) return;
        final shown = await showExitRatingIfNeeded(context, 'solve_choice', _entryTime!);
        if (shown && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('解题模式')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SolveFlowWidget(
                cooldownSeconds: _coolDownSec,
                isRevisit: _submitted,
                isCorrect: _isCorrect,
                correctAnswer: _detail?.answer,
                explanation: _detail?.explanation,
                onSubmit: _submit,
                onNext: widget.nextQuestionId != null
                    ? () {
                        SolveRouteHelper.navigateTo(context, widget.nextQuestionId!, _detail!.questionType);
                      }
                    : null,
                onRate: () async {
                  await context.push('${AppRoutes.solveRate}?id=${widget.questionId}');
                  _load();
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

  /// 构建作答次数选择器
  Widget _buildAttemptSelector() {
    if (_attempts.isEmpty) return const SizedBox.shrink();

    final label = _currentAttempt != null
        ? '第 ${_currentAttempt!.attemptNumber} 次作答'
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
        if (value is SolveAttempt) {
          await _switchAttempt(value);
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
                  color: a.id == _currentAttempt?.id ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                a.isCompleted ? '回顾' : (a.isStarted ? '进行中' : '未开始'),
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        )),
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
      });
    } catch (e) { OperationLog.instance.error('solve_choice_page_load', e); 
      AuditLogger.instance.error('SolveChoicePage._createNewAttempt', e);
    }
  }

  Widget _buildContent() {
    final detail = _detail;
    if (detail == null) {
      return const Text('题目数据不存在',
        style: TextStyle(color: AppColors.textSecondary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 题目元信息区
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.3),
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
                child: Text('[${_typeLabel(detail.questionType)}]',
                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              _buildAttemptSelector(),
            ],
          ),
        ),
        // 回顾横幅
        if (_submitted) ...[
          Container(
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
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(tag, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                )),
              ],
            ),
          ),
        // 题干（含 LaTeX）
        if (detail.conceptTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('相关概念：${detail.conceptTags.join("、")}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        MdLatexBody(detail.stem, fontSize: 15),
        const SizedBox(height: 20),
        // 图片
        ...detail.images.map((url) => QuestionImage(relativePath: url)),
        const SizedBox(height: 12),
        // 选项
        ...(detail.options?.entries.map((e) {
          final isSel = _selected == e.key;
          final isCorrectOption = _submitted && e.key == detail.answer;
          final isWrongSelection = _submitted && isSel && !_isCorrect;

          Color? borderColor;
          Color? bgColor;
          if (isCorrectOption) {
            borderColor = AppColors.success;
            bgColor = AppColors.success.withValues(alpha: 0.08);
          } else if (isWrongSelection) {
            borderColor = AppColors.error;
            bgColor = AppColors.error.withValues(alpha: 0.08);
          } else if (isSel) {
            borderColor = AppColors.primary;
            bgColor = AppColors.primaryLight;
          }

          Color dotBg = Colors.grey[200]!;
          Color dotText = AppColors.textSecondary;
          if (isCorrectOption) {
            dotBg = AppColors.success;
            dotText = Colors.white;
          } else if (isWrongSelection) {
            dotBg = AppColors.error;
            dotText = Colors.white;
          } else if (isSel) {
            dotBg = AppColors.primary;
            dotText = Colors.white;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: _submitted ? null : () => setState(() => _selected = e.key),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor ?? Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: borderColor ?? AppColors.border,
                    width: borderColor != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28, height: 28,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotBg,
                      ),
                      child: Center(
                        child: isCorrectOption
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : isWrongSelection
                                ? const Icon(Icons.close, size: 16, color: Colors.white)
                                : Text(e.key,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: dotText,
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MdLatexBody(e.value, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        }) ?? []),
      ],
    );
  }
}

