import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:convert';
import '../router.dart';
import 'package:shared/theme/app_theme.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/exam_repository.dart';
import '../../../domain/preference_repository.dart';
import '../../../data/daos/preference_dao.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/empty_placeholder.dart';
import 'package:shared/widgets/question_card.dart';
import '../../../widgets/shortfall_dialog.dart';
import 'package:shared/widgets/filter_panel.dart';
import 'widgets/preference_dialog_helper.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import '../../data/sync/sync_manager.dart';
import '../../data/sync/sync_types.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/user_api.dart';
import '../../../data/daos/user_dao.dart';
import '../../../domain/user_repository.dart';
import '../../../data/database/app_database.dart' as app_db;
import 'package:drift/drift.dart' hide Column;

/// 自主选题积分消耗常量
const _kPickPaperCost = 20; // 自主选题消耗 20 积分

/// 自主选题
class ExamPickPage extends StatefulWidget {
  final ExamRepository? examRepository;
  final PreferenceRepository? preferenceRepository;
  final UserRepository? userRepository;
  ExamPickPage({super.key, this.examRepository, this.preferenceRepository, this.userRepository});

  @override
  State<ExamPickPage> createState() => _ExamPickPageState();
}

class _ExamPickPageState extends State<ExamPickPage> {
  late final ExamRepository _repo;
  final _filterKey = GlobalKey<FilterPanelState>();
  late final PreferenceRepository _prefRepo = widget.preferenceRepository ??
      PreferenceRepository(PreferenceDao(DatabaseProvider()));
  late final UserRepository _userRepo = widget.userRepository ??
      UserRepository(UserDao(DatabaseProvider()), UserApi(ApiClient()), QuestionDao(DatabaseProvider()));
  FilterOptions? _filterOpts;
  bool _loadingOpts = true;
  List<SearchQuestion>? _questions;
  bool _loadingQ = false;
  final _selectedIds = <int>{};
  final _nameController = TextEditingController(text: '自主选题卷');
  bool _saving = false;
  Set<String> _years = {}, _regions = {}, _conceptTags = {};
  Set<String> _selectedTypes = {}, _selectedExamTypes = {}, _selectedKnowledgeCards = {};
  double _diffMin = 0, _diffMax = 10, _calcMin = 0, _calcMax = 10;
  Timer? _debouncedSearch;
  PoolStats? _poolStats;

