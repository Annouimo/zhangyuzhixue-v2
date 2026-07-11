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
      final sec = await dao.getInt('solve_cooldown_choice', 10);
      if (!mounted) return;
      setState(() => _coolDownSec = sec);
    } catch (e) {
      debugPrint('_loadCooldown error: $e');
    }
  }

  Future<void> _load() async {
    try {
      final detail = await _repo.getDetail(widget.questionId);
      setState(() { _detail = detail; _loading = false; });
    } catch (e) {
      debugPrint('_load error: $e');
      setState(() => _loading = false);
    }
  }

  void _submit() {
    if (_selected == null) return;
    setState(() {
      _submitted = true;
      _isCorrect = _selected == _detail?.answer;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('选择题')),
        body: const LoadingIndicator(),
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
          onRate: () => context.push('/solve/rate?id=${widget.questionId}'),
          child: _buildContent(),
        ),
      ),
    ));
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
        // 题目标题
        if (detail.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(detail.title,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        // 题干（含 LaTeX）
        MdLatexBody(detail.stem, fontSize: 15),
        const SizedBox(height: 20),
        // 图片
        ...detail.images.map((url) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Image.network(url, fit: BoxFit.contain),
        )),
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
