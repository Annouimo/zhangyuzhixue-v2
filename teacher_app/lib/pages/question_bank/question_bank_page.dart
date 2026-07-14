import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app_theme.dart';
import '../../domain/question_repository.dart';
import '../../widgets/filter_panel.dart';
import '../../widgets/question_card.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/empty_placeholder.dart';
import 'question_detail_page.dart';
import 'preview_page.dart';

/// 题库浏览页（Tab 0）
class QuestionBankPage extends StatefulWidget {
  const QuestionBankPage({super.key});

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
  Timer? _debouncedSearch;
  PoolStats? _poolStats;
  SortMode _sortMode = SortMode.newestFirst;

  @override
  void initState() {
    super.initState();
    _repo = QuestionRepository.fromProvider();
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
      // 首次加载搜索全部
      _search();
    } catch (e) {
      if (mounted) setState(() => _loadingOpts = false);
    }
  }

  Future<void> _updatePoolStats(FilterState state) async {
    try {
      final filters = _buildFilters(state);
      final stats = await _repo.getPoolStats(filters);
      if (mounted) setState(() => _poolStats = stats);
    } catch (_) {}
  }

  SearchFilters _buildFilters(FilterState state) {
    return SearchFilters(
      years: state.years.toList(),
      regions: state.regions.toList(),
      conceptTags: state.conceptTags.toList(),
      knowledgeCards: state.knowledgeCards.toList(),
      diffMin: state.diffMin,
      diffMax: state.diffMax,
      calcMin: state.calcMin,
      calcMax: state.calcMax,
      examTypes: state.examTypes.toList(),
      questionTypes: state.types.toList(),
    );
  }

  Future<void> _search() async {
    if (_filterOpts == null) return;
    setState(() => _loadingQ = true);
    try {
      final state = _filterKey.currentState?.state ?? const FilterState();
      _sortMode = state.sort;
      final filters = _buildFilters(state);
      final qs = await _repo.getFilteredQuestions(filters, sort: _sortMode);
      if (!mounted) return;
      setState(() { _questions = qs; _loadingQ = false; });
      _updatePoolStats(state);
    } catch (e) {
      if (mounted) setState(() => _loadingQ = false);
    }
  }

  void _exportJson() {
    if (_selectedIds.isEmpty) return;
    final json = jsonEncode({
      'version': 1,
      'questionIds': _selectedIds.toList()..sort(),
      'selectedAt': DateTime.now().toIso8601String(),
      'totalCount': _selectedIds.length,
    });
    Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制选题 JSON 到剪贴板'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openPreview() {
    if (_selectedIds.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PreviewPage(
        questionIds: _selectedIds.toList(),
        repo: _repo,
        onRemove: (id) {
          setState(() => _selectedIds.remove(id));
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('题库')),
      body: _loadingOpts
          ? const LoadingIndicator(message: '加载题库…')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildScrollContent()),
                // 底部栏
                Container(
                  color: Colors.white,
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('已选 ${_selectedIds.length} 题',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      if (_selectedIds.isNotEmpty)
                        TextButton(
                          onPressed: _openPreview,
                          child: const Text('预览'),
                        ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _selectedIds.isEmpty ? null : _exportJson,
                          child: Text('导出 JSON (${_selectedIds.length})'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildScrollContent() {
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
              _debouncedSearch?.cancel();
              _debouncedSearch = Timer(
                const Duration(milliseconds: 300),
                () { _search(); _updatePoolStats(state); },
              );
            },
          )
        : null;

    final headerChildren = <Widget>[
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

    if (_loadingQ) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [...headerChildren, const Center(child: Padding(
          padding: EdgeInsets.all(40),
          child: LoadingIndicator(message: '搜索中…'),
        ))],
      );
    }

    if (_questions == null || _questions!.isEmpty) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          ...headerChildren,
          const SizedBox(height: 80),
          const Center(child: EmptyPlaceholder(icon: Icons.search, message: '未找到匹配的题目')),
        ],
      );
    }

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
          onTap: () async {
            final detail = await _repo.getQuestionDetail(q.id);
            if (!context.mounted) return;
            if (detail == null) return;
            final toggled = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => QuestionDetailPage(
                  detail: detail,
                  initiallySelected: sel,
                ),
              ),
            );
            if (toggled != null && context.mounted) {
              setState(() {
                if (toggled) {
                  _selectedIds.add(q.id);
                } else {
                  _selectedIds.remove(q.id);
                }
              });
            }
          },
          trailing: Icon(
            sel ? Icons.check_circle : Icons.radio_button_unchecked,
            color: sel ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
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
      child: Text('$label $count',
        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
    );
  }
}
