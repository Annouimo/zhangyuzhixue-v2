import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../app_theme.dart';
import '../../domain/question_repository.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_placeholder.dart';
import '../../widgets/shared/empty_placeholder.dart';
import '../../widgets/shared/app_toast.dart';
import '../../widgets/shared/question_card.dart';
import '../../data/debug/operation_log.dart';

/// 选题预览页 — 展示已选题目详情，支持移除
class QuestionPreviewPage extends StatefulWidget {
  final List<int> questionIds;
  final QuestionRepository repo;
  final ValueChanged<int> onRemove;

  const QuestionPreviewPage({
    super.key,
    required this.questionIds,
    required this.repo,
    required this.onRemove,
  });

  @override
  State<QuestionPreviewPage> createState() => _QuestionPreviewPageState();
}

class _QuestionPreviewPageState extends State<QuestionPreviewPage> {
  final Map<int, QuestionDetail> _details = {};
  late List<int> _questionIds;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _questionIds = List.of(widget.questionIds);
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() { _loading = true; _error = null; });
    try {
      final details = await widget.repo.getQuestionDetailsBatch(_questionIds);
      if (!mounted) return;
      setState(() { _details..clear()..addAll(details); _loading = false; });
    } catch (e) {
      if (!mounted) return;
      OperationLog.instance.error('QuestionPreviewPage._loadDetails', e);
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _remove(int id) {
    widget.onRemove(id);
    setState(() {
      _details.remove(id);
      _questionIds.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('预览（${_questionIds.length} 题）'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: '复制全部',
            onPressed: () {
              final json = jsonEncode({
                'version': 1,
                'questionIds': _questionIds,
                'selectedAt': DateTime.now().toIso8601String(),
                'totalCount': _questionIds.length,
              });
              Clipboard.setData(ClipboardData(text: json));
              AppToast.show(context, message: '已复制到剪贴板');
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载题目详情…');
    if (_error != null) return ErrorPlaceholder(message: _error!, onRetry: _loadDetails);
    if (_questionIds.isEmpty) {
      return const Center(child: EmptyPlaceholder(
        icon: Icons.inbox, message: '暂无题目',
      ));
    }
    return ListView(
      padding: const EdgeInsets.all(AppSizes.baseSpacing),
      children: _questionIds.where((id) => _details.containsKey(id)).map((id) {
        final detail = _details[id]!;
        final q = detail.question;
        return QuestionCard(
          questionId: q.id,
          title: q.stem,
          questionType: q.questionType,
          subtitle: '${q.number.isNotEmpty ? '第${q.number}题 ' : ''}${q.examType} ${q.region} ${q.year}'.trim(),
          difficulty: q.difficulty,
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
            tooltip: '移除此题',
            onPressed: () => _remove(id),
          ),
        );
      }).toList(),
    );
  }
}

