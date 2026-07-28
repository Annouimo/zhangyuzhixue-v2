import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../router.dart';
import 'package:shared/shared.dart';
import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/exam_repository.dart';
import '../../domain/preference_repository.dart';
import '../../data/daos/preference_dao.dart';
import '../../widgets/shortfall_dialog.dart';
import 'widgets/preference_dialog_helper.dart';
import '../../data/sync/sync_manager.dart';
import '../../data/sync/sync_types.dart';
import '../../data/api/api_client.dart';
import '../../data/api/user_api.dart';
import '../../data/daos/user_dao.dart';
import '../../domain/user_repository.dart';
import '../../data/database/app_database.dart' as app_db;
import 'package:drift/drift.dart' hide Column;
import '../../widgets/question_search_field.dart';
import '../../widgets/question_search_results.dart';
import '../question_bank/question_detail_page.dart';

/// 自主选题积分消耗常量
const _kPickPaperCost = 20; // 自主选题消耗 20 积分

/// 自主选题
class ExamPickPage extends StatefulWidget {
  final ExamRepository? examRepository;
  final PreferenceRepository? preferenceRepository;
  final UserRepository? userRepository;
  const ExamPickPage({
    super.key,
    this.examRepository,
    this.preferenceRepository,
    this.userRepository,
  });

  @override
  State<ExamPickPage> createState() => _ExamPickPageState();
}

class _ExamPickPageState extends State<ExamPickPage> {
  late final ExamRepository _repo;
  final _filterKey = GlobalKey<FilterPanelState>();
  late final PreferenceRepository _prefRepo =
      widget.preferenceRepository ??
      PreferenceRepository(PreferenceDao(DatabaseProvider()));
  late final UserRepository _userRepo =
      widget.userRepository ??
      UserRepository(
        UserDao(DatabaseProvider()),
        UserApi(ApiClient()),
        QuestionDao(DatabaseProvider()),
      );
  FilterOptions? _filterOpts;
  bool _loadingOpts = true;
  List<SearchQuestion>? _questions;
  bool _loadingQ = false;
  final _selectedIds = <int>{};
  final _nameController = TextEditingController(text: '自主选题卷');
  final _queryController = TextEditingController();
  bool _saving = false;
  Set<String> _years = {}, _regions = {}, _conceptTags = {};
  Set<String> _selectedTypes = {},
      _selectedExamTypes = {},
      _selectedKnowledgeCards = {};
  double _diffMin = 0, _diffMax = 10, _calcMin = 0, _calcMax = 10;
  Timer? _debouncedSearch;
  PoolStats? _poolStats;

