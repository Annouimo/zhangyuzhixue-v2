import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../domain/exam_repository.dart';
import '../../domain/paper_question_order.dart';

class PaperDraft {
  final String name;
  final List<SearchQuestion> questions;

  const PaperDraft({required this.name, required this.questions});
}

class PaperDraftDialog extends StatefulWidget {
  final String initialName;
  final List<SearchQuestion> questions;
  final int cost;

  const PaperDraftDialog({
    super.key,
    required this.initialName,
    required this.questions,
    required this.cost,
  });

  @override
  State<PaperDraftDialog> createState() => _PaperDraftDialogState();
}

class _PaperDraftDialogState extends State<PaperDraftDialog> {
  late final TextEditingController _nameController;
  late final List<SearchQuestion> _questions;
  SearchQuestion? _removedQuestion;
  int? _removedIndex;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _questions = canonicalizePaperQuestions(
      widget.questions,
      (question) => question.questionType,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int _count(String type) =>
      _questions.where((question) => question.questionType == type).length;

  void _confirm() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _questions.isEmpty) return;
    Navigator.of(
      context,
    ).pop(PaperDraft(name: name, questions: List.unmodifiable(_questions)));
  }

  void _removeQuestion(int index) {
    setState(() {
      _removedIndex = index;
      _removedQuestion = _questions.removeAt(index);
    });
  }

  void _undoRemove() {
    final question = _removedQuestion;
    if (question == null) return;
    setState(() {
      final index = (_removedIndex ?? _questions.length).clamp(
        0,
        _questions.length,
      );
      _questions.insert(index, question);
      _removedQuestion = null;
      _removedIndex = null;
    });
  }

  void _reorderWithinType(String type, int oldIndex, int newIndex) {
    setState(() {
      final group = _questions
          .where((question) => question.questionType == type)
          .toList();
      final question = group.removeAt(oldIndex);
      group.insert(newIndex, question);
      var groupIndex = 0;
      for (var index = 0; index < _questions.length; index++) {
        if (_questions[index].questionType == type) {
          _questions[index] = group[groupIndex++];
        }
      }
    });
  }

  Widget _buildQuestionGroups() {
    var numberOffset = 0;
    final sections = <Widget>[];
    final types = [
      ...paperQuestionTypeOrder,
      ..._questions
          .map((question) => question.questionType)
          .where((type) => !paperQuestionTypeOrder.contains(type))
          .toSet(),
    ];
    for (final type in types) {
      final questions = _questions
          .where((question) => question.questionType == type)
          .toList();
      if (questions.isEmpty) continue;
      final startNumber = numberOffset;
      numberOffset += questions.length;
      sections.add(
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            '${QuestionTypeLabels.of(type)} · ${questions.length} 题',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      );
      sections.add(
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: questions.length,
          onReorderItem: (oldIndex, newIndex) =>
              _reorderWithinType(type, oldIndex, newIndex),
          itemBuilder: (context, index) {
            final question = questions[index];
            final globalIndex = _questions.indexWhere(
              (item) => item.id == question.id,
            );
            return ListTile(
              key: ValueKey(question.id),
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(
                width: 28,
                child: Text('${startNumber + index + 1}.'),
              ),
              title: MdLatexBody(question.title, fontSize: 14),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: '预览题目',
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: () => _previewQuestion(question),
                  ),
                  IconButton(
                    tooltip: '移除题目',
                    icon: const Icon(Icons.close),
                    onPressed: () => _removeQuestion(globalIndex),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
    return ListView(children: sections);
  }

  Future<void> _previewQuestion(SearchQuestion question) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(QuestionTypeLabels.of(question.questionType)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MdLatexBody(question.title, fontSize: 15),
              if (question.meta.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(question.meta),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      title: const Text('确认试卷'),
      content: SizedBox(
        width: 560,
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '试卷名称'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                AppStatusBadge(label: '共 ${_questions.length} 题'),
                AppStatusBadge(label: '选择题 ${_count('choice')}'),
                AppStatusBadge(label: '填空题 ${_count('fill')}'),
                AppStatusBadge(label: '解答题 ${_count('solution')}'),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '可在同一题型内拖动排序',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ),
              ],
            ),
            if (_removedQuestion != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '已移除：${_removedQuestion!.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                  TextButton(onPressed: _undoRemove, child: const Text('撤销')),
                ],
              ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: _questions.isEmpty
                  ? EmptyPlaceholder(
                      icon: Icons.playlist_remove,
                      message: '试卷中至少需要一道题',
                    )
                  : _buildQuestionGroups(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        AppButton(
          onPressed: _nameController.text.trim().isEmpty || _questions.isEmpty
              ? null
              : _confirm,
          label: '确认生成 · ${widget.cost} 积分',
          expanded: false,
        ),
      ],
    );
  }
}
