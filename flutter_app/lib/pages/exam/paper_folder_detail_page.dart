import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/api/api_client.dart';
import '../../data/api/user_api.dart';
import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/user_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/prefs/app_prefs.dart';
import '../../domain/exam_repository.dart';
import '../../domain/paper_creation_service.dart';
import '../../domain/paper_folder_repository.dart';
import '../../domain/paper_question_order.dart';
import '../../domain/user_repository.dart';
import '../../widgets/basket_selection_panel.dart';
import '../../widgets/question_selection_workspace.dart';
import '../question_bank/paper_draft_dialog.dart';
import '../router.dart';

class PaperFolderDetailPage extends StatefulWidget {
  const PaperFolderDetailPage({
    super.key,
    required this.folderId,
    this.repository,
    this.creationService,
  });

  final int folderId;
  final PaperFolderRepository? repository;
  final PaperCreationService? creationService;

  @override
  State<PaperFolderDetailPage> createState() => _PaperFolderDetailPageState();
}

class _PaperFolderDetailPageState extends State<PaperFolderDetailPage> {
  late final PaperFolderRepository _repository =
      widget.repository ?? PaperFolderRepository.local();
  late final PaperCreationService _creationService =
      widget.creationService ?? _buildCreationService();
  PaperFolderDetail? _detail;
  String? _error;
  bool _saving = false;
  bool _organizing = false;
  late bool _showHelpBadge;
  final QuestionWorkspaceController _workspaceController =
      QuestionWorkspaceController();

  @override
  void dispose() {
    _workspaceController.dispose();
    super.dispose();
  }

