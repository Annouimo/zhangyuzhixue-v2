import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/prefs/app_prefs.dart';
import '../../domain/exam_repository.dart';
import '../../domain/paper_folder_repository.dart';
import '../../domain/paper_question_order.dart';
import '../../widgets/question_selection_workspace.dart';
import '../../widgets/selected_questions_panel.dart';

class PaperFolderDetailPage extends StatefulWidget {
  const PaperFolderDetailPage({
    super.key,
    required this.folderId,
    this.repository,
  });

  final int folderId;
  final PaperFolderRepository? repository;

  @override
  State<PaperFolderDetailPage> createState() => _PaperFolderDetailPageState();
}

class _PaperFolderDetailPageState extends State<PaperFolderDetailPage> {
  late final PaperFolderRepository _repository =
      widget.repository ?? PaperFolderRepository.local();
  PaperFolderDetail? _detail;
  String? _error;
  late bool _showHelpBadge;
  final QuestionWorkspaceController _workspaceController =
      QuestionWorkspaceController();

  @override
  void dispose() {
    _workspaceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _showHelpBadge = !AppPrefs().paperFolderHelpSeen;
    _load();
  }

  Future<void> _showHelp() async {
    if (_showHelpBadge) {
      setState(() => _showHelpBadge = false);
      await AppPrefs().setPaperFolderHelpSeen();
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('操作说明'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.drag_handle_rounded),
              title: Text('拖动右侧手柄'),
              subtitle: Text('调整题目顺序'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.check_circle_outline),
              title: Text('勾选题目后管理'),
              subtitle: Text('取消当前试题篮的勾选即可批量移除'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    try {
      final detail = await _repository.detail(widget.folderId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _workspaceController.retain(
          detail.questions.map((question) => question.id),
        );
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = '试题篮加载失败，请稍后重试');
    }
  }

  Future<void> _rename() async {
    final detail = _detail;
    if (detail == null) return;
    final name = await AppDialog.prompt(
      context,
      title: '重命名试题篮',
      initialValue: detail.folder.name,
      confirmLabel: '保存',
      validator: (value) => value.isEmpty ? '请输入名称' : null,
    );
    if (name == null || name.isEmpty) return;
    await _repository.rename(widget.folderId, name);
    await _load();
  }

  Future<void> _delete() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: '删除试题篮？',
      message: '只删除试题篮，不影响已经生成的正式试卷。',
      icon: Icons.delete_outline_rounded,
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed) return;
    await _repository.delete(widget.folderId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _clear() async {
    final detail = _detail;
    if (detail == null || detail.questions.isEmpty) return;
    final confirmed = await AppDialog.confirm(
      context,
      title: '清空试题篮？',
      message: '将从“${detail.folder.name}”移除全部 ${detail.questions.length} 道题。',
      icon: Icons.remove_shopping_cart_outlined,
      confirmLabel: '清空',
      destructive: true,
    );
    if (!confirmed) return;
    await _repository.replaceQuestions(widget.folderId, const []);
    await _load();
  }

  Future<void> _handleMenu(String value) async {
    if (value == 'help') await _showHelp();
    if (value == 'rename') await _rename();
    if (value == 'clear') await _clear();
    if (value == 'delete') await _delete();
  }

  Future<void> _saveQuestions(List<SearchQuestion> questions) async {
    final ordered = canonicalizePaperQuestions(
      questions,
      (question) => question.questionType,
    );
    await _repository.replaceQuestions(
      widget.folderId,
      ordered.map((question) => question.id).toList(growable: false),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final orderedQuestions = detail == null
        ? const <SearchQuestion>[]
        : canonicalizePaperQuestions(
            detail.questions,
            (question) => question.questionType,
          );
    return Scaffold(
      appBar: AppBar(
        title: Text(detail?.folder.name ?? '试题篮'),
        actions: [
          PopupMenuButton<String>(
            tooltip: '更多题篮操作',
            onSelected: _handleMenu,
            icon: Badge(
              isLabelVisible: _showHelpBadge,
              smallSize: 8,
              child: const Icon(Icons.more_horiz),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.drive_file_rename_outline),
                  title: Text('重命名题篮'),
                ),
              ),
              if (detail?.questions.isNotEmpty == true)
                const PopupMenuItem(
                  value: 'clear',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.remove_shopping_cart_outlined),
                    title: Text('清空题目'),
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.delete_outline,
                    color: context.colors.error,
                  ),
                  title: Text(
                    '删除题篮',
                    style: TextStyle(color: context.colors.error),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _error != null
          ? ErrorPlaceholder(message: _error!, onRetry: _load)
          : detail == null
          ? const LoadingIndicator(message: '正在加载试题篮')
          : AppContentContainer(
              maxWidth: AppContentWidth.standard,
              child: Column(
                children: [
                  const AppPageHint(
                    message: '拖动右侧手柄调整顺序，勾选题目后可批量管理。',
                  ),
                  Expanded(
                    child: QuestionWorkspace(
                      controller: _workspaceController,
                      basketRepository: _repository,
                      items: orderedQuestions
                    .asMap()
                    .entries
                    .map(
                      (entry) => QuestionWorkspaceItem(
                        id: entry.value.id,
                        title: entry.value.title,
                        questionType: entry.value.questionType,
                        subtitle: '${entry.key + 1}. ${entry.value.meta}',
                        difficulty: entry.value.difficulty,
                      ),
                    )
                        .toList(growable: false),
                      onOpen: (item) => _workspaceController.toggle(item.id),
                      onEdit: (item) => manageSelectedQuestions(
                  context: context,
                  repository: _repository,
                  questionIds: {item.id},
                ),
                onReorder: (oldIndex, newIndex) {
                  final questions = List<SearchQuestion>.of(orderedQuestions);
                  final type = questions[oldIndex].questionType;
                  final groupIndices = questions.indexed
                      .where((entry) => entry.$2.questionType == type)
                      .map((entry) => entry.$1)
                      .toList(growable: false);
                  final insertionIndex = oldIndex < newIndex
                      ? newIndex - 1
                      : newIndex;
                  if (insertionIndex < groupIndices.first ||
                      insertionIndex > groupIndices.last) {
                    AppToast.info(context, '只能在同一题型内调整顺序');
                    return;
                  }
                  final item = questions.removeAt(oldIndex);
                  questions.insert(insertionIndex, item);
                  _saveQuestions(questions);
                },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