  @override
  void initState() {
    super.initState();
    _repo = widget.examRepository ?? ExamRepository(QuestionDao(DatabaseProvider()), ExamDao(DatabaseProvider()));
    _loadFilterOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _debouncedSearch?.cancel();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final opts = await _repo.getFilterOptions();
      if (!mounted) return;
      setState(() { _filterOpts = opts; _loadingOpts = false; });
      AuditLogger.instance.page('ExamPickPage', {'totalCount': _questions?.length});
    } catch (e) { AuditLogger.instance.error('ExamPickPage._loadFilterOptions', e); OperationLog.instance.error('ExamPickPage._loadFilterOptions', e); if (mounted) setState(() { _loadingOpts = false; }); }
  }

  Future<void> _updatePoolStats() async {
    try {
      final filters = SearchFilters(
        name: _nameController.text, choiceCount: 0, fillCount: 0, solutionCount: 0, targetDifficulty: 0,
        years: _years.toList(), regions: _regions.toList(), conceptTags: _conceptTags.toList(),
        knowledgeCards: _selectedKnowledgeCards.toList(),
        diffMin: _diffMin, diffMax: _diffMax, calcMin: _calcMin, calcMax: _calcMax,
        examTypes: _selectedExamTypes.isNotEmpty ? _selectedExamTypes.toList() : null,
        questionTypes: _selectedTypes.isNotEmpty ? _selectedTypes.toList() : null,
      );
      final stats = await _repo.getPoolStats(filters);
      if (mounted) setState(() => _poolStats = stats);
    } catch (e) { AuditLogger.instance.error('ExamPickPage._updatePoolStats', e); }
  }

  /// 保存当前筛选条件为学习偏好
  Future<void> _savePreference() async {
    final state = _filterKey.currentState;
    if (state == null) return;
    if (!context.mounted) return;
    final name = await showSavePreferenceDialog(context);
    if (name == null || name.trim().isEmpty) return;
    await _prefRepo.save(name: name.trim(), filter: buildPreferenceFilter(state));
    if (context.mounted) {
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
    if (!context.mounted) return;
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
      final filters = SearchFilters(name: _nameController.text, choiceCount: 0, fillCount: 0, solutionCount: 0, targetDifficulty: 0,
        years: _years.toList(), regions: _regions.toList(), conceptTags: _conceptTags.toList(), knowledgeCards: _selectedKnowledgeCards.toList(),
        diffMin: _diffMin, diffMax: _diffMax, calcMin: _calcMin, calcMax: _calcMax,
        examTypes: _selectedExamTypes.isNotEmpty ? _selectedExamTypes.toList() : null,
        questionTypes: _selectedTypes.isNotEmpty ? _selectedTypes.toList() : null,
      );
      final qs = await _repo.getFilteredQuestions(filters);
      if (!mounted) return;
      setState(() { _questions = qs; _loadingQ = false; });
      _selectedIds.retainAll(qs.map((q) => q.id).toList());
      _updatePoolStats();
    } catch (e) { AuditLogger.instance.error('ExamPickPage._search', e); OperationLog.instance.error('ExamPickPage._search', e); if (mounted) setState(() => _loadingQ = false); }
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
      pointId = await db.appDb.into(db.appDb.pointsTransactions).insert(
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
        choiceCount: 0, fillCount: 0, solutionCount: 0,
        targetDifficulty: 0,
        years: _years.toList(), regions: _regions.toList(),
        conceptTags: _conceptTags.toList(), knowledgeCards: _selectedKnowledgeCards.toList(),
        diffMin: _diffMin, diffMax: _diffMax, calcMin: _calcMin, calcMax: _calcMax,
        examTypes: _selectedExamTypes.isNotEmpty ? _selectedExamTypes.toList() : null,
        questionTypes: _selectedTypes.isNotEmpty ? _selectedTypes.toList() : null,
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
              onPressed: () => RouterUtils.push(context,'${AppRoutes.examQuicklook}?id=$paperId'),
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
          await (DatabaseProvider().appDb.delete(DatabaseProvider().appDb.pointsTransactions)
            ..where((t) => t.id.equals(pid))).go();
        } catch (_) {}
      }
      AuditLogger.instance.error('ExamPickPage._save', e);
      OperationLog.instance.error('ExamPickPage._save', e);
      if (mounted && context.mounted) {
        if (e is InsufficientPoolException) {
          await showShortfallDialog(context, type: e.type, needed: e.needed, available: e.available);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating));
        }
      }
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('自主选题')),
    body: _loadingOpts
        ? LoadingIndicator()
        : LayoutBuilder(builder: (context, constraints) {
            AuditLogger.instance.page('ExamPickPage.body', {
              'w': constraints.maxWidth,
              'h': constraints.maxHeight,
              'hasInfiniteW': constraints.maxWidth.isInfinite,
            });
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: _buildScrollContent()),
            Container(
              color: context.colors.surface,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('已选 ${_selectedIds.length} 题',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  SizedBox(
                    width: 140,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: (_selectedIds.isEmpty || _saving) ? null : _save,
                      child: _saving
                          ? SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('确认组卷 (${_selectedIds.length})'),
                    ),
                  ),
                ],
              ),
            ),
          ]);
        },
      ),
  );

  Widget _buildScrollContent() {
    final nameField = Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: TextField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: '试卷名称',
          hintText: '输入试卷名称',
          border: OutlineInputBorder(),
        ),
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
            _years = state.years; _regions = state.regions; _conceptTags = state.conceptTags;
            _selectedTypes = state.types; _selectedExamTypes = state.examTypes; _selectedKnowledgeCards = state.knowledgeCards;
            _diffMin = state.diffMin; _diffMax = state.diffMax; _calcMin = state.calcMin; _calcMax = state.calcMax;
            _debouncedSearch?.cancel();
            _debouncedSearch = Timer(Duration(milliseconds: 300), () { _search(); });
            },
          )
        : null;

    if (_loadingQ) {
      return Center(child: LoadingIndicator(message: '搜索中…'));
    }

    // 组装：filterPanel + 池统计 在顶部，下方根据状态切换
    final headerChildren = <Widget>[
      nameField,
      if (filterPanel != null) filterPanel,
      if (_poolStats != null)
        Card(
          margin: const EdgeInsets.fromLTRB(0, 4, 0, 0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            side: BorderSide(color: context.colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _statChip('选择', _poolStats!.availableChoice),
                SizedBox(width: 8),
                _statChip('填空', _poolStats!.availableFill),
                SizedBox(width: 8),
                _statChip('解答', _poolStats!.availableSolution),
              ],
            ),
          ),
        ),
    ];

    if (_questions == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        children: [
          ...headerChildren,
          SizedBox(height: 80),
          Center(child: EmptyPlaceholder(icon: Icons.search, message: '请设置筛选条件后搜索题目')),
        ],
      );
    }
    if (_questions!.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        children: [
          ...headerChildren,
          SizedBox(height: 80),
          Center(child: EmptyPlaceholder(icon: Icons.mail_outline, message: '未找到匹配的题目，试试调整筛选条件')),
        ],
      );
    }
    // 有搜索结果
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      itemCount: _questions!.length + headerChildren.length,
      itemBuilder: (context, index) {
        if (index < headerChildren.length) {
          return headerChildren[index];
        }
        final qIdx = index - headerChildren.length;
        final q = _questions![qIdx];
        final sel = _selectedIds.contains(q.id);
        return QuestionCard(
          questionId: q.id,
          title: q.title,
          questionType: q.questionType,
          subtitle: q.meta,
          difficulty: q.difficulty,
          selectable: true,
          selected: sel,
          onTap: () => setState(() {
            if (sel) { _selectedIds.remove(q.id); } else { _selectedIds.add(q.id); }
          }),
        );
      },
    );
  }

  Widget _statChip(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label $count', style: TextStyle(fontSize: 12, color: context.colors.primary, fontWeight: FontWeight.w500)),
    );
  }
}


