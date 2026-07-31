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
import '../../domain/paper_question_order.dart';
import '../../domain/user_repository.dart';
import '../question_bank/paper_draft_dialog.dart';
import '../router.dart';

class PaperFolderListPage extends StatefulWidget {
  const PaperFolderListPage({super.key, this.repository, this.creationService});

  final PaperFolderRepository? repository;
  final PaperCreationService? creationService;

  @override
  State<PaperFolderListPage> createState() => _PaperFolderListPageState();
}

class _PaperFolderListPageState extends State<PaperFolderListPage> {
  late final PaperFolderRepository _repository =
      widget.repository ?? PaperFolderRepository.local();
  late final PaperCreationService _creationService =
      widget.creationService ?? _buildCreationService();
  final AppSelectionController<int> _selection = AppSelectionController<int>();
  List<PaperFolderSummary>? _folders;
  String? _error;
  bool _working = false;

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

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  void _toggleSelection(int id) => setState(() => _selection.toggle(id));
  void _clearSelection() => setState(_selection.clear);

  List<PaperFolderSummary> get _selectedFolders => (_folders ?? const [])
      .where((folder) => _selection.isSelected(folder.id))
      .toList(growable: false);

  Future<List<SearchQuestion>> _selectedQuestions() async {
    final byId = <int, SearchQuestion>{};
    for (final folder in _selectedFolders) {
      final detail = await _repository.detail(folder.id);
      for (final question in detail.questions) {
        byId.putIfAbsent(question.id, () => question);
      }
    }
    return canonicalizePaperQuestions(
      byId.values,
      (question) => question.questionType,
    );
  }

