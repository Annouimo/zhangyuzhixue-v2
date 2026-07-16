import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/domain/models.dart';
import 'package:shared/widgets/difficulty_slider.dart';
import 'package:shared/widgets/concept_tag_tree.dart';
import 'package:shared/widgets/knowledge_card_group.dart';

/// 筛选状态
class FilterState {
  final Set<String> years;
  final Set<String> regions;
  final Set<String> types;
  final Set<String> conceptTags;
  final Set<String> examTypes;
  final Set<String> knowledgeCards;
  final double diffMin;
  final double diffMax;
  final double calcMin;
  final double calcMax;
  final SortMode? sort;

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
    this.sort,
  });
}

/// 筛选面板（智能组卷/自主选题/推荐 三页共用 + 教师端题库排序）
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

class FilterPanel extends StatefulWidget {
  final List<String> yearOptions;
  final List<String> regionOptions;
  final List<String> typeOptions;
  final List<String> conceptTagOptions;
  final List<ConceptTagNode> conceptTagTree;
  final List<String> examTypeOptions;
  final List<String> knowledgeCardOptions;
  final List<KnowledgeCardGroup> knowledgeCardGroups;
  final FilterChangedCallback? onChanged;
  final VoidCallback? onSavePreference;
  final VoidCallback? onLoadPreference;
  final double horizontalMargin;

  /// 是否显示排序选择器（教师端题库需要，学生端不需要）
  final bool showSort;

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
    this.onSavePreference,
    this.onLoadPreference,
    this.horizontalMargin = 16,
    this.showSort = false,
  });

  @override
  State<FilterPanel> createState() => FilterPanelState();
}

class FilterPanelState extends State<FilterPanel> {
  final _selectedYears = <String>{};
  final _selectedRegions = <String>{};
  final _selectedTypes = <String>{};
  final _selectedConceptTags = <String>{};
  final _selectedExamTypes = <String>{};
  final _selectedKnowledgeCards = <String>{};
  final _selectedConceptTagNames = <String>{};
  final _selectedKnowledgeCardTitles = <String>{};
  double _diffMin = 0, _diffMax = 10;
  double _calcMin = 0, _calcMax = 10;
  SortMode _sort = SortMode.newestFirst;

  bool _sourceExpanded = false;
  bool _conceptExpanded = false;
  bool _knowledgeExpanded = false;
  bool _diffExpanded = false;

  bool _initialized = false;

  bool get _allEmpty =>
      _selectedYears.isEmpty && _selectedRegions.isEmpty &&
      _selectedTypes.isEmpty && _selectedExamTypes.isEmpty &&
      _selectedConceptTagNames.isEmpty && _selectedKnowledgeCardTitles.isEmpty &&
      _selectedConceptTags.isEmpty && _selectedKnowledgeCards.isEmpty;