  PaperCreationService _buildCreationService() {
    final provider = DatabaseProvider();
    return PaperCreationService(
      ExamRepository(QuestionDao(provider), ExamDao(provider)),
      UserRepository(
        UserDao(provider),
        UserApi(ApiClient()),
        QuestionDao(provider),
      ),
      provider,
    );
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
              leading: Icon(Icons.reorder_rounded),
              title: Text('点击“整理题目”'),
              subtitle: Text('进入排序和移除模式'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.drag_handle_rounded),
              title: Text('拖动右侧手柄'),
              subtitle: Text('调整题目顺序'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.remove_circle_outline),
              title: Text('点击移除按钮'),
              subtitle: Text('从当前试题篮移除这道题'),
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

  Future<void> _removeQuestion(int questionId) async {
    final detail = _detail;
    if (detail == null) return;
    await _saveQuestions(
      detail.questions
          .where((question) => question.id != questionId)
          .toList(growable: false),
    );
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

  Future<void> _editQuestionFolders(SearchQuestion question) async {
    final folders = await _repository.list();
    final initialIds = await _repository.folderIdsForQuestion(question.id);
    if (!mounted) return;
    final selectedIds = await showBasketSelectionPanel(
      context: context,
      title: '所在试题篮',
      subtitle: question.title,
      items: folders
          .map(
            (folder) => BasketSelectionItem(
              id: folder.id,
              name: folder.name,
              subtitle: '${folder.questionCount} 道题',
            ),
          )
          .toList(),
      initialSelectedIds: initialIds,
      multiple: true,
      allowEmpty: true,
      footerBuilder: (ids) {
        final added = ids.difference(initialIds).length;
        final removed = initialIds.difference(ids).length;
        final removingEverywhere = ids.isEmpty;
        return BasketSelectionFooter(
          summary: removingEverywhere
              ? '该题将从所有试题篮移除'
              : '将加入 $added 个试题篮，并从 $removed 个试题篮移除',
          confirmLabel: removingEverywhere ? '确认全部移除' : '保存所在试题篮',
          confirmIcon: removingEverywhere
              ? Icons.remove_shopping_cart_outlined
              : Icons.save_outlined,
          destructive: removingEverywhere,
        );
      },
      onCreate: () async {
        final name = await showCreateBasketDialog(context);
        if (name == null || name.isEmpty) return null;
        final id = await _repository.create(name);
        return BasketSelectionItem(id: id, name: name, subtitle: '0 道题');
      },
    );
    if (selectedIds == null) return;
    await _repository.setQuestionFolders(question.id, selectedIds);
    await _load();
  }

  Future<void> _generate() async {
    final detail = _detail;
    final selectedIds = _workspaceController.selectedIds;
    if (detail == null || selectedIds.isEmpty || _saving) return;
    final selectedQuestions = canonicalizePaperQuestions(
      detail.questions.where((question) => selectedIds.contains(question.id)),
      (question) => question.questionType,
    );
    final ids = selectedQuestions.map((question) => question.id).toList();
    final unchanged =
        detail.folder.lastGeneratedFingerprint.isNotEmpty &&
        detail.folder.lastGeneratedFingerprint == _repository.fingerprint(ids);
    if (unchanged) {
      final proceed = await AppDialog.confirm(
        context,
        title: '内容没有变化',
        message: '当前试题篮自上次生成后没有变化，继续生成仍会扣除 10 积分。',
        icon: Icons.info_outline_rounded,
        confirmLabel: '继续生成',
      );
      if (!proceed || !mounted) return;
    }
    final draft = await showDialog<PaperDraft>(
      context: context,
      builder: (_) => PaperDraftDialog(
        initialName: detail.folder.name,
        questions: selectedQuestions,
        cost: paperCreationCost,
      ),
    );
    if (draft == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final questionIds = draft.questions.map((q) => q.id).toList();
      final paperId = await _creationService.createFolderPaper(
        name: draft.name,
        questionIds: questionIds,
      );
      await _repository.markGenerated(widget.folderId, paperId, questionIds);
      if (!mounted) return;
      RouterUtils.push(context, '${AppRoutes.examQuicklook}?id=$paperId');
    } on InsufficientPointsException catch (error) {
      if (mounted) {
        AppToast.warning(context, '积分不足，生成试卷需要 ${error.requiredPoints} 积分');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
        leading: _organizing
            ? IconButton(
                tooltip: '退出整理',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _organizing = false),
              )
            : null,
        title: Text(_organizing ? '整理试题篮' : detail?.folder.name ?? '试题篮'),
        actions: _organizing
            ? [
                TextButton(
                  onPressed: () => setState(() => _organizing = false),
                  child: const Text('完成'),
                ),
              ]
            : [
                TextButton.icon(
                  onPressed: detail == null || detail.questions.isEmpty
                      ? null
                      : () => setState(() => _organizing = true),
                  icon: const Icon(Icons.reorder_rounded),
                  label: const Text('整理题目'),
                ),
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
                      value: 'help',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.help_outline_rounded),
                        title: Text('操作说明'),
                      ),
                    ),
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
              child: QuestionWorkspace(
                controller: _workspaceController,
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
                onOpen: (item) {
                  if (!_organizing) _workspaceController.toggle(item.id);
                },
                selectionEnabled: !_organizing,
                onRemove: _organizing
                    ? (item) => _removeQuestion(item.id)
                    : null,
                onEdit: _organizing
                    ? null
                    : (item) => _editQuestionFolders(
                        orderedQuestions.firstWhere(
                          (question) => question.id == item.id,
                        ),
                      ),
                onReorder: !_organizing
                    ? null
                    : (oldIndex, newIndex) {
                        final questions = List<SearchQuestion>.of(
                          orderedQuestions,
                        );
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
                bottomBuilder: _organizing
                    ? null
                    : (context, selectedIds) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: AppButton(
                            label: selectedIds.isEmpty
                                ? '请选择题目'
                                : '用已选 ${selectedIds.length} 题组卷 · 10 积分',
                            icon: Icons.description_outlined,
                            onPressed: selectedIds.isEmpty || _saving
                                ? null
                                : _generate,
                            loading: _saving,
                          ),
                        ),
                      ),
              ),
            ),
    );
  }
}
