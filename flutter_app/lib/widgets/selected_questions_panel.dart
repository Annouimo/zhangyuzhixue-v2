import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../data/api/api_client.dart';
import '../data/api/user_api.dart';
import '../data/daos/exam_dao.dart';
import '../data/daos/question_dao.dart';
import '../data/daos/user_dao.dart';
import '../data/database/database_provider.dart';
import '../domain/exam_repository.dart';
import '../domain/paper_creation_service.dart';
import '../domain/paper_folder_repository.dart';
import '../domain/paper_question_order.dart';
import '../domain/user_repository.dart';
import '../pages/question_bank/paper_draft_dialog.dart';
import '../pages/router.dart';

class SelectedQuestionsBasketItem {
  const SelectedQuestionsBasketItem({
    required this.id,
    required this.name,
    required this.questionCount,
    required this.containedCount,
  });

  final int id;
  final String name;
  final int questionCount;
  final int containedCount;
}

class SelectedQuestionsPanelResult {
  const SelectedQuestionsPanelResult({
    required this.updates,
    required this.createPaper,
  });

  final Map<int, bool> updates;
  final bool createPaper;
}

Future<SelectedQuestionsPanelResult?> showSelectedQuestionsPanel({
  required BuildContext context,
  required int selectedCount,
  required List<SelectedQuestionsBasketItem> items,
  required Future<SelectedQuestionsBasketItem?> Function() onCreateBasket,
}) {
  final panel = SelectedQuestionsPanel(
    selectedCount: selectedCount,
    items: items,
    onCreateBasket: onCreateBasket,
  );
  if (MediaQuery.sizeOf(context).width < 600) {
    return showModalBottomSheet<SelectedQuestionsPanelResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(heightFactor: 0.9, child: panel),
    );
  }
  return showDialog<SelectedQuestionsPanelResult>(
    context: context,
    builder: (_) => AppDialogFrame(child: SizedBox(height: 680, child: panel)),
  );
}

class SelectedQuestionsPanel extends StatefulWidget {
  const SelectedQuestionsPanel({
    super.key,
    required this.selectedCount,
    required this.items,
    required this.onCreateBasket,
  });

  final int selectedCount;
  final List<SelectedQuestionsBasketItem> items;
  final Future<SelectedQuestionsBasketItem?> Function() onCreateBasket;

  @override
  State<SelectedQuestionsPanel> createState() => _SelectedQuestionsPanelState();
}

class _SelectedQuestionsPanelState extends State<SelectedQuestionsPanel> {
  late final List<SelectedQuestionsBasketItem> _items = List.of(widget.items);
  final Map<int, bool> _updates = {};

  bool? _value(SelectedQuestionsBasketItem item) {
    final update = _updates[item.id];
    if (update != null) return update;
    if (item.containedCount == 0) return false;
    if (item.containedCount == widget.selectedCount) return true;
    return null;
  }

  void _toggle(SelectedQuestionsBasketItem item) {
    final current = _value(item);
    setState(() => _updates[item.id] = current == true ? false : true);
  }

  Future<void> _create() async {
    final item = await widget.onCreateBasket();
    if (item == null || !mounted) return;
    setState(() {
      _items.insert(0, item);
      _updates[item.id] = true;
    });
  }

  (int, int) get _changes {
    var additions = 0;
    var removals = 0;
    for (final item in _items) {
      final update = _updates[item.id];
      if (update == true) {
        additions += widget.selectedCount - item.containedCount;
      }
      if (update == false) removals += item.containedCount;
    }
    return (additions, removals);
  }

