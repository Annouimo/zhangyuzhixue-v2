import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../domain/question_repository.dart';
import '../../widgets/question_card.dart';
import '../../widgets/shared/loading_indicator.dart';

/// 已选题预览页
class PreviewPage extends StatefulWidget {
  final List<int> questionIds;
  final QuestionRepository repo;
  final void Function(int id)? onRemove;

  const PreviewPage({
    super.key,
    required this.questionIds,
    required this.repo,
    this.onRemove,
  });

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  List<SearchQuestion>? _questions;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final questions = <SearchQuestion>[];
    for (final id in widget.questionIds) {
      final detail = await widget.repo.getQuestionDetail(id);
      if (detail != null) {
        final meta = [
          '${detail.question.year}',
          if (detail.question.region.isNotEmpty) detail.question.region,
        ].join(' · ');
        questions.add(SearchQuestion(
          id: id,
          title: detail.question.stem,
          questionType: detail.question.questionType,
          meta: meta,
          difficulty: detail.question.difficulty ?? 0,
          calculation: detail.question.calculation ?? 0,
        ));
      }
    }
    if (!mounted) return;
    setState(() { _questions = questions; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('已选 ${widget.questionIds.length} 题'),
      ),
      body: _loading
          ? const LoadingIndicator()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _questions!.length,
              itemBuilder: (ctx, i) {
                final q = _questions![i];
                return QuestionCard(
                  questionId: q.id,
                  title: q.title,
                  questionType: q.questionType,
                  subtitle: q.meta,
                  difficulty: q.difficulty,
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                      color: AppColors.error, size: 22),
                    onPressed: () {
                      widget.onRemove?.call(q.id);
                      setState(() => _questions!.removeAt(i));
                      if (_questions!.isEmpty) Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
    );
  }
}
