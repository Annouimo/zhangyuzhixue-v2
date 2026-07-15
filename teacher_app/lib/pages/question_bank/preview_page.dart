import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../domain/question_repository.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_placeholder.dart';
import '../../widgets/question_card.dart';

/// 已选题预览页 — 教师端简化版
class PreviewPage extends StatefulWidget {
  final List<int> questionIds;
  final QuestionRepository questionRepository;

  /// 从列表中移除题目的回调
  final void Function(int questionId)? onRemove;

  const PreviewPage({
    super.key,
    required this.questionIds,
    required this.questionRepository,
    this.onRemove,
  });

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  final _questions = <int, QuestionDetail?>{};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      // 逐个加载题目详情
      for (final id in widget.questionIds) {
        if (!mounted) return;
        final detail = await widget.questionRepository.getQuestionDetail(id);
        if (!mounted) return;
        _questions[id] = detail;
        setState(() {});
      }
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('已选题 (${widget.questionIds.length})'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载题目…');
    if (_error != null) return ErrorPlaceholder(message: _error!, onRetry: _loadAll);

    if (_questions.isEmpty) {
      return const Center(child: Text('暂无已选题目'));
    }

    return ListView(
      padding: const EdgeInsets.all(AppSizes.baseSpacing),
      children: widget.questionIds.map((id) {
        final detail = _questions[id];
        final title = detail?.question.stem ?? '加载中…';
        final qType = detail?.question.questionType ?? 'choice';
        return QuestionCard(
          questionId: id,
          title: title,
          questionType: qType,
          subtitle: detail != null ? '${detail.question.year} · ${detail.question.region}' : null,
          difficulty: detail?.question.difficulty,
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
            tooltip: '移除',
            onPressed: () {
              setState(() {
                _questions.remove(id);
                widget.onRemove?.call(id);
              });
            },
          ),
        );
      }).toList(),
    );
  }
}