  @override
  void initState() {
    super.initState();
    _repo =
        widget.examRepository ??
        ExamRepository(
          QuestionDao(DatabaseProvider()),
          ExamDao(DatabaseProvider()),
        );
    _loadFilterOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _queryController.dispose();
    _debouncedSearch?.cancel();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final opts = await _repo.getFilterOptions();
      if (!mounted) return;
      setState(() {
        _filterOpts = opts;
        _loadingOpts = false;
      });
      AuditLogger.instance.page('ExamPickPage', {
        'totalCount': _questions?.length,
      });
    } catch (e) {
      AuditLogger.instance.error('ExamPickPage._loadFilterOptions', e);
      OperationLog.instance.error('ExamPickPage._loadFilterOptions', e);
      if (mounted) {
        setState(() {
          _loadingOpts = false;
        });
      }
    }
  }

  Future<void> _updatePoolStats() async {
    try {
      final filters = SearchFilters(
        name: _nameController.text,
        keyword: _queryController.text,
        choiceCount: 0,
        fillCount: 0,
        solutionCount: 0,
        targetDifficulty: 0,
        years: _years.toList(),
        regions: _regions.toList(),
        conceptTags: _conceptTags.toList(),
        knowledgeCards: _selectedKnowledgeCards.toList(),
        diffMin: _diffMin,
        diffMax: _diffMax,
        calcMin: _calcMin,
        calcMax: _calcMax,
        examTypes: _selectedExamTypes.isNotEmpty
            ? _selectedExamTypes.toList()
            : null,
        questionTypes: _selectedTypes.isNotEmpty
            ? _selectedTypes.toList()
            : null,
      );
      final stats = await _repo.getPoolStats(filters);
      if (mounted) setState(() => _poolStats = stats);
    } catch (e) {
      AuditLogger.instance.error('ExamPickPage._updatePoolStats', e);
    }
  }

  /// 保存当前筛选条件为学习偏好
  Future<void> _savePreference() async {
    final state = _filterKey.currentState;
    if (state == null) return;
    if (!mounted) return;
    final name = await showSavePreferenceDialog(context);
    if (name == null || name.trim().isEmpty) return;
    await _prefRepo.save(
      name: name.trim(),
      filter: buildPreferenceFilter(state),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('偏好已保存'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  /// 读取学习偏好并应用到筛选面板
  Future<void> _loadPreference() async {
    final state = _filterKey.currentState;
    if (state == null) return;
    final presets = await _prefRepo.getList();
    if (!mounted) return;
    final selected = await showLoadPreferenceDialog(context, presets);
    if (selected == null) return;
    final editData = await _prefRepo.getEdit(selected);
    if (!context.mounted) return;
    final filter = editData.filter;
    state.applyFilter(
      years: filter.years.toSet(),
      regions: filter.regions.toSet(),
      conceptTags: filter.conceptTags.toSet(),
      examTypes: filter.types.toSet(),
      knowledgeCards: filter.knowledgeCards.toSet(),
      types: filter.questionTypes.toSet(),
      diffMin: filter.diffMin,
      diffMax: filter.diffMax,
      calcMin: filter.calcMin,
      calcMax: filter.calcMax,
    );
  }

  Future<void> _search() async {
    setState(() => _loadingQ = true);
    try {
      final filters = SearchFilters(
        name: _nameController.text,
        keyword: _queryController.text,
        choiceCount: 0,
        fillCount: 0,
        solutionCount: 0,
        targetDifficulty: 0,
        years: _years.toList(),
        regions: _regions.toList(),
        conceptTags: _conceptTags.toList(),
        knowledgeCards: _selectedKnowledgeCards.toList(),
        diffMin: _diffMin,
        diffMax: _diffMax,
        calcMin: _calcMin,
        calcMax: _calcMax,
        examTypes: _selectedExamTypes.isNotEmpty
            ? _selectedExamTypes.toList()
            : null,
        questionTypes: _selectedTypes.isNotEmpty
            ? _selectedTypes.toList()
            : null,
      );
      final qs = await _repo.getFilteredQuestions(filters);
      if (!mounted) return;
      setState(() {
        _questions = qs;
        _loadingQ = false;
      });
      _selectedIds.retainAll(qs.map((q) => q.id).toList());
      _updatePoolStats();
    } catch (e) {
      AuditLogger.instance.error('ExamPickPage._search', e);
      OperationLog.instance.error('ExamPickPage._search', e);
      if (mounted) setState(() => _loadingQ = false);
    }
  }

  Future<void> _save() async {
    if (_selectedIds.isEmpty) return;
    // 积分检查
    final available = await _userRepo.availablePoints();
    if (available < _kPickPaperCost) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('积分不足，自主选题需要 $_kPickPaperCost 积分'),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _saving = true);
    // 先扣分，后组卷——遇失败回滚积分流水
    int? pointId;
    try {
      final now = DateTime.now().toIso8601String();
      final db = DatabaseProvider();
      // 1. 扣分
      pointId = await db.appDb
          .into(db.appDb.pointsTransactions)
          .insert(
            app_db.PointsTransactionsCompanion(
              amount: Value(-_kPickPaperCost * 1.0),
              source: Value('PAPER_PURCHASE'),
              transactionType: Value('SPEND'),
              createdAt: Value(now),
              description: Value('自主选题'),
            ),
          );
      // 2. 组卷
      final filters = SearchFilters(
        name: _nameController.text,
        keyword: _queryController.text,
        choiceCount: 0,
        fillCount: 0,
        solutionCount: 0,
        targetDifficulty: 0,
        years: _years.toList(),
        regions: _regions.toList(),
        conceptTags: _conceptTags.toList(),
        knowledgeCards: _selectedKnowledgeCards.toList(),
        diffMin: _diffMin,
        diffMax: _diffMax,
        calcMin: _calcMin,
        calcMax: _calcMax,
        examTypes: _selectedExamTypes.isNotEmpty
            ? _selectedExamTypes.toList()
            : null,
        questionTypes: _selectedTypes.isNotEmpty
            ? _selectedTypes.toList()
            : null,
        selectedIds: _selectedIds.toList(),
      );
      final paperId = await _repo.confirm(filters);
      OperationLog.instance.action('exam_pick', 'saved paperId=$paperId');
      // 3. 入同步队列（积分流水）
      try {
        await SyncManager().enqueue(
          entityType: SyncEntityType.pointsTransaction,
          operation: SyncOperationType.upsert,
          localId: pointId,
          payload: jsonEncode({
            'amount': -_kPickPaperCost * 1.0,
            'source': 'PAPER_PURCHASE',
            'transaction_type': 'SPEND',
            'description': '自主选题',
            'created_at': now,
          }),
        );
      } catch (_) {}
      // 4. 成功
      if (!mounted) return;
      _selectedIds.clear();
      _nameController.clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('组卷成功！'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '查看',
              onPressed: () => RouterUtils.push(
                context,
                '${AppRoutes.examQuicklook}?id=$paperId',
              ),
            ),
          ),
        );
      }
      setState(() => _saving = false);
    } catch (e) {
      // 回滚积分流水（如果扣了分但组卷失败）
      if (pointId != null) {
        try {
          final pid = pointId;
          await (DatabaseProvider().appDb.delete(
            DatabaseProvider().appDb.pointsTransactions,
          )..where((t) => t.id.equals(pid))).go();
        } catch (_) {}
      }
      AuditLogger.instance.error('ExamPickPage._save', e);
      OperationLog.instance.error('ExamPickPage._save', e);
      if (mounted && context.mounted) {
        if (e is InsufficientPoolException) {
          await showShortfallDialog(
            context,
            type: e.type,
            needed: e.needed,
            available: e.available,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
          );
        }
      }
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('自主选题')),
    body: _loadingOpts
        ? const LoadingIndicator(message: '加载题库条件…')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AppContentContainer(
                  maxWidth: AppContentWidth.standard,
                  child: _buildScrollContent(),
                ),
              ),
              _buildBottomAction(),
            ],
          ),
  );

  Widget _buildBottomAction() {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: AppContentContainer(
            maxWidth: AppContentWidth.standard,
            useSafeArea: false,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '已选 ${_selectedIds.length} 题',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '创建时消耗 $_kPickPaperCost 积分',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AppButton(
                  label: '确认组卷',
                  icon: Icons.playlist_add_check_rounded,
                  fullWidth: false,
                  isLoading: _saving,
                  onPressed: (_selectedIds.isEmpty || _saving) ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollContent() {
    final nameField = TextField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: '试卷名称',
        hintText: '例如：周末自主选题卷',
        prefixIcon: Icon(Icons.edit_note_rounded),
      ),
    );

    final filterPanel = _filterOpts != null
        ? FilterPanel(
            key: _filterKey,
            horizontalMargin: 0,
            yearOptions: _filterOpts!.years,
            regionOptions: _filterOpts!.regions,
            typeOptions: _filterOpts!.questionTypes,
            conceptTagOptions: _filterOpts!.conceptTags,
            conceptTagTree: _filterOpts!.conceptTagTree,
            examTypeOptions: _filterOpts!.examTypes,
            knowledgeCardOptions: _filterOpts!.knowledgeCards,
            knowledgeCardGroups: _filterOpts!.knowledgeCardGroups,
            onSavePreference: _savePreference,
            onLoadPreference: _loadPreference,
            onChanged: (state) {
              _years = state.years;
              _regions = state.regions;
              _conceptTags = state.conceptTags;
              _selectedTypes = state.types;
              _selectedExamTypes = state.examTypes;
              _selectedKnowledgeCards = state.knowledgeCards;
              _diffMin = state.diffMin;
              _diffMax = state.diffMax;
              _calcMin = state.calcMin;
              _calcMax = state.calcMax;
              _debouncedSearch?.cancel();
              _debouncedSearch = Timer(
                const Duration(milliseconds: 300),
                _search,
              );
            },
          )
        : null;

    final searchField = QuestionSearchField(
      controller: _queryController,
      onChanged: (_) {
        _debouncedSearch?.cancel();
        _debouncedSearch = Timer(const Duration(milliseconds: 300), _search);
      },
      onSubmitted: (_) => _search(),
    );

    if (_loadingQ) {
      return const Center(child: LoadingIndicator(message: '搜索题目…'));
    }

    final headerChildren = <Widget>[
      const SizedBox(height: AppSpacing.md),
      const AppSectionHeader(title: '试卷信息与筛选', subtitle: '修改条件后会自动重新搜索。'),
      const SizedBox(height: AppSpacing.sm),
      nameField,
      const SizedBox(height: AppSpacing.sm),
      searchField,
      if (filterPanel != null) ...[
        const SizedBox(height: AppSpacing.sm),
        filterPanel,
      ],
      if (_poolStats != null) ...[
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(
                title: '当前筛选池',
                subtitle: '下面是各题型可供选择的数量。',
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _statChip('选择题', _poolStats!.availableChoice),
                  _statChip('填空题', _poolStats!.availableFill),
                  _statChip('解答题', _poolStats!.availableSolution),
                ],
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      AppSectionHeader(
        title: _questions == null ? '题目结果' : '题目结果 · ${_questions!.length} 题',
        subtitle: '点击题目卡片即可加入或移出试卷。',
      ),
      const SizedBox(height: AppSpacing.sm),
    ];

    if (_questions == null) {
      return ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          ...headerChildren,
          const SizedBox(height: AppSpacing.lg),
          EmptyPlaceholder(
            icon: Icons.manage_search_rounded,
            message: '设置筛选条件后，这里会显示匹配题目',
          ),
        ],
      );
    }
    if (_questions!.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          ...headerChildren,
          const SizedBox(height: AppSpacing.lg),
          EmptyPlaceholder(
            icon: Icons.search_off_rounded,
            message: '没有找到匹配题目，请放宽筛选条件',
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: _questions!.length + headerChildren.length,
      itemBuilder: (context, index) {
        if (index < headerChildren.length) return headerChildren[index];
        final question = _questions![index - headerChildren.length];
        final selected = _selectedIds.contains(question.id);
        return QuestionSearchResultCard(
          question: question,
          selected: selected,
          onOpen: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  StudentQuestionDetailPage(questionId: question.id),
            ),
          ),
          onToggle: () => setState(() {
            if (selected) {
              _selectedIds.remove(question.id);
            } else {
              _selectedIds.add(question.id);
            }
          }),
        );
      },
    );
  }

  Widget _statChip(String label, int count) => AppStatusBadge(
    label: '$label $count',
    tone: count > 0 ? AppStatusTone.info : AppStatusTone.neutral,
    icon: Icons.inventory_2_outlined,
    compact: true,
  );
}
