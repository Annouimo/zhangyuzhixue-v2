import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../router.dart';
import '../../../app_theme.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/exam_repository.dart';
import '../../../domain/preference_repository.dart';
import '../../../data/daos/preference_dao.dart';
import '../../../widgets/shared/loading_indicator.dart';
import 'widgets/filter_panel.dart';
import 'widgets/preference_dialog_helper.dart';
import 'widgets/difficulty_slider.dart';
import '../../../data/debug/audit_logger.dart';
import '../../../data/sync/sync_manager.dart';
import '../../../data/sync/sync_types.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/user_api.dart';
import '../../../data/daos/user_dao.dart';
import '../../../domain/user_repository.dart';
import '../../../data/database/app_database.dart' as app_db;
import 'package:drift/drift.dart' hide Column;

/// 智能组卷积分消耗常量
const _kAutoPaperCost = 10; // 智能组卷消耗 10 积分

/// 智能组卷
class ExamAutoPage extends StatefulWidget {
  final ExamRepository? examRepository;
  final PreferenceRepository? preferenceRepository;
  final UserRepository? userRepository;
  const ExamAutoPage({super.key, this.examRepository, this.preferenceRepository, this.userRepository});

  @override
  State<ExamAutoPage> createState() => _ExamAutoPageState();
}

class _ExamAutoPageState extends State<ExamAutoPage> {
  late final ExamRepository _repo;
  final _filterKey = GlobalKey<FilterPanelState>();
  late final PreferenceRepository _prefRepo = widget.preferenceRepository ??
      PreferenceRepository(PreferenceDao(DatabaseProvider().appDb));
  FilterOptions? _filterOpts;
  bool _loadingOpts = true;
  final _nameController = TextEditingController(text: '智能练习卷');
  int _choiceCount = 10, _fillCount = 5, _solutionCount = 6;
  double _targetDifficulty = 5;
  bool _generating = false;
  Set<String> _years = {}, _regions = {}, _conceptTags = {};
  Set<String> _selectedTypes = {}, _selectedExamTypes = {}, _selectedKnowledgeCards = {};
  double _diffMin = 0, _diffMax = 10, _calcMin = 0, _calcMax = 10;
  PoolStats? _poolStats;

