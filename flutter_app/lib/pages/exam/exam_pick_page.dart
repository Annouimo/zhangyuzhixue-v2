import 'package:flutter/material.dart';
import 'dart:async';
import '../../../app_theme.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/exam_repository.dart';
import '../../../domain/preference_repository.dart';
import '../../../data/daos/preference_dao.dart';
import '../../../widgets/shared/loading_indicator.dart';
import '../../../widgets/shared/empty_placeholder.dart';
import '../../../widgets/md_latex_body.dart';
import 'widgets/filter_panel.dart';
import 'widgets/preference_dialog_helper.dart';
import '../../data/debug/audit_logger.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/user_api.dart';
import '../../../data/daos/user_dao.dart';
import '../../../domain/user_repository.dart';
import '../../../data/database/app_database.dart' as app_db;
import 'package:drift/drift.dart' hide Column;

/// 自主选题积分消耗常量
const _kPickPaperCost = 20;

/// 自主选题
class ExamPickPage extends StatefulWidget {
  final ExamRepository? examRepository;
  final PreferenceRepository? preferenceRepository;
  final UserRepository? userRepository;
  const ExamPickPage({super.key, this.examRepository, this.preferenceRepository, this.userRepository});

  @override
  State<ExamPickPage> createState() => _ExamPickPageState();
}

class _ExamPickPageState extends State<ExamPickPage> {
  late final ExamRepository _repo;
  final _filterKey = GlobalKey<FilterPanelState>();
  late final PreferenceRepository _prefRepo = widget.preferenceRepository ??
      PreferenceRepository(PreferenceDao(DatabaseProvider().appDb));
  late final UserRepository _userRepo = widget.userRepository ??
      UserRepository(UserDao(DatabaseProvider().appDb), UserApi(ApiClient()), QuestionDao(DatabaseProvider().assetsDb));
  FilterOptions? _filterOpts;
  bool _loadingOpts = true;
  List<SearchQuestion>? _questions;
  bool _loadingQ = false;
  final _selectedIds = <int>{};
  final _nameController = TextEditingController(text: '智能练习卷');
  bool _saving = false;
  Set<String> _years = {}, _regions = {}, _conceptTags = {};
  Set<String> _selectedTypes = {}, _selectedExamTypes = {}, _selectedKnowledgeCards = {};
  double _diffMin = 0, _diffMax = 10, _calcMin = 0, _calcMax = 10;
  Timer? _debouncedSearch;

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.examRepository ?? ExamRepository(QuestionDao(db.assetsDb), ExamDao(db.appDb));
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
    } catch (e) { AuditLogger.instance.error('ExamPickPage._loadFilterOptions', e); if (mounted) setState(() { _loadingOpts = false; }); }
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
    } catch (e) { AuditLogger.instance.error('ExamPickPage._search', e); if (mounted) setState(() => _loadingQ = false); }
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
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _saving = true);
    try {
      await _repo.confirm(SearchFilters(name: _nameController.text, choiceCount: _selectedIds.length, fillCount: 0, solutionCount: 0,
        targetDifficulty: 0, years: [], regions: [], conceptTags: [], knowledgeCards: [], selectedIds: _selectedIds.toList()));
      // 扣分
      final now = DateTime.now().toIso8601String();
      final db = DatabaseProvider();
      await db.appDb.into(db.appDb.pointsTransactions).insert(
        app_db.PointsTransactionsCompanion(
          amount: const Value(-_kPickPaperCost),
          source: const Value('PAPER_PURCHASE'),
          transactionType: const Value('SPEND'),
          createdAt: Value(now),
          description: const Value('自主选题'),
        ),
      );
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('组卷成功！'), behavior: SnackBarBehavior.floating));
      }
      setState(() => _saving = false);
    } catch (e) {
      AuditLogger.instance.error('ExamPickPage._save', e);
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating));
      }
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('自主选题')),
    body: _loadingOpts
        ? const LoadingIndicator()
        : LayoutBuilder(builder: (context, constraints) {
            AuditLogger.instance.page('ExamPickPage.body', {
              'w': constraints.maxWidth,
              'h': constraints.maxHeight,
              'hasInfiniteW': constraints.maxWidth.isInfinite,
            });
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: _buildScrollContent()),
            Container(
              color: Colors.white,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('已选 ${_selectedIds.length} 题',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  SizedBox(
                    width: 140,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: (_selectedIds.isEmpty || _saving) ? null : _save,
                      child: _saving
                          ? const SizedBox(width: 20, height: 20,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: '试卷名称',
          hintText: '输入试卷名称',
          border: OutlineInputBorder(),
        ),
      ),
    );

    final filterPanel = _filterOpts != null
        ? FilterPanel(
            key: _filterKey,
            yearOptions: _filterOpts!.years,
            regionOptions: _filterOpts!.regions,
            conceptTagOptions: _filterOpts!.conceptTags,
            examTypeOptions: _filterOpts!.examTypes,
            knowledgeCardOptions: _filterOpts!.knowledgeCards,
            onSavePreference: _savePreference,
            onLoadPreference: _loadPreference,
            onChanged: (y, r, t, ct, et, kc, dmn, dmx, cmn, cmx) {
            _years = y; _regions = r; _conceptTags = ct;
            _selectedTypes = t; _selectedExamTypes = et; _selectedKnowledgeCards = kc;
            _diffMin = dmn; _diffMax = dmx; _calcMin = cmn; _calcMax = cmx;
            _debouncedSearch?.cancel();
            _debouncedSearch = Timer(const Duration(milliseconds: 300), _search);
            },
          )
        : null;

    if (_loadingQ) {
      return const Center(child: LoadingIndicator(message: '搜索中…'));
    }

    // 组装：filterPanel 在顶部，下方根据状态切换
    final headerChildren = <Widget>[
      nameField,
      if (filterPanel != null) filterPanel,
    ];

    if (_questions == null) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          ...headerChildren,
          const SizedBox(height: 80),
          const Center(child: EmptyPlaceholder(icon: Icons.search, message: '设置筛选条件后搜索')),
        ],
      );
    }
    if (_questions!.isEmpty) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          ...headerChildren,
          const SizedBox(height: 80),
          const Center(child: EmptyPlaceholder(icon: Icons.mail_outline, message: '未找到匹配的题目')),
        ],
      );
    }
    // 有搜索结果
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _questions!.length + headerChildren.length,
      itemBuilder: (context, index) {
        if (index < headerChildren.length) {
          return headerChildren[index];
        }
        final qIdx = index - headerChildren.length;
        final q = _questions![qIdx];
        final sel = _selectedIds.contains(q.id);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: InkWell(
            onTap: () => setState(() {
              if (sel) { _selectedIds.remove(q.id); } else { _selectedIds.add(q.id); }
            }),
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MdLatexBody(q.title, fontSize: 14),
                    const SizedBox(height: 4),
                    Text(q.meta, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                )),
                Icon(sel ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: sel ? AppColors.primary : AppColors.textSecondary, size: 24),
              ]),
            ),
          ),
        );
      },
    );
  }
}
