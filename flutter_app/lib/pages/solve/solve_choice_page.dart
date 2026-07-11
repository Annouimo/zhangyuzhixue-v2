import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../domain/question_repository.dart';
import 'widgets/solve_flow_widget.dart';

/// 选择题解题页
class SolveChoicePage extends StatefulWidget {
  final int questionId;
  final int? nextQuestionId;

  const SolveChoicePage({
    super.key,
    required this.questionId,
    this.nextQuestionId,
  });

  @override
  State<SolveChoicePage> createState() => _SolveChoicePageState();
}

class _SolveChoicePageState extends State<SolveChoicePage> {
  String? _selected;
  bool _submitted = false;
  bool _isCorrect = false;
  bool _loading = true;
  QuestionDetail? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // 实际使用 QuestionRepository(QuestionDao, ProgressDao)
    // 简化：占位数据
    setState(() => _loading = false);
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('选择题')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SolveFlowWidget(
          isRevisit: _submitted,
          isCorrect: _isCorrect,
          correctAnswer: _detail?.answer,
          onSubmit: _submit,
          onNext: widget.nextQuestionId != null
              ? () => context.go('/solve/choice?id=${widget.nextQuestionId}')
              : null,
          onRate: () => context.push('/solve/rate?id=${widget.questionId}'),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // 简化展示 — 实际使用 QuestionRepository.getDetail
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('题目加载中…', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 16),
        if (_selected == null || !_submitted)
          ...List.generate(4, (i) {
            final label = String.fromCharCode(65 + i); // A, B, C, D
            final isSel = _selected == label;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: _submitted ? null : () => setState(() => _selected = label),
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
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSel ? AppColors.primary : Colors.grey[200],
                        ),
                        child: Center(
                          child: Text(label,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSel ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('选项 $label',
                        style: TextStyle(color: isSel ? AppColors.primary : AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
