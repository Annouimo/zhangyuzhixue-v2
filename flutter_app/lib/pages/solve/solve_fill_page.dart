import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../widgets/md_latex_body.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/exit_rating_popup.dart';
import '../../domain/question_repository.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/daos/system_config_dao.dart';
import '../../data/database/database_provider.dart';
import 'widgets/solve_flow_widget.dart';

/// 填空题解题页
class SolveFillPage extends StatefulWidget {
  final int questionId;
  final int? nextQuestionId;
  final QuestionRepository? questionRepository;

  const SolveFillPage({
    super.key,
    required this.questionId,
    this.nextQuestionId,
    this.questionRepository,
  });

  @override
  State<SolveFillPage> createState() => _SolveFillPageState();
}

class _SolveFillPageState extends State<SolveFillPage> {
  final _answerCtrl = TextEditingController();
  bool _submitted = false;
  bool _isCorrect = false;
  bool _loading = true;
  int _coolDownSec = 10;
  QuestionDetail? _detail;
  String? _error;
  late final QuestionRepository _repo;

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
      final sec = await dao.getInt('solve_cooldown_fill', 10);
      if (!mounted) return;
      setState(() => _coolDownSec = sec);
    } catch (e) {
      debugPrint('_loadCooldown error: $e');
    }
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final detail = await _repo.getDetail(widget.questionId);
      setState(() { _detail = detail; _loading = false; });
    } catch (e) {
      debugPrint('_load error: $e');
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _submit() {
    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty) return;
    setState(() {
      _submitted = true;
      _isCorrect = answer == _detail?.answer;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('填空题')),
        body: const LoadingIndicator(),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('填空题')),
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
        final shown = await showExitRatingIfNeeded(context, 'solve_fill', _entryTime!);
        if (shown && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('填空题')),
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
              ? () => context.go('/solve/fill?id=${widget.nextQuestionId}')
              : null,
          onRate: () => context.push('/solve/rate?id=${widget.questionId}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_detail != null && _detail!.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_detail!.title,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              MdLatexBody(_detail?.stem ?? '题目数据不存在'),
              const SizedBox(height: 16),
              TextField(
                controller: _answerCtrl,
                decoration: InputDecoration(
                  hintText: '输入答案',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14,
                  ),
                ),
                enabled: !_submitted,
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
