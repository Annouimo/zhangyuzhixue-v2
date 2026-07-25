import 'package:flutter/material.dart';
import 'dart:convert';
import '../router.dart';
import 'package:shared/shared.dart';
import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/exam_repository.dart';
import '../../domain/preference_repository.dart';
import '../../data/daos/preference_dao.dart';
import 'widgets/preference_dialog_helper.dart';
import '../../widgets/shortfall_dialog.dart';
import '../../data/sync/sync_manager.dart';
import '../../data/sync/sync_types.dart';
import '../../data/api/api_client.dart';
import '../../data/api/user_api.dart';
import '../../data/daos/user_dao.dart';
import '../../domain/user_repository.dart';
import '../../data/database/app_database.dart' as app_db;
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
      PreferenceRepository(PreferenceDao(DatabaseProvider()));
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
      UserRepository(UserDao(DatabaseProvider()), UserApi(ApiClient()), QuestionDao(DatabaseProvider()));

  @override
  void initState() {
    super.initState();
    _repo = widget.examRepository ?? ExamRepository(
      QuestionDao(DatabaseProvider()), ExamDao(DatabaseProvider()),
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
    } catch (e) { AuditLogger.instance.error('ExamAutoPage._loadFilterOptions', e); OperationLog.instance.error('ExamAutoPage._loadFilterOptions', e); if (mounted) setState(() { _loadingOpts = false; }); }
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
            backgroundColor: context.colors.error,
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
      OperationLog.instance.action('exam_auto', 'created paperId=$paperId');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('组卷成功！'), behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: '查看', onPressed: () => RouterUtils.push(context,'${AppRoutes.examQuicklook}?id=$paperId')),
          ),
        );
      }
    } catch (e) {
      AuditLogger.instance.error('ExamAutoPage._confirm', e);
      OperationLog.instance.error('ExamAutoPage._confirm', e);
      if (mounted && context.mounted) {
        if (e is InsufficientPoolException) {
          await showShortfallDialog(context, type: e.type, needed: e.needed, available: e.available);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    } finally { if (mounted) setState(() => _generating = false); }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _choiceCount + _fillCount + _solutionCount;

    return Scaffold(
      appBar: AppBar(title: const Text('智能组卷')),
      body: _loadingOpts
          ? const LoadingIndicator(message: '加载组卷条件…')
          : Column(
              children: [
                Expanded(
                  child: AppContentContainer(
                    maxWidth: AppContentWidth.standard,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      children: [
                        AppFeatureBanner(
                          eyebrow: '智能配题',
                          icon: Icons.auto_awesome_rounded,
                          title: '告诉系统你想练什么',
                          subtitle: '设置范围、题型数量和目标难度，系统会从当前题库中挑选最接近目标的组合。',
                          footer: Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              AppStatusBadge(
                                label: '预计 $totalCount 题',
                                tone: AppStatusTone.info,
                                icon: Icons.format_list_numbered_rounded,
                                compact: true,
                              ),
                              const AppStatusBadge(
                                label: '消耗 $_kAutoPaperCost 积分',
                                tone: AppStatusTone.recommendation,
                                icon: Icons.toll_rounded,
                                compact: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const AppSectionHeader(
                          title: '试卷信息',
                          subtitle: '名称可以在创建前随时修改。',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: '试卷名称',
                            hintText: '例如：函数与导数专项练习',
                            prefixIcon: Icon(Icons.edit_note_rounded),
                          ),
                        ),
                        if (_filterOpts != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          FilterPanel(
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
                            onChanged: (state) async {
                              setState(() {
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
                              });
                              _updatePoolStats();
                            },
                          ),
                        ],
                        if (_poolStats != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppSectionHeader(
                                  title: '当前筛选池',
                                  subtitle: '可用题量会随筛选条件实时更新。',
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
                        const SizedBox(height: AppSpacing.sm),
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppSectionHeader(
                                title: '题型与难度',
                                subtitle: '先确定题量，再让系统围绕目标难度进行调优。',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _countStepper(
                                '选择题',
                                _choiceCount,
                                (value) => _choiceCount = value,
                                availableCount: _poolStats?.availableChoice ?? 0,
                              ),
                              _countStepper(
                                '填空题',
                                _fillCount,
                                (value) => _fillCount = value,
                                availableCount: _poolStats?.availableFill ?? 0,
                              ),
                              _countStepper(
                                '解答题',
                                _solutionCount,
                                (value) => _solutionCount = value,
                                availableCount: _poolStats?.availableSolution ?? 0,
                              ),
                              const Divider(height: AppSpacing.xl),
                              Text(
                                '目标平均难度',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                '系统会优先选择整体难度最接近目标的题目组合。',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              DifficultySlider(
                                label: '目标难度',
                                min: 0,
                                max: 10,
                                lower: _targetDifficulty,
                                upper: _targetDifficulty,
                                onChanged: (value) => setState(
                                  () => _targetDifficulty = value.start,
                                ),
                              ),
                              if (_poolStats != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '筛选池难度 ${_poolStats!.poolDiffMin.toStringAsFixed(2)}—${_poolStats!.poolDiffMax.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                Text(
                                  '高考参考：最小 ${_poolStats!.gaokaoDiffMin.toStringAsFixed(2)} · 平均 ${_poolStats!.gaokaoDiffAvg.toStringAsFixed(2)} · 最大 ${_poolStats!.gaokaoDiffMax.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
                _buildBottomAction(totalCount),
              ],
            ),
    );
  }

  Widget _buildBottomAction(int totalCount) {
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
                        '共 $totalCount 题',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '创建后消耗 $_kAutoPaperCost 积分',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AppButton(
                  label: '确认组卷',
                  icon: Icons.auto_awesome_rounded,
                  isLoading: _generating,
                  onPressed: _generating ? null : _confirm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, int count) => AppStatusBadge(
        label: '$label $count',
        tone: count > 0 ? AppStatusTone.info : AppStatusTone.neutral,
        icon: Icons.inventory_2_outlined,
        compact: true,
      );

  Widget _countStepper(
    String label,
    int count,
    ValueChanged<int> onChanged, {
    int availableCount = 0,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                if (availableCount > 0)
                  Text(
                    '当前可用 $availableCount 题',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton.outlined(
            tooltip: '减少$label',
            icon: const Icon(Icons.remove_rounded),
            onPressed: count > 0
                ? () => setState(() => onChanged(count - 1))
                : null,
          ),
          SizedBox(
            width: 52,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                  ),
            ),
          ),
          IconButton.filledTonal(
            tooltip: '增加$label',
            icon: const Icon(Icons.add_rounded),
            onPressed: count < 30
                ? () => setState(() => onChanged(count + 1))
                : null,
          ),
        ],
      ),
    );
  }
}