  Future<void> _mergeSelected() async {
    final questions = await _selectedQuestions();
    if (!mounted || questions.isEmpty) return;
    final name = await AppDialog.prompt(
      context,
      title: '合并到新试题篮',
      initialValue: '合并试题篮',
      confirmLabel: '创建',
      validator: (value) => value.isEmpty ? '请输入名称' : null,
    );
    if (name == null || name.isEmpty) return;
    setState(() => _working = true);
    try {
      final id = await _repository.create(name);
      await _repository.addQuestions(id, questions.map((item) => item.id));
      if (!mounted) return;
      _clearSelection();
      await _load();
      if (!mounted) return;
      AppToast.success(
        context,
        '已合并 ${questions.length} 道不重复题目',
        actionLabel: '查看',
        onAction: () =>
            RouterUtils.push(context, '${AppRoutes.paperFolderDetail}?id=$id'),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _generateSelected() async {
    final questions = await _selectedQuestions();
    if (!mounted || questions.isEmpty) return;
    final draft = await showDialog<PaperDraft>(
      context: context,
      builder: (_) => PaperDraftDialog(
        initialName: '试题篮合并组卷',
        questions: questions,
        cost: paperCreationCost,
      ),
    );
    if (draft == null || !mounted) return;
    setState(() => _working = true);
    try {
      final id = await _creationService.createManualPaper(
        name: draft.name,
        selectedIds: draft.questions.map((item) => item.id).toList(),
      );
      if (!mounted) return;
      _clearSelection();
      RouterUtils.push(context, '${AppRoutes.examQuicklook}?id=$id');
    } on InsufficientPointsException catch (error) {
      if (mounted) {
        AppToast.warning(context, '积分不足，生成试卷需要 ${error.requiredPoints} 积分');
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _clearSelectedFolders() async {
    final selected = _selectedFolders;
    final total = selected.fold<int>(
      0,
      (sum, item) => sum + item.questionCount,
    );
    final confirmed = await AppDialog.confirm(
      context,
      title: '清空所选试题篮？',
      message: '将从 ${selected.length} 个试题篮移除 $total 道题，试题篮本身会保留。',
      icon: Icons.remove_shopping_cart_outlined,
      confirmLabel: '清空',
      destructive: true,
    );
    if (!confirmed) return;
    for (final folder in selected) {
      await _repository.replaceQuestions(folder.id, const []);
    }
    _clearSelection();
    await _load();
  }

  Future<void> _deleteSelectedFolders() async {
    final selected = _selectedFolders;
    final confirmed = await AppDialog.confirm(
      context,
      title: '删除所选试题篮？',
      message: '将删除 ${selected.length} 个试题篮，已生成的试卷不受影响。',
      icon: Icons.delete_outline,
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed) return;
    for (final folder in selected) {
      await _repository.delete(folder.id);
    }
    _clearSelection();
    await _load();
  }

  Future<void> _manageSelected() async {
    final action = await AppActionSheet.show<String>(
      context,
      title: '管理所选试题篮 · ${_selection.selectedCount} 个',
      items: const [
        AppActionSheetItem(
          value: 'generate',
          label: '用所含题目组卷',
          icon: Icons.description_outlined,
          detail: '合并并自动去重',
        ),
        AppActionSheetItem(
          value: 'merge',
          label: '合并到新试题篮',
          icon: Icons.create_new_folder_outlined,
          detail: '保留原试题篮',
        ),
        AppActionSheetItem(
          value: 'clear',
          label: '清空所选试题篮',
          icon: Icons.remove_shopping_cart_outlined,
          destructive: true,
        ),
        AppActionSheetItem(
          value: 'delete',
          label: '删除所选试题篮',
          icon: Icons.delete_outline,
          destructive: true,
        ),
      ],
    );
    if (!mounted || action == null) return;
    if (action == 'generate') await _generateSelected();
    if (action == 'merge') await _mergeSelected();
    if (action == 'clear') await _clearSelectedFolders();
    if (action == 'delete') await _deleteSelectedFolders();
  }

  Future<void> _load() async {
    try {
      final folders = await _repository.list();
      if (!mounted) return;
      setState(() {
        _folders = folders;
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = '试题篮加载失败，请稍后重试');
    }
  }

  Future<void> _create() async {
    final name = await AppDialog.prompt(
      context,
      title: '新建试题篮',
      initialValue: '新试题篮',
      confirmLabel: '创建',
      validator: (value) => value.isEmpty ? '请输入名称' : null,
    );
    if (name == null || name.isEmpty) return;
    final id = await _repository.create(name);
    if (!mounted) return;
    await RouterUtils.push(context, '${AppRoutes.paperFolderDetail}?id=$id');
    await _load();
  }

  Future<void> _rename(PaperFolderSummary folder) async {
    final name = await AppDialog.prompt(
      context,
      title: '重命名试题篮',
      initialValue: folder.name,
      confirmLabel: '保存',
      validator: (value) => value.isEmpty ? '请输入名称' : null,
    );
    if (name == null || name.isEmpty) return;
    await _repository.rename(folder.id, name);
    await _load();
  }

  Future<void> _delete(PaperFolderSummary folder) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: '删除试题篮？',
      message: '将删除“${folder.name}”，已生成的试卷不受影响。',
      icon: Icons.delete_outline_rounded,
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed) return;
    await _repository.delete(folder.id);
    await _load();
  }

  Future<void> _showFolderMenu(PaperFolderSummary folder) async {
    final action = await AppActionSheet.show<String>(
      context,
      title: folder.name,
      items: const [
        AppActionSheetItem(
          value: 'rename',
          label: '重命名',
          icon: Icons.edit_outlined,
        ),
        AppActionSheetItem(
          value: 'copy',
          label: '复制试题篮',
          icon: Icons.copy_outlined,
        ),
        AppActionSheetItem(
          value: 'delete',
          label: '删除试题篮',
          icon: Icons.delete_outline,
          destructive: true,
        ),
      ],
    );
    if (!mounted) return;
    if (action == 'rename') await _rename(folder);
    if (action == 'copy') {
      await _repository.copyFolder(folder.id);
      await _load();
    }
    if (action == 'delete') await _delete(folder);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('试题篮'),
      actions: [
        if (MediaQuery.sizeOf(context).width < 600)
          IconButton(
            tooltip: '新建试题篮',
            onPressed: _create,
            icon: const Icon(Icons.add_rounded),
          )
        else
          TextButton.icon(
            onPressed: _create,
            icon: const Icon(Icons.add_rounded),
            label: const Text('新建试题篮'),
          ),
      ],
    ),
    body: _error != null
        ? ErrorPlaceholder(message: _error!, onRetry: _load)
        : _folders == null
        ? const LoadingIndicator(message: '正在加载试题篮')
        : _folders!.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EmptyPlaceholder(
                  icon: Icons.folder_copy_outlined,
                  message: '还没有试题篮',
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: '新建试题篮',
                  icon: Icons.create_new_folder_outlined,
                  expanded: false,
                  onPressed: _create,
                ),
              ],
            ),
          )
        : Column(
            children: [
              Expanded(
                child: AppContentContainer(
                  maxWidth: AppContentWidth.standard,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    itemCount: _folders!.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final folder = _folders![index];
                      return GestureDetector(
                        onLongPress: () => _showFolderMenu(folder),
                        onSecondaryTap: () => _showFolderMenu(folder),
                        child: ListTile(
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(folder.name),
                          subtitle: Text(
                            '${folder.questionCount} 题 · ${_time(folder.updatedAt)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: '更多题篮操作',
                                icon: const Icon(Icons.more_horiz),
                                onPressed: () => _showFolderMenu(folder),
                              ),
                              AppSelectionToggle(
                                selected: _selection.isSelected(folder.id),
                                onPressed: () => _toggleSelection(folder.id),
                                selectTooltip: '选择试题篮',
                              ),
                            ],
                          ),
                          onTap: () async {
                            await RouterUtils.push(
                              context,
                              '${AppRoutes.paperFolderDetail}?id=${folder.id}',
                            );
                            await _load();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              AppSelectionActionBar(
                selectedCount: _selection.selectedCount,
                totalCount: _folders!.length,
                itemUnit: ' 个',
                onSelectAll: () => setState(
                  () => _selection.selectAll(_folders!.map((item) => item.id)),
                ),
                onClear: _clearSelection,
                actionLabel: '管理试题篮',
                actionIcon: Icons.folder_copy_outlined,
                actionLoading: _working,
                onAction: _working ? null : _manageSelected,
              ),
            ],
          ),
  );

  String _time(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
