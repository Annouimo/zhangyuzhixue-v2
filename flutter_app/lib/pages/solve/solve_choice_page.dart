import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

/// 选择题解题页
class SolveChoicePage extends StatefulWidget {
  final int questionId;
  final int? nextQuestionId;
  final QuestionRepository? questionRepository;

  const SolveChoicePage({
    super.key,
    required this.questionId,
    this.nextQuestionId,
    this.questionRepository,
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
      QuestionDao(DatabaseProvider().assetsDb),
      ProgressDao(DatabaseProvider().appDb),
    );
    _load();
    _loadCooldown();
  }

  Future<void> _loadCooldown() async {
    try {
      final dao = SystemConfigDao(DatabaseProvider().assetsDb);
      final sec = await dao.getInt('solve_cooldown_choice', 10);
      if (!mounted) return;
      setState(() => _coolDownSec = sec);
    } catch (e) {
      AuditLogger.instance.error('SolveChoicePage._loadCooldown', e);
      debugPrint('_loadCooldown error: $e');
    }
  }

  Future<void> _load() async {
    try {
      final detail = await _repo.getDetail(widget.questionId);
      // 加载作答次数
      final attempts = await _repo.getAttempts(widget.questionId);
      final latest = attempts.isNotEmpty ? attempts.last : null;
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _attempts = attempts;
        _currentAttempt = latest;
        _loading = false;
      });
      AuditLogger.instance.page('SolveChoicePage', {'qid': widget.questionId, 'optionsCount': _detail?.options?.length});
    } catch (e) {
      AuditLogger.instance.error('SolveChoicePage._load', e);
      debugPrint('_load error: $e');
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
      setState(() {
        _submitted = true;
        _isCorrect = _selected == _detail?.answer;
      });
    } catch (e) {
      AuditLogger.instance.error('SolveChoicePage._submit', e);
      debugPrint('_submit save error: $e');
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
        appBar: AppBar(title: const Text('选择题')),
        body: const LoadingIndicator(),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('选择题')),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('加载失败', style: TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () { setState(() { _error = null; _loading = true; }); _load(); }, child: const Text('重试')),
        ])),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _entryTime == null) return;
        final shown = await showExitRatingIfNeeded(context, 'solve_choice', _entryTime!);
        if (shown && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('选择题')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SolveFlowWidget(
            cooldownSeconds: _coolDownSec,
            isRevisit: _submitted,
            isCorrect: _isCorrect,
            correctAnswer: _detail?.answer,
            explanation: _detail?.explanation,
            onSubmit: _submit,
            onNext: widget.nextQuestionId != null
                ? () => context.go('/solve/choice?id=${widget.nextQuestionId}')
                : null,
            onRate: () async {
              await context.push('/solve/rate?id=${widget.questionId}');
              _load();
            },
            child: _buildContent(),
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

    // 仅一次作答时显示纯文字标签
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

    // 多次作答时显示下拉选择器
    return PopupMenuButton<Object>(
      onSelected: (value) {
        if (value is SolveAttempt) {
          _switchAttempt(value);
        } else if (value is String && value == 'new') {
          _createNewAttempt();
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

  /// 切换作答次数
  void _switchAttempt(SolveAttempt attempt) {
    setState(() {
      _currentAttempt = attempt;
    });
    // 重置答题状态（切换到存档对应状态）
    setState(() {
      _selected = null;
      _submitted = false;
      _isCorrect = false;
    });
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
    } catch (e) {
      AuditLogger.instance.error('SolveChoicePage._createNewAttempt', e);
      debugPrint('_createNewAttempt error: $e');
    }
  }

  Widget _buildContent() {
    final detail = _detail;
    if (detail == null) {
      return const Text('题目数据不存在',
        style: TextStyle(color: AppColors.textSecondary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 题目元信息区
        Container(
          width: double.infinity,
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
              // 作答次数选择器
              _buildAttemptSelector(),
            ],
          ),
        ),
        // 题干（含 LaTeX）
        MdLatexBody(detail.stem, fontSize: 15),
        const SizedBox(height: 20),
        // 图片
        ...detail.images.map((url) => QuestionImage(relativePath: url)),
        const SizedBox(height: 12),
        // 选项
        ...(detail.options?.entries.map((e) {
          final isSel = _selected == e.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: _submitted ? null : () => setState(() => _selected = e.key),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSel ? AppColors.primary : const Color(0xFFE5E7EB),
                    width: isSel ? 1.5 : 1,
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
                        color: isSel ? AppColors.primary : Colors.grey[200],
                      ),
                      child: Center(
                        child: Text(e.key,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSel ? Colors.white : AppColors.textSecondary,
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
