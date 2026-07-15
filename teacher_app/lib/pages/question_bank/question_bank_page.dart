import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../app_theme.dart';
import '../../domain/question_repository.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/empty_placeholder.dart';
import '../../widgets/question_card.dart';
import '../../widgets/filter_panel.dart';
import 'preview_page.dart';

/// 题库浏览 — 教师端选题页
class QuestionBankPage extends StatefulWidget {
  final QuestionRepository? questionRepository;
  const QuestionBankPage({super.key, this.questionRepository});

  @override
  State<QuestionBankPage> createState() => _QuestionBankPageState();
}

class _QuestionBankPageState extends State<QuestionBankPage> {
  late final QuestionRepository _repo;
  final _filterKey = GlobalKey<FilterPanelState>();
  FilterOptions? _filterOpts;
  bool _loadingOpts = true;
  List<SearchQuestion>? _questions;
  bool _loadingQ = false;
  final _selectedIds = <int>{};
  bool _saving = false;
  Set<String> _years = {}, _regions = {}, _conceptTags = {};
  Set<String> _selectedTypes = {}, _selectedExamTypes = {}, _selectedKnowledgeCards = {};
  double _diffMin = 0, _diffMax = 10, _calcMin = 0, _calcMax = 10;
  Timer? _debouncedSearch;
  PoolStats? _poolStats;

  /// 排序方式
  SortMode _sortMode = SortMode.newestFirst;

  @override
  void initState() {
    super.initState();
    _repo = widget.questionRepository ?? QuestionRepository.fromProvider();
    _loadFilterOptions();
  }

  @override
  void dispose() {
    _debouncedSearch?.cancel();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final opts = await _repo.getFilterOptions();
      if (!mounted) return;
      setState(() { _filterOpts = opts; _loadingOpts = false; });
    } catch (e) {
      if (mounted) setState(() { _loadingOpts = false; });
    }
  }

  Future<void> _updatePoolStats() async {
    try {
      final filters = SearchFilters(
        name: '', choiceCount: 0, fillCount: 0, solutionCount: 0, targetDifficulty: 0,
        years: _years.toList(), regions: _regions.toList(), conceptTags: _conceptTags.toList(),
        knowledgeCards: _selectedKnowledgeCards.toList(),
        diffMin: _diffMin, diffMax: _diffMax, calcMin: _calcMin, calcMax: _calcMax,
        examTypes: _selectedExamTypes.isEmpty ? const [] : _selectedExamTypes.toList(),
        questionTypes: _selectedTypes.isEmpty ? const [] : _selectedTypes.toList(),
      );
      final stats = await _repo.getPoolStats(filters);
      if (mounted) setState(() => _poolStats = stats);
    } catch (_) {}
  }

  Future<void> _search() async {
    setState(() => _loadingQ = true);
    try {
      final filters = SearchFilters(name: '', choiceCount: 0, fillCount: 0, solutionCount: 0, targetDifficulty: 0,
        years: _years.toList(), regions: _regions.toList(), conceptTags: _conceptTags.toList(), knowledgeCards: _selectedKnowledgeCards.toList(),
        diffMin: _diffMin, diffMax: _diffMax, calcMin: _calcMin, calcMax: _calcMax,
        examTypes: _selectedExamTypes.isEmpty ? const [] : _selectedExamTypes.toList(),
        questionTypes: _selectedTypes.isEmpty ? const [] : _selectedTypes.toList(),
      );
      final qs = await _repo.getFilteredQuestions(filters, sort: _sortMode);
      if (!mounted) return;
      setState(() { _questions = qs; _loadingQ = false; });
      _updatePoolStats();
    } catch (e) {
      if (mounted) setState(() => _loadingQ = false);
    }
  }

  /// 保存选中题目为 JSON 并复制到剪贴板
  Future<void> _save() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _saving = true);
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final jsonObj = {
        'version': 1,
        'questionIds': _selectedIds.toList()..sort(),
        'selectedAt': now,
        'totalCount': _selectedIds.length,
      };
      final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonObj);

      await Clipboard.setData(ClipboardData(text: jsonStr));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已复制 ${_selectedIds.length} 道题到剪贴板'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _saving = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
      setState(() => _saving = false);
    }
  }

  void _openPreview() {
    if (_selectedIds.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PreviewPage(
        questionIds: _selectedIds.toList(),
        questionRepository: _repo,
        onRemove: (removedId) {
          setState(() => _selectedIds.remove(removedId));
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('题库浏览')),
    body: _loadingOpts
        ? const LoadingIndicator()
        : LayoutBuilder(builder: (context, constraints) {
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedIds.isNotEmpty)
                        TextButton(
                          onPressed: _openPreview,
                          child: const Text('预览'),
                        ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 140,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: (_selectedIds.isEmpty || _saving) ? null : _save,
                          child: _saving
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('导出 (${_selectedIds.length})'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]);
        },
      ),
  );

  Widget _buildScrollContent() {
    final sortRow = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          const Text('排序：', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          DropdownButton<SortMode>(
            value: _sortMode,
            underline: const SizedBox.shrink(),
            isDense: true,
            style: const TextStyle(fontSize: 13, color: AppColors.primary),
            items: const [
              DropdownMenuItem(value: SortMode.newestFirst, child: Text('最新优先')),
              DropdownMenuItem(value: SortMode.oldestFirst, child: Text('最早优先')),
              DropdownMenuItem(value: SortMode.difficultyDesc, child: Text('难度从高')),
              DropdownMenuItem(value: SortMode.difficultyAsc, child: Text('难度从低')),
              DropdownMenuItem(value: SortMode.byType, child: Text('按题型')),
              DropdownMenuItem(value: SortMode.byNumber, child: Text('按题号')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _sortMode = v);
              _search();
            },
          ),
        ],
      ),
    );

    final filterPanel = _filterOpts != null
        ? FilterPanel(
            key: _filterKey,
            yearOptions: _filterOpts!.years,
            regionOptions: _filterOpts!.regions,
            typeOptions: _filterOpts!.questionTypes,
            conceptTagOptions: _filterOpts!.conceptTags,
            conceptTagTree: _filterOpts!.conceptTagTree,
            examTypeOptions: _filterOpts!.examTypes,
            knowledgeCardOptions: _filterOpts!.knowledgeCards,
            knowledgeCardGroups: _filterOpts!.knowledgeCardGroups,
            onChanged: (state) {
            _years = state.years; _regions = state.regions; _conceptTags = state.conceptTags;
            _selectedTypes = state.types; _selectedExamTypes = state.examTypes; _selectedKnowledgeCards = state.knowledgeCards;
            _diffMin = state.diffMin; _diffMax = state.diffMax; _calcMin = state.calcMin; _calcMax = state.calcMax;
            _debouncedSearch?.cancel();
            _debouncedSearch = Timer(const Duration(milliseconds: 300), () { _search(); _updatePoolStats(); });
            },
          )
        : null;

    if (_loadingQ) {
      return const Center(child: LoadingIndicator(message: '搜索中…'));
    }

    // 组装：filterPanel + 排序 + 池统计 在顶部，下方根据状态切换
    final headerChildren = <Widget>[
      sortRow,
      ?filterPanel,
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
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label $count', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
    );
  }
}
