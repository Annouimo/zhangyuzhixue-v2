import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/api/api_client.dart';
import '../../data/api/user_api.dart';
import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/user_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/exam_repository.dart';
import '../../domain/paper_creation_service.dart';
import '../../domain/paper_folder_repository.dart';
import '../../domain/user_repository.dart';
import '../../widgets/basket_selection_panel.dart';
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
  final Set<int> _selectedIds = {};

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
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await _repository.detail(widget.folderId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _selectedIds.removeWhere(
          (id) => !detail.questions.any((question) => question.id == id),
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
    final controller = TextEditingController(text: detail.folder.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重命名试题篮'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await _repository.rename(widget.folderId, name);
    await _load();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除试题篮？'),
        content: const Text('只删除试题篮，不影响已经生成的正式试卷。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('删除', style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.delete(widget.folderId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _saveQuestions(List<SearchQuestion> questions) async {
    await _repository.replaceQuestions(
      widget.folderId,
      questions.map((question) => question.id).toList(growable: false),
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
    if (detail == null || _selectedIds.isEmpty || _saving) return;
    final selectedQuestions = detail.questions
        .where((question) => _selectedIds.contains(question.id))
        .toList();
    final ids = selectedQuestions.map((question) => question.id).toList();
    final unchanged =
        detail.folder.lastGeneratedFingerprint.isNotEmpty &&
        detail.folder.lastGeneratedFingerprint == _repository.fingerprint(ids);
    if (unchanged) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('内容没有变化'),
          content: const Text('当前试题篮自上次生成后没有变化，继续生成仍会扣除 10 积分。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('继续生成'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('积分不足，生成试卷需要 ${error.requiredPoints} 积分')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      appBar: AppBar(
        title: Text(detail?.folder.name ?? '试题篮'),
        actions: [
          IconButton(
            tooltip: '重命名',
            onPressed: detail == null ? null : _rename,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: '删除试题篮',
            onPressed: detail == null ? null : _delete,
            icon: const Icon(Icons.delete_outline),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.sm,
                      0,
                    ),
                    child: MaterialBanner(
                      content: const Text('长按题目（桌面端右键）可编辑所在试题篮；长按右侧手柄可调整顺序。'),
                      actions: const [SizedBox.shrink()],
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: 96,
                      ),
                      itemCount: detail.questions.length,
                      onReorderItem: (oldIndex, newIndex) {
                        final questions = List<SearchQuestion>.of(
                          detail.questions,
                        );
                        final item = questions.removeAt(oldIndex);
                        questions.insert(newIndex, item);
                        _saveQuestions(questions);
                      },
                      itemBuilder: (context, index) {
                        final question = detail.questions[index];
                        final selected = _selectedIds.contains(question.id);
                        return GestureDetector(
                          key: ValueKey(question.id),
                          onLongPress: () => _editQuestionFolders(question),
                          onSecondaryTap: () => _editQuestionFolders(question),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: QuestionCard(
                              questionId: question.id,
                              title: question.title,
                              questionType: question.questionType,
                              subtitle: '${index + 1}. ${question.meta}',
                              difficulty: question.difficulty,
                              compact: true,
                              onTap: () => setState(() {
                                selected
                                    ? _selectedIds.remove(question.id)
                                    : _selectedIds.add(question.id);
                              }),
                              trailing: SizedBox(
                                width: 96,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Checkbox(
                                      value: selected,
                                      onChanged: (_) => setState(() {
                                        selected
                                            ? _selectedIds.remove(question.id)
                                            : _selectedIds.add(question.id);
                                      }),
                                    ),
                                    ReorderableDelayedDragStartListener(
                                      index: index,
                                      child: const Tooltip(
                                        message: '长按拖动排序',
                                        child: Padding(
                                          padding: EdgeInsets.all(
                                            AppSpacing.sm,
                                          ),
                                          child: Icon(
                                            Icons.drag_handle_rounded,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: detail == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppButton(
                  label: _selectedIds.isEmpty
                      ? '请选择题目'
                      : '用已选 ${_selectedIds.length} 题组卷 · 10 积分',
                  icon: Icons.description_outlined,
                  onPressed: _selectedIds.isEmpty || _saving ? null : _generate,
                  loading: _saving,
                ),
              ),
            ),
    );
  }
}
