import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/exam_repository.dart';
import '../../../widgets/shared/loading_indicator.dart';
import '../../../widgets/shared/empty_placeholder.dart';
import '../../../widgets/md_latex_body.dart';
import 'widgets/filter_panel.dart';
import '../../data/debug/audit_logger.dart';

/// 自主选题
class ExamPickPage extends StatefulWidget {
  final ExamRepository? examRepository;
  const ExamPickPage({super.key, this.examRepository});

  @override
  State<ExamPickPage> createState() => _ExamPickPageState();
}

class _ExamPickPageState extends State<ExamPickPage> {
  late final ExamRepository _repo;
  FilterOptions? _filterOpts;
  bool _loadingOpts = true;
  List<SearchQuestion>? _questions;
  bool _loadingQ = false;
  final _selectedIds = <int>{};
  bool _saving = false;
  Set<String> _years = {}, _regions = {}, _conceptTags = {};
  double _diffMin = 0, _diffMax = 10, _calcMin = 0, _calcMax = 10;

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.examRepository ?? ExamRepository(QuestionDao(db.assetsDb), ExamDao(db.appDb));
    _loadFilterOptions();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final opts = await _repo.getFilterOptions();
      if (!mounted) return;
      setState(() { _filterOpts = opts; _loadingOpts = false; });
      AuditLogger.instance.page('ExamPickPage', {'totalCount': _questions?.length});
    } catch (_) { if (mounted) setState(() { _loadingOpts = false; }); }
  }

  Future<void> _search() async {
    setState(() => _loadingQ = true);
    try {
      final filters = SearchFilters(name: '', choiceCount: 0, fillCount: 0, solutionCount: 0, targetDifficulty: 0,
        years: _years.toList(), regions: _regions.toList(), conceptTags: _conceptTags.toList(), knowledgeCards: [],
        diffMin: _diffMin, diffMax: _diffMax, calcMin: _calcMin, calcMax: _calcMax);
      final qs = await _repo.getFilteredQuestions(filters);
      if (!mounted) return;
      setState(() { _questions = qs; _loadingQ = false; });
    } catch (_) { if (mounted) setState(() => _loadingQ = false); }
  }

  Future<void> _save() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _repo.confirm(SearchFilters(name: '', choiceCount: _selectedIds.length, fillCount: 0, solutionCount: 0,
        targetDifficulty: 0, years: [], regions: [], conceptTags: [], knowledgeCards: [], selectedIds: _selectedIds.toList()));
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('组卷成功！'), behavior: SnackBarBehavior.floating));
      }
      setState(() => _saving = false);
    } catch (e) {
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
    body: _loadingOpts ? const LoadingIndicator() : Column(children: [
      Expanded(child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _filterOpts != null
          ? FilterPanel(yearOptions: _filterOpts!.years, regionOptions: _filterOpts!.regions,
              conceptTagOptions: _filterOpts!.conceptTags,
              onChanged: (y, r, t, ct, dmn, dmx, cmn, cmx) { _years = y; _regions = r; _conceptTags = ct; _diffMin = dmn; _diffMax = dmx; _calcMin = cmn; _calcMax = cmx; })
          : const SizedBox.shrink()),
        if (_filterOpts != null) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _search, child: const Text('搜索'))))),
        if (_loadingQ) const SliverFillRemaining(child: LoadingIndicator(message: '搜索中…'))
        else if (_questions == null) const SliverFillRemaining(child: EmptyPlaceholder(icon: '🔍', message: '设置筛选条件后搜索'))
        else if (_questions!.isEmpty) const SliverFillRemaining(child: EmptyPlaceholder(icon: '📭', message: '未找到匹配的题目'))
        else SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
          final q = _questions![i];
          final sel = _selectedIds.contains(q.id);
          return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: InkWell(
            onTap: () => setState(() { if (sel) { _selectedIds.remove(q.id); } else { _selectedIds.add(q.id); } }),
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                MdLatexBody(q.title, fontSize: 14), const SizedBox(height: 4),
                Text(q.meta, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ])),
              Icon(sel ? Icons.check_circle : Icons.radio_button_unchecked, color: sel ? AppColors.primary : AppColors.textSecondary, size: 24),
            ]))));
        }, childCount: _questions!.length)),
      ])),
      Container(width: double.infinity, color: Colors.white, padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: Text('已选 ${_selectedIds.length} 题', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
        ElevatedButton(onPressed: (_selectedIds.isEmpty || _saving) ? null : _save, child: _saving
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text('确认组卷 (${_selectedIds.length})')),
      ])),
    ]),
  );
}
