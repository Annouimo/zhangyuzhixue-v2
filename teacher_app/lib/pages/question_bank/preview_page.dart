import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../app_theme.dart';
import '../../domain/question_repository.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_placeholder.dart';

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
      final details = <int, QuestionDetail>{};
      for (final id in _questionIds) {
        final d = await widget.repo.getQuestionDetail(id);
        details[id] = d;
      }
      if (!mounted) return;
      setState(() { _details.addAll(details); _loading = false; });
    } catch (e) {
      if (!mounted) return;
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制到剪贴板'), behavior: SnackBarBehavior.floating),
              );
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
      return const Center(child: Text('暂无题目'));
    }
    return ListView(
      padding: const EdgeInsets.all(AppSizes.baseSpacing),
      children: _questionIds.map((id) {
        final detail = _details[id];
        if (detail == null) return const SizedBox.shrink();
        final q = detail.question;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(
                      '${q.number.isNotEmpty ? '第${q.number}题 ' : ''}${q.examType} ${q.region} ${q.year}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    )),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                      tooltip: '移除此题',
                      onPressed: () => _remove(id),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(q.stem.length > 150 ? '${q.stem.substring(0, 150)}...' : q.stem,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _tag(_typeLabel(q.questionType)),
                    const SizedBox(width: 6),
                    if (q.difficulty != null)
                      _tag('难度 ${q.difficulty!.toStringAsFixed(1)}'),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'choice': return '选择题';
      case 'fill': return '填空题';
      case 'solution': return '解答题';
      default: return type;
    }
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(
        fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500,
      )),
    );
  }
}
