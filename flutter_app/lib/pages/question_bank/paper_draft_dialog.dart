import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../domain/exam_repository.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _questions = List.of(widget.questions);
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
            Text(
              '拖动右侧手柄调整题序',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: _questions.isEmpty
                  ? EmptyPlaceholder(
                      icon: Icons.playlist_remove,
                      message: '试卷中至少需要一道题',
                    )
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: _questions.length,
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          final question = _questions.removeAt(oldIndex);
                          _questions.insert(newIndex, question);
                        });
                      },
                      itemBuilder: (context, index) {
                        final question = _questions[index];
                        return ListTile(
                          key: ValueKey(question.id),
                          contentPadding: EdgeInsets.zero,
                          leading: SizedBox(
                            width: 28,
                            child: Text('${index + 1}.'),
                          ),
                          title: Text(
                            question.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            QuestionTypeLabels.of(question.questionType),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: '移除题目',
                                icon: const Icon(Icons.close),
                                onPressed: () =>
                                    setState(() => _questions.removeAt(index)),
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