  Set<String> get selectedYears => _selectedYears;
  Set<String> get selectedRegions => _selectedRegions;
  Set<String> get selectedConceptTags => _selectedConceptTags;
  Set<String> get selectedExamTypes => _selectedExamTypes;
  Set<String> get selectedKnowledgeCards => _selectedKnowledgeCards;
  Set<String> get selectedTypes => _selectedTypes;
  double get diffMin => _diffMin;
  double get diffMax => _diffMax;
  double get calcMin => _calcMin;
  double get calcMax => _calcMax;
  SortMode get sort => _sort;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _selectAllInitial());
  }

  void _selectAllInitial() {
    if (_initialized) return;
    setState(() {
      _selectedYears.addAll(widget.yearOptions);
      _selectedRegions.addAll(widget.regionOptions);
      _selectedTypes.addAll(widget.typeOptions);
      _selectedExamTypes.addAll(widget.examTypeOptions);
      _selectedConceptTagNames.addAll(widget.conceptTagOptions);
      _selectedKnowledgeCardTitles.addAll(widget.knowledgeCardOptions);
      _initialized = true;
    });
    _emit();
  }

  void applyFilter({
    Set<String>? years, Set<String>? regions, Set<String>? conceptTags,
    Set<String>? examTypes, Set<String>? knowledgeCards,
    Set<String>? types,
    double? diffMin, double? diffMax, double? calcMin, double? calcMax,
    SortMode? sort,
  }) {
    setState(() {
      if (years != null) { _selectedYears.clear(); _selectedYears.addAll(years); }
      if (regions != null) { _selectedRegions.clear(); _selectedRegions.addAll(regions); }
      if (conceptTags != null) {
        _selectedConceptTags.clear(); _selectedConceptTags.addAll(conceptTags);
        _selectedConceptTagNames.clear();
      }
      if (examTypes != null) { _selectedExamTypes.clear(); _selectedExamTypes.addAll(examTypes); }
      if (knowledgeCards != null) {
        _selectedKnowledgeCards.clear(); _selectedKnowledgeCards.addAll(knowledgeCards);
        _selectedKnowledgeCardTitles.clear();
      }
      if (types != null) { _selectedTypes.clear(); _selectedTypes.addAll(types); }
      if (diffMin != null) _diffMin = diffMin;
      if (diffMax != null) _diffMax = diffMax;
      if (calcMin != null) _calcMin = calcMin;
      if (calcMax != null) _calcMax = calcMax;
      if (sort != null) _sort = sort;
      _initialized = true; // 阻止 _selectAllInitial 覆盖已加载值
    });
    _emit();
  }

  void clearAll() {
    setState(() {
      _selectedYears.clear();
      _selectedRegions.clear();
      _selectedExamTypes.clear();
      _selectedConceptTags.clear();
      _selectedKnowledgeCards.clear();
      _selectedTypes.clear();
      _selectedConceptTagNames.clear();
      _selectedKnowledgeCardTitles.clear();
      _diffMin = 0; _diffMax = 10;
      _calcMin = 0; _calcMax = 10;
      _sort = SortMode.newestFirst;
    });
    _emit();
  }

  void selectAll() {
    setState(() {
      _selectedYears.addAll(widget.yearOptions);
      _selectedRegions.addAll(widget.regionOptions);
      _selectedTypes.addAll(widget.typeOptions);
      _selectedExamTypes.addAll(widget.examTypeOptions);
      _selectedConceptTagNames.addAll(widget.conceptTagOptions);
      _selectedKnowledgeCardTitles.addAll(widget.knowledgeCardOptions);
      _diffMin = 0; _diffMax = 10;
      _calcMin = 0; _calcMax = 10;
      _sort = SortMode.newestFirst;
    });
    _emit();
  }

  void _emit() {
    final flatTags = _selectedConceptTagNames.isNotEmpty
        ? _selectedConceptTagNames
        : _selectedConceptTags;
    final flatKcs = _selectedKnowledgeCardTitles.isNotEmpty
        ? _selectedKnowledgeCardTitles
        : _selectedKnowledgeCards;
    final effectiveTags = widget.conceptTagOptions.isEmpty || flatTags.length == widget.conceptTagOptions.length
        ? const <String>{}
        : flatTags;
    final effectiveKcs = widget.knowledgeCardOptions.isEmpty || flatKcs.length == widget.knowledgeCardOptions.length
        ? const <String>{}
        : flatKcs;
    widget.onChanged?.call(FilterState(
      years: _selectedYears,
      regions: _selectedRegions,
      types: _selectedTypes,
      conceptTags: effectiveTags,
      examTypes: _selectedExamTypes,
      knowledgeCards: effectiveKcs,
      diffMin: _diffMin,
      diffMax: _diffMax,
      calcMin: _calcMin,
      calcMax: _calcMax,
      sort: widget.showSort ? _sort : null,
    ));
  }

  /// 空维度提示 — 有选项但用户未选任何项时，列出维度名
  List<String> get _emptyHints {
    final h = <String>[];
    if (widget.yearOptions.isNotEmpty && _selectedYears.isEmpty) h.add('年份未选');
    if (widget.regionOptions.isNotEmpty && _selectedRegions.isEmpty) h.add('地区未选');
    if (widget.examTypeOptions.isNotEmpty && _selectedExamTypes.isEmpty) h.add('考试类型未选');
    if (widget.typeOptions.isNotEmpty && _selectedTypes.isEmpty) h.add('题型未选');
    if (widget.conceptTagOptions.isNotEmpty && _selectedConceptTagNames.isEmpty) h.add('概念标签未选');
    if (widget.knowledgeCardOptions.isNotEmpty && _selectedKnowledgeCardTitles.isEmpty) h.add('知识卡片未选');
    return h;
  }

  // ── 摘要 chips ──
  List<Widget> get _summaryChips {
    final chips = <Widget>[];
    void addChip(String text) {
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text, style: const TextStyle(fontSize: 10, color: AppColors.primary)),
      ));
    }
    if (_selectedYears.isNotEmpty && _selectedYears.length < widget.yearOptions.length) {
      addChip(_selectedYears.join(' '));
    }
    if (_selectedRegions.isNotEmpty && _selectedRegions.length < widget.regionOptions.length) {
      addChip(_selectedRegions.join('/'));
    }
    if (_selectedTypes.isNotEmpty && _selectedTypes.length < widget.typeOptions.length) {
      addChip(_selectedTypes.map((t) => QuestionTypeLabels.of(t)).join('/'));
    }
    if (_selectedExamTypes.isNotEmpty && _selectedExamTypes.length < widget.examTypeOptions.length) {
      addChip(_selectedExamTypes.join('/'));
    }
    final tagCount = _selectedConceptTagNames.length;
    final kcCount = _selectedKnowledgeCardTitles.length;
    if (tagCount > 0 && tagCount < widget.conceptTagOptions.length) {
      addChip('概念标签 $tagCount');
    }
    if (kcCount > 0 && kcCount < widget.knowledgeCardOptions.length) {
      addChip('知识卡片 $kcCount');
    }
    if ((_diffMin > 0 || _diffMax < 10) || (_calcMin > 0 || _calcMax < 10)) {
      final d = _diffMin > 0 || _diffMax < 10 ? '难度 ${_diffMin.toStringAsFixed(0)}-${_diffMax.toStringAsFixed(0)}' : null;
      final c = _calcMin > 0 || _calcMax < 10 ? '计算量 ${_calcMin.toStringAsFixed(0)}-${_calcMax.toStringAsFixed(0)}' : null;
      addChip([d, c].nonNulls.join(' '));
    }
    if (chips.isEmpty) {
      addChip('全部');
    }
    return chips;
  }

  // ── 排序选择器（仅 showSort=true 时显示） ──
  static const _sortOptions = {
    SortMode.newestFirst: '最新优先',
    SortMode.oldestFirst: '最早优先',
    SortMode.difficultyDesc: '难度↓',
    SortMode.difficultyAsc: '难度↑',
    SortMode.byType: '按题型',
  };

  Widget _buildSortRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text('排序方式', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ),
        Wrap(
          spacing: 6, runSpacing: 4,
          children: _sortOptions.entries.map((entry) {
            final mode = entry.key;
            final label = entry.value;
            final isSelected = _sort == mode;
            return GestureDetector(
              onTap: () { setState(() => _sort = mode); _emit(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                  border: isSelected
                      ? Border.all(color: Colors.transparent)
                      : Border.all(color: AppColors.border),
                ),
                child: Text(label,
                  style: TextStyle(fontSize: 12, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: widget.horizontalMargin),
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
            // 标题行
            Row(
              children: [
                const Text('筛选条件', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton(
                  onPressed: _allEmpty ? selectAll : clearAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(_allEmpty ? '全选' : '取消全选', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (_summaryChips.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(spacing: 4, runSpacing: 4, children: _summaryChips),
              ),
            if (_emptyHints.isNotEmpty && !_allEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(spacing: 4, runSpacing: 4, children: _emptyHints.map((h) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Text(h, style: const TextStyle(fontSize: 10, color: AppColors.warning)),
                )).toList()),
              ),
            if (widget.onSavePreference != null || widget.onLoadPreference != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    if (widget.onSavePreference != null)
                      GestureDetector(
                        onTap: widget.onSavePreference,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.save_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          const Text('保存为学习偏好', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                        ]),
                      ),
                    if (widget.onSavePreference != null && widget.onLoadPreference != null)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('|', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ),
                    if (widget.onLoadPreference != null)
                      GestureDetector(
                        onTap: widget.onLoadPreference,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.folder_open_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          const Text('读取学习偏好', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                        ]),
                      ),
                  ],
                ),
              ),
            // 按来源筛选
            _buildSection('按来源筛选', _sourceExpanded, () {
              setState(() => _sourceExpanded = !_sourceExpanded);
            }, [
              _buildChipGroup('年份', widget.yearOptions, _selectedYears),
              const SizedBox(height: 8),
              _buildChipGroup('地区', widget.regionOptions, _selectedRegions),
              if (widget.examTypeOptions.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildChipGroup('考试', widget.examTypeOptions, _selectedExamTypes),
              ],
              if (widget.typeOptions.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildTypeChipGroup(widget.typeOptions, _selectedTypes),
              ],
            ]),
            const SizedBox(height: 8),
            if (widget.conceptTagTree.isNotEmpty)
              _section('按概念标签筛选', _conceptExpanded, () {
                setState(() => _conceptExpanded = !_conceptExpanded);
              }, ConceptTagTreeView(
                nodes: widget.conceptTagTree,
                selectedNames: _selectedConceptTagNames,
                onChanged: (names) {
                  setState(() => _selectedConceptTagNames
                    ..clear()
                    ..addAll(names));
                  _emit();
                },
              )),
            if (widget.conceptTagTree.isNotEmpty)
              const SizedBox(height: 8),
            if (widget.knowledgeCardGroups.isNotEmpty)
              _section('按知识卡片筛选', _knowledgeExpanded, () {
                setState(() => _knowledgeExpanded = !_knowledgeExpanded);
              }, KnowledgeCardGroupView(
                groups: widget.knowledgeCardGroups,
                selectedTitles: _selectedKnowledgeCardTitles,
                onChanged: (titles) {
                  setState(() => _selectedKnowledgeCardTitles
                    ..clear()
                    ..addAll(titles));
                  _emit();
                },
              )),
            if (widget.knowledgeCardGroups.isNotEmpty)
              const SizedBox(height: 8),
            _buildSection('按难度/计算量筛选', _diffExpanded, () {
              setState(() => _diffExpanded = !_diffExpanded);
            }, [
              DifficultySlider(
                label: '难度范围', min: 0, max: 10,
                lower: _diffMin, upper: _diffMax,
                onChanged: (v) { setState(() { _diffMin = v.start; _diffMax = v.end; }); _emit(); },
              ),
              _buildSegmentDesc(_difficultySegments, _diffMin, _diffMax),
              const SizedBox(height: 8),
              DifficultySlider(
                label: '计算量范围', min: 0, max: 10,
                lower: _calcMin, upper: _calcMax,
                onChanged: (v) { setState(() { _calcMin = v.start; _calcMax = v.end; }); _emit(); },
              ),
              _buildSegmentDesc(_workloadSegments, _calcMin, _calcMax),
              const SizedBox(height: 4),
            ]),
            const SizedBox(height: 4),
            // 排序方式（教师端）
            if (widget.showSort) _buildSortRow(),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, bool expanded, VoidCallback onToggle, {Widget? trailing}) {
    return Container(
      color: AppColors.background,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              const Spacer(),
              if (trailing != null) trailing,
              const SizedBox(width: 4),
              Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, bool expanded, VoidCallback onToggle, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title, expanded, onToggle),
        if (expanded) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _section(String title, bool expanded, VoidCallback onToggle, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title, expanded, onToggle),
        if (expanded) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: child,
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildChipGroup(String label, List<String> options, Set<String> selected) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ),
        Wrap(
          spacing: 6, runSpacing: 4,
          children: options.map((o) => FilterChip(
            label: Text(o, style: const TextStyle(fontSize: 12)),
            selected: selected.contains(o),
            onSelected: (v) { setState(() { v ? selected.add(o) : selected.remove(o); }); _emit(); },
            selectedColor: AppColors.primaryLight,
            checkmarkColor: AppColors.primary,
            side: selected.contains(o)
                ? BorderSide.none
                : const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeChipGroup(List<String> rawOptions, Set<String> selected) {
    if (rawOptions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text('题型', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ),
        Wrap(
          spacing: 6, runSpacing: 4,
          children: rawOptions.map((o) => FilterChip(
            label: Text(QuestionTypeLabels.of(o), style: const TextStyle(fontSize: 12)),
            selected: selected.contains(o),
            onSelected: (v) { setState(() { v ? selected.add(o) : selected.remove(o); }); _emit(); },
            selectedColor: AppColors.primaryLight,
            checkmarkColor: AppColors.primary,
            side: selected.contains(o)
                ? BorderSide.none
                : const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildSegmentDesc(List<_DifficultySegment> segments, double lower, double upper) {
    int segIndex(double v) => segments.indexWhere((s) => v <= s.max);
    final minIdx = segIndex(lower).clamp(0, segments.length - 1);
    final maxIdx = segIndex(upper).clamp(0, segments.length - 1);
    final same = minIdx == maxIdx;
    if (same) {
      return Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 4),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: segments[minIdx].label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary)),
          TextSpan(text: ' ${segments[minIdx].sample}',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ])),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(TextSpan(children: [
          const WidgetSpan(child: Text('← ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          TextSpan(text: segments[minIdx].label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary)),
          TextSpan(text: ' ${segments[minIdx].sample}',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ])),
        Text.rich(TextSpan(children: [
          const WidgetSpan(child: Text('→ ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          TextSpan(text: segments[maxIdx].label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary)),
          TextSpan(text: ' ${segments[maxIdx].sample}',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ])),
      ]),
    );
  }
}