  late final UserRepository _userRepo = widget.userRepository ??
      UserRepository(UserDao(DatabaseProvider().appDb), UserApi(ApiClient()), QuestionDao(DatabaseProvider().assetsDb));

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.examRepository ?? ExamRepository(
      QuestionDao(db.assetsDb), ExamDao(db.appDb),
    );
    _loadFilterOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final opts = await _repo.getFilterOptions();
      if (!mounted) return;
      setState(() { _filterOpts = opts; _loadingOpts = false; });
      AuditLogger.instance.page('ExamAutoPage', {'count': _choiceCount, 'difficulty': _targetDifficulty});
      _updatePoolStats();
    } catch (e) { AuditLogger.instance.error('ExamAutoPage._loadFilterOptions', e); if (mounted) setState(() { _loadingOpts = false; }); }
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
        const SnackBar(content: Text('偏好已保存'), behavior: SnackBarBehavior.floating),
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
    } catch (_) {}
  }

  Future<void> _confirm() async {
    // 积分检查
    final available = await _userRepo.availablePoints();
    if (available < _kAutoPaperCost) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('积分不足，智能组卷需要 $_kAutoPaperCost 积分'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _generating = true);
    try {
      final filters = SearchFilters(
        name: _nameController.text, choiceCount: _choiceCount, fillCount: _fillCount,
        solutionCount: _solutionCount, targetDifficulty: _targetDifficulty,
        years: _years.toList(), regions: _regions.toList(),
        conceptTags: _conceptTags.toList(), knowledgeCards: _selectedKnowledgeCards.toList(),
        diffMin: _diffMin, diffMax: _diffMax, calcMin: _calcMin, calcMax: _calcMax,
        examTypes: _selectedExamTypes.isNotEmpty ? _selectedExamTypes.toList() : null,
        questionTypes: _selectedTypes.isNotEmpty ? _selectedTypes.toList() : null,
      );
      final paperId = await _repo.confirm(filters);
      // 扣分
      final now = DateTime.now().toIso8601String();
      final db = DatabaseProvider();
      final pointId = await db.appDb.into(db.appDb.pointsTransactions).insert(
        app_db.PointsTransactionsCompanion(
          amount: const Value(-_kAutoPaperCost * 1.0),
          source: const Value('PAPER_PURCHASE'),
          transactionType: const Value('SPEND'),
          createdAt: Value(now),
          description: const Value('智能组卷'),
        ),
      );
      // 入同步队列
      try {
        await SyncManager().enqueue(
          entityType: SyncEntityType.pointsTransaction,
          operation: SyncOperationType.upsert,
          localId: pointId,
          payload: jsonEncode({
            'amount': -_kAutoPaperCost * 1.0,
            'source': 'PAPER_PURCHASE',
            'transaction_type': 'SPEND',
            'description': '智能组卷',
            'created_at': now,
          }),
        );
      } catch (_) {}
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('组卷成功！'), behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: '查看', onPressed: () => context.push('${AppRoutes.examQuicklook}?id=$paperId')),
          ),
        );
      }
    } catch (e) {
      AuditLogger.instance.error('ExamAutoPage._confirm', e);
      if (mounted && context.mounted) {
        final msg = e is InsufficientPoolException ? e.message : '$e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
        );
      }
    } finally { if (mounted) setState(() => _generating = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('智能组卷')),
    body: _loadingOpts
        ? const LoadingIndicator()
        : Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '试卷名称',
                          hintText: '输入试卷名称',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    if (_filterOpts != null)
                      FilterPanel(
                        key: _filterKey,
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
                        onChanged: (state) async {
                          setState(() { _years = state.years; _regions = state.regions;
                            _conceptTags = state.conceptTags;
                            _selectedTypes = state.types; _selectedExamTypes = state.examTypes; _selectedKnowledgeCards = state.knowledgeCards;
                            _diffMin = state.diffMin; _diffMax = state.diffMax; _calcMin = state.calcMin; _calcMax = state.calcMax; });
                          _updatePoolStats();
                        },
                      ),
                    // 池统计
                    if (_poolStats != null)
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              _statChip('选择', _poolStats!.availableChoice),
                              const SizedBox(width: 8),
                              _statChip('填空', _poolStats!.availableFill),
                              const SizedBox(width: 8),
                              _statChip('解答', _poolStats!.availableSolution),
                            ],
                          ),
                        ),
                      ),
                    // 题型配比 Card
                    Card(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('题型配比', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            _countStepper('选择题', _choiceCount, (v) => _choiceCount = v, availableCount: _poolStats?.availableChoice ?? 0),
                            _countStepper('填空题', _fillCount, (v) => _fillCount = v, availableCount: _poolStats?.availableFill ?? 0),
                            _countStepper('解答题', _solutionCount, (v) => _solutionCount = v, availableCount: _poolStats?.availableSolution ?? 0),
                            const Text('难度调优（可选）', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('设置目标平均难度，系统自动挑选最接近的题目组合',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            DifficultySlider(
                              label: '目标难度', min: 0, max: 10,
                              lower: _targetDifficulty, upper: _targetDifficulty,
                              onChanged: (v) => setState(() => _targetDifficulty = v.start),
                            ),
                            if (_poolStats != null) ...[
                              const SizedBox(height: 4),
                              Text('当前筛选池：${_poolStats!.poolDiffMin.toStringAsFixed(2)} — ${_poolStats!.poolDiffMax.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              Text('高考全卷参考：最小 ${_poolStats!.gaokaoDiffMin.toStringAsFixed(2)} · 平均 ${_poolStats!.gaokaoDiffAvg.toStringAsFixed(2)} · 最大 ${_poolStats!.gaokaoDiffMax.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity, color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _generating ? null : _confirm,
                  child: _generating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('确认组卷'),
                ),
              ),
            ],
          ),
  );

  Widget _statChip(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label $count', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
    );
  }

  Widget _countStepper(String label, int count, ValueChanged<int> onChanged, {int availableCount = 0}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: count > 0 ? () => setState(() => onChanged(count - 1)) : null),
          SizedBox(width: 32, child: Center(child: Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
          IconButton(icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: count < 30 ? () => setState(() => onChanged(count + 1)) : null),
          if (availableCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('（可用 $availableCount 题）', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }
}
