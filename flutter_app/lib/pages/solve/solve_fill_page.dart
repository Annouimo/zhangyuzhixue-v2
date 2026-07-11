import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/solve_flow_widget.dart';

/// 填空题解题页
class SolveFillPage extends StatefulWidget {
  final int questionId;
  final int? nextQuestionId;

  const SolveFillPage({
    super.key,
    required this.questionId,
    this.nextQuestionId,
  });

  @override
  State<SolveFillPage> createState() => _SolveFillPageState();
}

class _SolveFillPageState extends State<SolveFillPage> {
  final _answerCtrl = TextEditingController();
  bool _submitted = false;
  bool _isCorrect = false;

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty) return;
    setState(() {
      _submitted = true;
      _isCorrect = answer == '42'; // 简化验证
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('填空题')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SolveFlowWidget(
          isRevisit: _submitted,
          isCorrect: _isCorrect,
          onSubmit: _submit,
          onNext: widget.nextQuestionId != null
              ? () => context.go('/solve/fill?id=${widget.nextQuestionId}')
              : null,
          onRate: () => context.push('/solve/rate?id=${widget.questionId}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '题目内容加载中…\n\n请在下方输入你的答案：',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
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
    );
  }
}
