import 'package:flutter/material.dart';
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
import '../../data/debug/audit_logger.dart';

/// 自主选题
class ExamPickPage extends StatefulWidget {
  final ExamRepository? examRepository;
  final PreferenceRepository? preferenceRepository;
  const ExamPickPage({super.key, this.examRepository, this.preferenceRepository});

  @override
  State<ExamPickPage> createState() => _ExamPickPageState();
}

class _ExamPickPageState extends State<ExamPickPage> {
  late final ExamRepository _repo;
  final _filterKey = GlobalKey<FilterPanelState>();
  late final PreferenceRepository _prefRepo = widget.preferenceRepository ??
      PreferenceRepository(PreferenceDao(DatabaseProvider().appDb));
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
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('保存为学习偏好'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            hintText: '偏好名称（如"北京高考模拟"）',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ctx.mounted) Navigator.of(ctx).pop();
            }),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ctx.mounted) Navigator.of(ctx).pop(nameCtrl.text);
            }),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    if (name == null || name.trim().isEmpty) return;
    await _prefRepo.save(
      name: name.trim(),
      filter: PreferenceFilter(
        years: state.selectedYears.toList(),
        regions: state.selectedRegions.toList(),
        conceptTags: state.selectedConceptTags.toList(),
        types: state.selectedExamTypes.toList(),
        knowledgeCards: state.selectedKnowledgeCards.toList(),
        questionTypes: state.selectedTypes.toList(),
        diffMin: state.diffMin,
        diffMax: state.diffMax,
        calcMin: state.calcMin,
        calcMax: state.calcMax,
      ),
    );
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
    if (presets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无保存的学习偏好'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择学习偏好'),
        children: presets.map((p) => SimpleDialogOption(
          onPressed: () => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ctx.mounted) Navigator.of(ctx).pop(p.id);
          }),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500)),
              if (p.summary.isNotEmpty)
                Text(p.summary, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        )).toList(),
      ),
    );
    if (selected == null) return;
    final filter = await _prefRepo.getEdit(selected);
    if (!context.mounted) return;
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
    setState(() => _saving = true);
    try {
      await _repo.confirm(SearchFilters(name: _nameController.text, choiceCount: _selectedIds.length, fillCount: 0, solutionCount: 0,
        targetDifficulty: 0, years: [], regions: [], conceptTags: [], knowledgeCards: [], selectedIds: _selectedIds.toList()));
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
            },
          )
        : null;

    final searchButton = _filterOpts != null
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(onPressed: _search, child: const Text('搜索')),
          )
        : null;

    if (_loadingQ) {
      return const Center(child: LoadingIndicator(message: '搜索中…'));
    }

    // 组装：filterPanel + searchButton 在顶部，下方根据状态切换
    final headerChildren = <Widget>[
      nameField,
      if (filterPanel != null) filterPanel,
      if (searchButton != null) searchButton,
    ];

    if (_questions == null) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          ...headerChildren,
          const SizedBox(height: 80),
          const Center(child: EmptyPlaceholder(icon: '🔍', message: '设置筛选条件后搜索')),
        ],
      );
    }
    if (_questions!.isEmpty) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          ...headerChildren,
          const SizedBox(height: 80),
          const Center(child: EmptyPlaceholder(icon: '📭', message: '未找到匹配的题目')),
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
