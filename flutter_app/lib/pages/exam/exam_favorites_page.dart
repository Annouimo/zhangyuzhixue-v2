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

/// 我的收藏。
class ExamFavoritesPage extends StatefulWidget {
  const ExamFavoritesPage({
    super.key,
    this.examRepository,
    this.paperFolderRepository,
    this.embedded = false,
  });

  final ExamRepository? examRepository;
  final PaperFolderRepository? paperFolderRepository;
  final bool embedded;

  @override
  State<ExamFavoritesPage> createState() => _ExamFavoritesPageState();
}

class _ExamFavoritesPageState extends State<ExamFavoritesPage> {
  late final ExamRepository _repo;
  late final PaperFolderRepository _folderRepo;
  final AppSelectionController<int> _selection = AppSelectionController<int>();
  final GlobalKey<AsyncLoadWidgetState<List<FavoriteExamSummary>>> _loadKey =
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

  void _selectAll(Iterable<int> ids) =>
      setState(() => _selection.selectAll(ids));

  void _clearSelection() => setState(_selection.clear);

  Future<void> _removeSelected(List<FavoriteExamSummary> list) async {
    final selected = list
        .where((item) => _selection.isSelected(item.id))
        .toList(growable: false);
    final confirmed = await AppDialog.confirm(
      context,
      title: '取消收藏所选试卷？',
      message: '将从收藏中移除 ${selected.length} 份试卷。',
      icon: Icons.star_outline_rounded,
      confirmLabel: '取消收藏',
      destructive: true,
    );
    if (!confirmed) return;
    for (final exam in selected) {
      await _repo.toggleCollect(exam.id);
    }
    _clearSelection();
    _loadKey.currentState?.refresh();
    if (mounted) AppToast.success(context, '已取消收藏 ${selected.length} 份试卷');
  }

  Future<void> _mergeToBasket(List<FavoriteExamSummary> list) async {
    final selected = list.where((item) => _selection.isSelected(item.id));
    final questionIds = <int>{};
    for (final exam in selected) {
      final preview = await _repo.getPreviewOther(exam.id);
      questionIds.addAll(
        preview.questions.map((question) => question.questionId),
      );
    }
    if (!mounted || questionIds.isEmpty) return;
    final name = await AppDialog.prompt(
      context,
      title: '合并到新试题篮',
      initialValue: '收藏试卷合并',
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

  Future<void> _manageSelected(List<FavoriteExamSummary> list) async {
    final action = await AppActionSheet.show<String>(
      context,
      title: '管理所选收藏 · ${_selection.selectedCount} 份',
      items: const [
        AppActionSheetItem(
          value: 'merge',
          label: '合并题目到新试题篮',
          icon: Icons.create_new_folder_outlined,
          detail: '自动按题目去重',
        ),
        AppActionSheetItem(
          value: 'remove',
          label: '取消收藏',
          icon: Icons.star_outline_rounded,
          destructive: true,
        ),
      ],
    );
    if (!mounted || action == null) return;
    if (action == 'merge') await _mergeToBasket(list);
    if (action == 'remove') await _removeSelected(list);
  }

  Future<void> _removeCollect(FavoriteExamSummary exam) async {
    _loadKey.currentState?.optimisticUpdate((list) {
      list.removeWhere((item) => item.id == exam.id);
      return list;
    });
    await _repo.toggleCollect(exam.id);
    if (!mounted) return;
    AppToast.info(
      context,
      '已取消收藏',
      actionLabel: '撤销',
      onAction: () async {
        await _repo.toggleCollect(exam.id);
        _loadKey.currentState?.refresh();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = AsyncLoadWidget<List<FavoriteExamSummary>>(
      contentIsScrollable: true,
      key: _loadKey,
      onLoad: _repo.getFavorites,
      emptyWidget: EmptyPlaceholder(
        icon: Icons.star_border_rounded,
        message: '还没有收藏试卷，可以去发现页看看',
      ),
      builder: (ctx, list) {
        _selection.retain(list.map((item) => item.id));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AuditLogger.instance.page('ExamFavoritesPage', {
            'total': list.length,
          });
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
                      subtitle: exam.authorInfo.isNotEmpty
                          ? exam.authorInfo
                          : exam.summary,
                      trailingWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: '取消收藏',
                            icon: Icon(
                              Icons.star_rounded,
                              color: context.colors.primary,
                            ),
                            onPressed: () => _removeCollect(exam),
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
                        '${AppRoutes.examQuicklookOther}?id=${exam.id}',
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
              onSelectAll: () => _selectAll(list.map((item) => item.id)),
              onClear: _clearSelection,
              actionLabel: '管理收藏',
              actionIcon: Icons.star_outline_rounded,
              onAction: () => _manageSelected(list),
            ),
          ],
        );
      },
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('收藏')),
      body: body,
    );
  }
}
