import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../domain/question_repository.dart' as repo;
import 'concept_tag_tree.dart';
import 'knowledge_card_group.dart';

/// 筛选状态
class FilterState {
  final Set<String> years;
  final Set<String> regions;
  final Set<String> types; // question types: choice/fill/solution
  final Set<String> conceptTags;
  final Set<String> examTypes;
  final Set<String> knowledgeCards;
  final double diffMin;
  final double diffMax;
  final double calcMin;
  final double calcMax;
  final repo.SortMode sort;

  const FilterState({
    this.years = const {},
    this.regions = const {},
    this.types = const {},
    this.conceptTags = const {},
    this.examTypes = const {},
    this.knowledgeCards = const {},
    this.diffMin = 0,
    this.diffMax = 10,
    this.calcMin = 0,
    this.calcMax = 10,
    this.sort = repo.SortMode.newestFirst,
  });
}

typedef FilterChangedCallback = void Function(FilterState state);

final _difficultySegments = [
  _DifficultySegment(max: 3.0, label: '基础', sample: '单选1-3·填空11·解答第一问'),
  _DifficultySegment(max: 5.0, label: '中档', sample: '单选4-6·填空12-13·常规解答'),
  _DifficultySegment(max: 7.0, label: '中难', sample: '选填后半·填空14·解答多步推理'),
  _DifficultySegment(max: 8.5, label: '较难', sample: '选填压轴·解答最后两问'),
  _DifficultySegment(max: 10.0, label: '压轴', sample: '解答压轴问·创新综合题'),
];

final _workloadSegments = [
  _DifficultySegment(max: 2.0, label: '少量', sample: '心算即可，不需动笔'),
  _DifficultySegment(max: 4.0, label: '较少', sample: '简单代入化简，2-3步'),
  _DifficultySegment(max: 6.0, label: '适中', sample: '常规运算量，需完整步骤'),
  _DifficultySegment(max: 8.0, label: '较多', sample: '多步代数运算，需仔细'),
  _DifficultySegment(max: 10.0, label: '繁琐', sample: '大量代数变换，需耐心推导'),
];

class _DifficultySegment {
  final double max;
  final String label;
  final String sample;
  const _DifficultySegment({required this.max, required this.label, required this.sample});
}

/// 教师端筛选面板 — 在学生端基础上增加排序
class FilterPanel extends StatefulWidget {
  final List<String> yearOptions;
  final List<String> regionOptions;
  final List<String> typeOptions;
  final List<String> conceptTagOptions;
  final List<repo.ConceptTagNode> conceptTagTree;
  final List<String> examTypeOptions;
  final List<String> knowledgeCardOptions;
  final List<repo.KnowledgeCardGroup> knowledgeCardGroups;
  final FilterChangedCallback? onChanged;
  final int? questionCount;

  const FilterPanel({
    super.key,
    required this.yearOptions,
    required this.regionOptions,
    this.typeOptions = const ['choice', 'fill', 'solution'],
    this.conceptTagOptions = const [],
    this.conceptTagTree = const [],
    this.examTypeOptions = const [],
    this.knowledgeCardOptions = const [],
    this.knowledgeCardGroups = const [],
    this.onChanged,
    this.questionCount,
  });

  @override
  State<FilterPanel> createState() => FilterPanelState();
}

class FilterPanelState extends State<FilterPanel> {
  bool _expanded = false;
  bool _expandedYears = false;
  bool _expandedRegions = false;
  bool _expandedTags = false;
  bool _expandedExamTypes = false;
  bool _expandedKcs = false;

  final _selectedYears = <String>{};
  final _selectedRegions = <String>{};
  final _selectedTypes = <String>{};
  final _selectedConceptTags = <String>{};
  final _selectedExamTypes = <String>{};
  final _selectedKnowledgeCards = <String>{};
  double _diffMin = 0, _diffMax = 10, _calcMin = 0, _calcMax = 10;
  repo.SortMode _sortMode = repo.SortMode.newestFirst;

  FilterState get state => FilterState(
    years: Set.from(_selectedYears),
    regions: Set.from(_selectedRegions),
    types: Set.from(_selectedTypes),
    conceptTags: Set.from(_selectedConceptTags),
    examTypes: Set.from(_selectedExamTypes),
    knowledgeCards: Set.from(_selectedKnowledgeCards),
    diffMin: _diffMin, diffMax: _diffMax,
    calcMin: _calcMin, calcMax: _calcMax,
    sort: _sortMode,
  );

  void _notify() => widget.onChanged?.call(state);

