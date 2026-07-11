import 'package:flutter/material.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/exam_repository.dart';
import '../../../widgets/shared/loading_indicator.dart';
import '../../../widgets/shared/error_placeholder.dart';
import '../../../widgets/md_latex_body.dart';

/// 快对答案
class AnswerSheetPage extends StatefulWidget {
  final int examId;
  final ExamRepository? examRepository;
  const AnswerSheetPage({super.key, required this.examId, this.examRepository});

  @override
  State<AnswerSheetPage> createState() => _AnswerSheetPageState();
}

class _AnswerSheetPageState extends State<AnswerSheetPage> {
  late final ExamRepository _repo;
  List<AnswerItem>? _answers;
  bool _loading = true; String? _error;

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.examRepository ?? ExamRepository(
      QuestionDao(db.assetsDb), ExamDao(db.appDb),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final l = await _repo.getQuickAnswers(widget.examId);
      if (!mounted) return;
      setState(() { _answers = l; _loading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = e.toString(); _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('快对答案')),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载答案…');
    if (_error != null) return ErrorPlaceholder(message: _error!, onRetry: _load);
    final items = _answers ?? [];
    if (items.isEmpty) return const Center(child: Text('暂无答案'));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final a = items[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 28, height: 28,
                decoration: BoxDecoration(color: const Color(0xFFEEF1FF), borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A6CF7))))),
              const SizedBox(width: 12),
              Expanded(child: MdLatexBody(a.answer, fontSize: 14)),
            ],
          ),
        );
      },
    );
  }
}