  void _finish(bool createPaper) => Navigator.pop(
    context,
    SelectedQuestionsPanelResult(
      updates: Map.unmodifiable(_updates),
      createPaper: createPaper,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final (additions, removals) = _changes;
    return Material(
      color: context.colors.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '管理已选题目',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '已选择 ${widget.selectedCount} 道题',
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: context.colors.border),
              ),
              leading: Icon(Icons.add_rounded, color: context.colors.primary),
              title: const Text('新建试题篮'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _create,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return CheckboxListTile(
                  tristate: true,
                  value: _value(item),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.questionCount} 道题 · 已选题中 ${item.containedCount}/${widget.selectedCount} 道在其中',
                  ),
                  onChanged: (_) => _toggle(item),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.colors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '将加入 $additions 个题次，并移除 $removals 个题次',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: '保存所在试题篮',
                    icon: Icons.save_outlined,
                    type: AppButtonType.secondary,
                    onPressed: _updates.isEmpty ? null : () => _finish(false),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label:
                        '用所选 ${widget.selectedCount} 道题组卷 · $paperCreationCost 积分',
                    icon: Icons.description_outlined,
                    onPressed: () => _finish(true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> manageSelectedQuestions({
  required BuildContext context,
  required PaperFolderRepository repository,
  required Set<int> questionIds,
}) async {
  if (questionIds.isEmpty) return false;
  var folders = await repository.list();
  if (folders.isEmpty) {
    await repository.defaultFolderId();
    folders = await repository.list();
  }
  final items = await Future.wait(
    folders.map((folder) async {
      final detail = await repository.detail(folder.id);
      return SelectedQuestionsBasketItem(
        id: folder.id,
        name: folder.name,
        questionCount: folder.questionCount,
        containedCount: detail.questions
            .where((question) => questionIds.contains(question.id))
            .length,
      );
    }),
  );
  if (!context.mounted) return false;
  final result = await showSelectedQuestionsPanel(
    context: context,
    selectedCount: questionIds.length,
    items: items,
    onCreateBasket: () async {
      final name = await showCreateBasketDialog(context);
      if (name == null || name.isEmpty) return null;
      final id = await repository.create(name);
      return SelectedQuestionsBasketItem(
        id: id,
        name: name,
        questionCount: 0,
        containedCount: 0,
      );
    },
  );
  if (result == null) return false;
  await repository.setQuestionsFolderMembership(questionIds, result.updates);
  if (!context.mounted) return false;
  if (result.createPaper) {
    final created = await _createPaperFromQuestions(context, questionIds);
    return created || result.updates.isNotEmpty;
  } else {
    AppToast.success(context, '所在试题篮已保存');
  }
  return true;
}

Future<String?> showCreateBasketDialog(BuildContext context) {
  return AppDialog.prompt(
    context,
    title: '新建试题篮',
    initialValue: '新试题篮',
    confirmLabel: '创建',
    validator: (value) => value.isEmpty ? '请输入名称' : null,
  );
}

Future<bool> _createPaperFromQuestions(
  BuildContext context,
  Set<int> questionIds,
) async {
  final provider = DatabaseProvider();
  final questionDao = QuestionDao(provider);
  final rows = await questionDao.getByIds(questionIds.toList());
  final questions = canonicalizePaperQuestions(
    rows.map(
      (row) => SearchQuestion(
        id: row.id,
        title: row.stem,
        meta: '${row.year} ${row.examType} ${row.region}',
        questionType: row.questionType,
        difficulty: row.difficulty ?? 0,
        calculation: row.calculation ?? 0,
      ),
    ),
    (question) => question.questionType,
  );
  if (!context.mounted || questions.isEmpty) return false;
  final draft = await showDialog<PaperDraft>(
    context: context,
    builder: (_) => PaperDraftDialog(
      initialName: '手动组卷',
      questions: questions,
      cost: paperCreationCost,
    ),
  );
  if (draft == null || !context.mounted) return false;
  final service = PaperCreationService(
    ExamRepository(questionDao, ExamDao(provider)),
    UserRepository(UserDao(provider), UserApi(ApiClient()), questionDao),
    provider,
  );
  try {
    final id = await service.createManualPaper(
      name: draft.name,
      selectedIds: draft.questions.map((item) => item.id).toList(),
    );
    if (context.mounted) {
      RouterUtils.push(context, '${AppRoutes.examQuicklook}?id=$id');
    }
    return true;
  } on InsufficientPointsException catch (error) {
    if (context.mounted) {
      AppToast.warning(context, '积分不足，生成试卷需要 ${error.requiredPoints} 积分');
    }
    return false;
  }
}