  void applyFilter({
    Set<String>? years, Set<String>? regions, Set<String>? conceptTags,
    Set<String>? examTypes, Set<String>? knowledgeCards, Set<String>? types,
    double? diffMin, double? diffMax, double? calcMin, double? calcMax,
  }) {
    setState(() {
      if (years != null) { _selectedYears.clear(); _selectedYears.addAll(years); }
      if (regions != null) { _selectedRegions.clear(); _selectedRegions.addAll(regions); }
      if (conceptTags != null) { _selectedConceptTags.clear(); _selectedConceptTags.addAll(conceptTags); }
      if (examTypes != null) { _selectedExamTypes.clear(); _selectedExamTypes.addAll(examTypes); }
      if (knowledgeCards != null) { _selectedKnowledgeCards.clear(); _selectedKnowledgeCards.addAll(knowledgeCards); }
      if (types != null) { _selectedTypes.clear(); _selectedTypes.addAll(types); }
      if (diffMin != null) _diffMin = diffMin;
      if (diffMax != null) _diffMax = diffMax;
      if (calcMin != null) _calcMin = calcMin;
      if (calcMax != null) _calcMax = calcMax;
    });
    _notify();
  }

  /// 当前已选筛选条件数量
  int get _activeFilterCount {
    int count = 0;
    if (_selectedTypes.isNotEmpty) count++;
    if (_selectedYears.isNotEmpty) count++;
    if (_selectedRegions.isNotEmpty) count++;
    if (_selectedConceptTags.isNotEmpty) count++;
    if (_selectedExamTypes.isNotEmpty) count++;
    if (_selectedKnowledgeCards.isNotEmpty) count++;
    if (_diffMin > 0 || _diffMax < 10) count++;
    if (_calcMin > 0 || _calcMax < 10) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final filterCount = _activeFilterCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 展开/收起按钮
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text('筛选条件',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary),
                ),
                if (filterCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$filterCount',
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                // 已选题目数
                if (widget.questionCount != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('已选 ${widget.questionCount} 题',
                      style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else
                  const Spacer(),
                Text(_expanded ? '收起' : '展开',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18, color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (!_expanded) ...[
          // 收起时显示已选条件摘要
          _buildSummaryChips(),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 排序
                _buildSectionTitle('排序方式'),
                _buildSortRow(),
                const SizedBox(height: 4),
                const Divider(height: 1),

                // 题型
                _buildSectionTitle('题型'),
                _buildChipGroup(
                  widget.typeOptions,
                  _selectedTypes,
                  (v) => setState(() { _selectedTypes.contains(v) ? _selectedTypes.remove(v) : _selectedTypes.add(v); _notify(); }),
                  singleSelect: false,
                ),
                const Divider(height: 1),

                // 年份
                _buildCollapsibleSection(
                  '年份', _expandedYears,
                  () => setState(() => _expandedYears = !_expandedYears),
                  _buildChipGroup(widget.yearOptions, _selectedYears,
                    (v) => setState(() { _selectedYears.contains(v) ? _selectedYears.remove(v) : _selectedYears.add(v); _notify(); }),
                  ),
                ),

                // 地区
                _buildCollapsibleSection(
                  '地区', _expandedRegions,
                  () => setState(() => _expandedRegions = !_expandedRegions),
                  _buildChipGroup(widget.regionOptions, _selectedRegions,
                    (v) => setState(() { _selectedRegions.contains(v) ? _selectedRegions.remove(v) : _selectedRegions.add(v); _notify(); }),
                  ),
                ),

                // 概念标签
                _buildCollapsibleSection(
                  '概念标签', _expandedTags,
                  () => setState(() => _expandedTags = !_expandedTags),
                  ConceptTagTreeView(
                    nodes: widget.conceptTagTree,
                    selectedNames: _selectedConceptTags,
                    onChanged: (v) => setState(() { _selectedConceptTags
                      ..clear()
                      ..addAll(v); _notify(); }),
                  ),
                ),

                // 考试类型
                _buildCollapsibleSection(
                  '考试类型', _expandedExamTypes,
                  () => setState(() => _expandedExamTypes = !_expandedExamTypes),
                  _buildChipGroup(widget.examTypeOptions, _selectedExamTypes,
                    (v) => setState(() { _selectedExamTypes.contains(v) ? _selectedExamTypes.remove(v) : _selectedExamTypes.add(v); _notify(); }),
                  ),
                ),

                // 知识卡片
                _buildCollapsibleSection(
                  '知识卡片', _expandedKcs,
                  () => setState(() => _expandedKcs = !_expandedKcs),
                  KnowledgeCardGroupView(
                    groups: widget.knowledgeCardGroups,
                    selectedTitles: _selectedKnowledgeCards,
                    onChanged: (v) => setState(() { _selectedKnowledgeCards
                      ..clear()
                      ..addAll(v); _notify(); }),
                  ),
                ),

                // 难度
                const SizedBox(height: 8),
                _buildSectionTitle('难度范围'),
                _DifficultySliderWithLabel(
                  min: _diffMin, max: _diffMax,
                  segments: _difficultySegments,
                  onChanged: (min, max) => setState(() { _diffMin = min; _diffMax = max; _notify(); }),
                ),

                // 计算量
                const SizedBox(height: 8),
                _buildSectionTitle('计算量范围'),
                _DifficultySliderWithLabel(
                  min: _calcMin, max: _calcMax,
                  segments: _workloadSegments,
                  onChanged: (min, max) => setState(() { _calcMin = min; _calcMax = max; _notify(); }),
                ),

                const SizedBox(height: 8),
                const Divider(height: 1),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSortRow() {
    const options = [
      (repo.SortMode.newestFirst, '最新优先'),
      (repo.SortMode.oldestFirst, '最早优先'),
      (repo.SortMode.difficultyDesc, '难度↓'),
      (repo.SortMode.difficultyAsc, '难度↑'),
      (repo.SortMode.byType, '按题型'),
      (repo.SortMode.byNumber, '按题号'),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: options.map((o) => ChoiceChip(
          label: Text(o.$2, style: const TextStyle(fontSize: 12)),
          selected: _sortMode == o.$1,
          onSelected: (_) => setState(() { _sortMode = o.$1; _notify(); }),
          selectedColor: AppColors.primaryLight,
          side: BorderSide.none,
          visualDensity: VisualDensity.compact,
        )).toList(),
      ),
    );
  }

  Widget _buildSummaryChips() {
    final chips = <Widget>[];
    if (_selectedTypes.isNotEmpty) {
      chips.add(_MiniChip(_selectedTypes.map(QuestionTypeLabels.of).join('、')));
    }
    if (_selectedYears.isNotEmpty) {
      chips.add(_MiniChip('${_selectedYears.length}个年份'));
    }
    if (_selectedRegions.isNotEmpty) {
      chips.add(_MiniChip('${_selectedRegions.length}个地区'));
    }
    if (_selectedConceptTags.isNotEmpty) {
      chips.add(_MiniChip('${_selectedConceptTags.length}个标签'));
    }
    if (_selectedExamTypes.isNotEmpty) {
      chips.add(_MiniChip('${_selectedExamTypes.length}种考试'));
    }
    if (_selectedKnowledgeCards.isNotEmpty) {
      chips.add(_MiniChip('${_selectedKnowledgeCards.length}张卡片'));
    }
    if (_diffMin > 0 || _diffMax < 10) {
      chips.add(_MiniChip('难度 ${_diffMin.toStringAsFixed(1)}-${_diffMax.toStringAsFixed(1)}'));
    }
    if (_calcMin > 0 || _calcMax < 10) {
      chips.add(_MiniChip('计算量 ${_calcMin.toStringAsFixed(1)}-${_calcMax.toStringAsFixed(1)}'));
    }

    if (chips.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(left: 16, bottom: 4),
        child: Text('暂无筛选条件',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 4, runSpacing: 4,
              children: chips,
            ),
          ),
          if (widget.questionCount != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Text('${widget.questionCount} 题',
                style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildCollapsibleSection(String title, bool expanded, VoidCallback onToggle, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        if (expanded) content,
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildChipGroup(List<String> options, Set<String> selected, void Function(String) onToggle, {bool singleSelect = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: options.map((opt) => ChoiceChip(
          label: Text(opt, style: const TextStyle(fontSize: 12)),
          selected: selected.contains(opt),
          onSelected: (_) => onToggle(opt),
          selectedColor: AppColors.primaryLight,
          side: BorderSide.none,
          visualDensity: VisualDensity.compact,
        )).toList(),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  const _MiniChip(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// 难度双滑块组件（注入分段信息）
class _DifficultySliderWithLabel extends StatelessWidget {
  final double min;
  final double max;
  final List<_DifficultySegment> segments;
  final void Function(double min, double max) onChanged;

  const _DifficultySliderWithLabel({
    required this.min, required this.max,
    required this.segments, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final minLabel = segments.lastIndexWhere((s) => min >= (segments.indexOf(s) > 0 ? segments[segments.indexOf(s) - 1].max : 0));
    final maxLabel = segments.lastIndexWhere((s) => max >= (segments.indexOf(s) > 0 ? segments[segments.indexOf(s) - 1].max : 0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${segments[minLabel.clamp(0, segments.length - 1)].label} ~ ${segments[maxLabel.clamp(0, segments.length - 1)].label}',
          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
        ),
        RangeSlider(
          values: RangeValues(min, max),
          min: 0, max: 10, divisions: 20,
          labels: RangeLabels(min.toStringAsFixed(1), max.toStringAsFixed(1)),
          onChanged: (v) => onChanged(v.start, v.end),
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
}
