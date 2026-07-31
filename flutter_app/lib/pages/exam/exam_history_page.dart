import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/exam_repository.dart';
import '../../domain/paper_folder_repository.dart';
import '../../widgets/shared/async_load_widget.dart';
import '../router.dart';
import 'widgets/paper_card.dart';

/// 我的组卷列表。
class ExamHistoryPage extends StatefulWidget {
  const ExamHistoryPage({
    super.key,
    this.examRepository,
    this.paperFolderRepository,
    this.embedded = false,
  });

  final ExamRepository? examRepository;
  final PaperFolderRepository? paperFolderRepository;
  final bool embedded;

  @override
  State<ExamHistoryPage> createState() => _ExamHistoryPageState();
}

class _ExamHistoryPageState extends State<ExamHistoryPage> {
  late final ExamRepository _repo;
  late final PaperFolderRepository _folderRepo;
  final AppSelectionController<int> _selection = AppSelectionController<int>();
  final GlobalKey<AsyncLoadWidgetState<List<ExamSummary>>> _loadKey =
      GlobalKey();

  @override
  void initState() {
    super.initState();
    _repo =
        widget.examRepository ??
        ExamRepository(
          QuestionDao(DatabaseProvider()),
          ExamDao(DatabaseProvider()),
        );
    _folderRepo = widget.paperFolderRepository ?? PaperFolderRepository.local();
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  void _toggleSelection(int id) => setState(() => _selection.toggle(id));
  void _clearSelection() => setState(_selection.clear);

  Future<void> _setVisibility(List<ExamSummary> list, bool isPublic) async {
    final selected = list.where((item) => _selection.isSelected(item.id));
    var changed = 0;
    for (final exam in selected) {
      if (exam.isPublic == isPublic) continue;
      await _repo.togglePublic(exam.id);
      changed++;
    }
    _clearSelection();
    _loadKey.currentState?.refresh();
    if (mounted) {
      AppToast.success(
        context,
        changed == 0 ? '所选试卷状态无需修改' : '已更新 $changed 份试卷',
      );
    }
  }

  Future<void> _mergeToBasket(List<ExamSummary> list) async {
    final selected = list.where((item) => _selection.isSelected(item.id));
    final questionIds = <int>{};
    for (final exam in selected) {
      final preview = await _repo.getPreview(exam.id);
      questionIds.addAll(
        preview.questions.map((question) => question.questionId),
      );
    }
    if (!mounted || questionIds.isEmpty) return;
    final name = await AppDialog.prompt(
      context,
      title: '合并到新试题篮',
      initialValue: '我的试卷合并',
      confirmLabel: '创建',
      validator: (value) => value.isEmpty ? '请输入名称' : null,
    );
    if (name == null || name.isEmpty) return;
    final folderId = await _folderRepo.create(name);
    await _folderRepo.addQuestions(folderId, questionIds);
    if (!mounted) return;
    _clearSelection();
    AppToast.success(
      context,
      '已合并 ${questionIds.length} 道不重复题目',
      actionLabel: '查看试题篮',
      onAction: () => RouterUtils.push(
        context,
        '${AppRoutes.paperFolderDetail}?id=$folderId',
      ),
    );
  }

  Future<void> _deleteSelected(List<ExamSummary> list) async {
    final selected = list
        .where((item) => _selection.isSelected(item.id))
        .toList();
    final confirmed = await AppDialog.confirm(
      context,
      title: '删除所选试卷？',
      message: '将永久删除 ${selected.length} 份试卷，删除后无法恢复。',
      icon: Icons.delete_outline,
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed) return;
    for (final exam in selected) {
      await _repo.deleteExam(exam.id);
    }
    _clearSelection();
    _loadKey.currentState?.refresh();
  }

  Future<void> _manageSelected(List<ExamSummary> list) async {
    final action = await AppActionSheet.show<String>(
      context,
      title: '管理所选试卷 · ${_selection.selectedCount} 份',
      items: const [
        AppActionSheetItem(
          value: 'public',
          label: '全部设为公开',
          icon: Icons.public,
        ),
        AppActionSheetItem(
          value: 'private',
          label: '全部设为私密',
          icon: Icons.lock_outline,
        ),
        AppActionSheetItem(
          value: 'merge',
          label: '合并题目到新试题篮',
          icon: Icons.create_new_folder_outlined,
          detail: '自动按题目去重',
        ),
        AppActionSheetItem(
          value: 'delete',
          label: '删除所选试卷',
          icon: Icons.delete_outline,
          destructive: true,
        ),
      ],
    );
    if (!mounted || action == null) return;
    if (action == 'public') await _setVisibility(list, true);
    if (action == 'private') await _setVisibility(list, false);
    if (action == 'merge') await _mergeToBasket(list);
    if (action == 'delete') await _deleteSelected(list);
  }

  String _formatTime(String iso) {
    try {
      return iso.substring(0, 16).replaceFirst('T', ' ');
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = AsyncLoadWidget<List<ExamSummary>>(
      contentIsScrollable: true,
      key: _loadKey,
      onLoad: _repo.getMyExams,
      emptyWidget: EmptyPlaceholder(
        icon: Icons.description_outlined,
        message: '还没有创建过试卷，前往题库与组卷创建吧',
      ),
      builder: (ctx, list) {
        _selection.retain(list.map((item) => item.id));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AuditLogger.instance.page('ExamHistoryPage', {'total': list.length});
        });
        return Column(
          children: [
            Expanded(
              child: AppContentContainer(
                maxWidth: AppContentWidth.standard,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (ctx, index) {
                    final exam = list[index];
                    final selected = _selection.isSelected(exam.id);
                    return PaperCard(
                      title: exam.name,
                      selected: selected,
                      subtitle: '创建于 ${_formatTime(exam.createdAt)}',
                      trailingWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppStatusBadge(
                            label: exam.isPublic ? '公开' : '私密',
                            tone: exam.isPublic
                                ? AppStatusTone.success
                                : AppStatusTone.neutral,
                            icon: exam.isPublic
                                ? Icons.public
                                : Icons.lock_outline,
                            compact: true,
                          ),
                          AppSelectionToggle(
                            selected: selected,
                            onPressed: () => _toggleSelection(exam.id),
                            selectTooltip: '选择试卷',
                          ),
                        ],
                      ),
                      onTap: () => RouterUtils.push(
                        context,
                        '${AppRoutes.examQuicklook}?id=${exam.id}',
                      ),
                    );
                  },
                ),
              ),
            ),
            AppSelectionActionBar(
              selectedCount: _selection.selectedCount,
              totalCount: list.length,
              itemUnit: ' 份',
              onSelectAll: () => setState(
                () => _selection.selectAll(list.map((item) => item.id)),
              ),
              onClear: _clearSelection,
              actionLabel: '管理试卷',
              actionIcon: Icons.description_outlined,
              onAction: () => _manageSelected(list),
            ),
          ],
        );
      },
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('已生成')),
      body: body,
    );
  }
}
