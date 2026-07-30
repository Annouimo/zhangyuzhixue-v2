import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/domain/models.dart';
import 'package:shared/widgets/difficulty_slider.dart';
import 'package:shared/widgets/concept_tag_tree.dart';
import 'package:shared/widgets/knowledge_card_group.dart';
import 'package:shared/widgets/filter_panel_components.dart';
import 'package:shared/widgets/filter_state.dart';

export 'filter_state.dart';

/// 筛选面板（题库工作台和筛选方案页面共用）

final _difficultySegments = [
  FilterRangeSegment(max: 3.0, label: '基础', sample: '单选1-3·填空11·解答第一问'),
  FilterRangeSegment(max: 5.0, label: '中档', sample: '单选4-6·填空12-13·常规解答'),
  FilterRangeSegment(max: 7.0, label: '中难', sample: '选填后半·填空14·解答多步推理'),
  FilterRangeSegment(max: 8.5, label: '较难', sample: '选填压轴·解答最后两问'),
  FilterRangeSegment(max: 10.0, label: '压轴', sample: '解答压轴问·创新综合题'),
];

final _workloadSegments = [
  FilterRangeSegment(max: 2.0, label: '少量', sample: '心算即可，不需动笔'),
  FilterRangeSegment(max: 4.0, label: '较少', sample: '简单代入化简，2-3步'),
  FilterRangeSegment(max: 6.0, label: '适中', sample: '常规运算量，需完整步骤'),
  FilterRangeSegment(max: 8.0, label: '较多', sample: '多步代数运算，需仔细'),
  FilterRangeSegment(max: 10.0, label: '繁琐', sample: '大量代数变换，需耐心推导'),
];

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

  /// 是否显示排序选择器。
  final bool showSort;

  /// 是否在首次显示时选择所有选项。新范围选择流程应设为 false。
  final bool selectAllInitially;

  /// 是否允许从标题行一键选择所有维度。
  final bool allowGlobalSelectAll;

  /// Whether to show concept and knowledge-card selectors inside this panel.
  /// Dedicated range browsers can disable them to avoid duplicate entry points.
  final bool showConceptSection;
  final bool showKnowledgeSection;

  /// 面板首次构建时使用的外部筛选状态。
  final FilterState? initialState;

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
    this.selectAllInitially = false,
    this.allowGlobalSelectAll = true,
    this.showConceptSection = true,
    this.showKnowledgeSection = true,
    this.initialState,
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

  int _groupIndex = 0;

  bool _initialized = false;

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
    final initial = widget.initialState;
    if (initial != null) {
      applyFilter(
        years: initial.years,
        regions: initial.regions,
        conceptTags: initial.conceptTags,
        examTypes: initial.examTypes,
        knowledgeCards: initial.knowledgeCards,
        types: initial.types,
        diffMin: initial.diffMin,
        diffMax: initial.diffMax,
        calcMin: initial.calcMin,
        calcMax: initial.calcMax,
        sort: initial.sort,
      );
      return;
    }
    setState(() {
      if (widget.selectAllInitially) {
        _selectedYears.addAll(widget.yearOptions);
        _selectedRegions.addAll(widget.regionOptions);
        _selectedTypes.addAll(widget.typeOptions);
        _selectedExamTypes.addAll(widget.examTypeOptions);
        _selectedConceptTagNames.addAll(widget.conceptTagOptions);
        _selectedKnowledgeCardTitles.addAll(widget.knowledgeCardOptions);
      }
      _initialized = true;
    });
    _emit();
  }

  void applyFilter({
    Set<String>? years,
    Set<String>? regions,
    Set<String>? conceptTags,
    Set<String>? examTypes,
    Set<String>? knowledgeCards,
    Set<String>? types,
    double? diffMin,
    double? diffMax,
    double? calcMin,
    double? calcMax,
    SortMode? sort,
    bool notify = true,
  }) {
    setState(() {
      if (years != null) {
        _selectedYears.clear();
        _selectedYears.addAll(years);
      }
      if (regions != null) {
        _selectedRegions.clear();
        _selectedRegions.addAll(regions);
      }
      if (conceptTags != null) {
        _selectedConceptTags.clear();
        _selectedConceptTags.addAll(conceptTags);
        _selectedConceptTagNames
          ..clear()
          ..addAll(conceptTags);
      }
      if (examTypes != null) {
        _selectedExamTypes.clear();
        _selectedExamTypes.addAll(examTypes);
      }
      if (knowledgeCards != null) {
        _selectedKnowledgeCards.clear();
        _selectedKnowledgeCards.addAll(knowledgeCards);
        _selectedKnowledgeCardTitles
          ..clear()
          ..addAll(knowledgeCards);
      }
      if (types != null) {
        _selectedTypes.clear();
        _selectedTypes.addAll(types);
      }
      if (diffMin != null) _diffMin = diffMin;
      if (diffMax != null) _diffMax = diffMax;
      if (calcMin != null) _calcMin = calcMin;
      if (calcMax != null) _calcMax = calcMax;
      if (sort != null) _sort = sort;
      _initialized = true; // 阻止 _selectAllInitial 覆盖已加载值
    });
    if (notify) _emit();
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
      _diffMin = 0;
      _diffMax = 10;
      _calcMin = 0;
      _calcMax = 10;
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
      _selectedConceptTags.addAll(widget.conceptTagOptions);
      _selectedKnowledgeCardTitles.addAll(widget.knowledgeCardOptions);
      _selectedKnowledgeCards.addAll(widget.knowledgeCardOptions);
      _diffMin = 0;
      _diffMax = 10;
      _calcMin = 0;
      _calcMax = 10;
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
    final effectiveTags =
        widget.conceptTagOptions.isEmpty ||
            flatTags.length == widget.conceptTagOptions.length
        ? const <String>{}
        : flatTags;
    final effectiveKcs =
        widget.knowledgeCardOptions.isEmpty ||
            flatKcs.length == widget.knowledgeCardOptions.length
        ? const <String>{}
        : flatKcs;
    widget.onChanged?.call(
      FilterState(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _buildGroupedLayout(context);
  Widget _buildGroupedLayout(BuildContext context) {
    final colors = context.colors;
    final groups = <Widget>[
      ConceptTagTreeView(
        nodes: widget.conceptTagTree,
        selectedNames: _selectedConceptTagNames,
        compactLeaves: true,
        onChanged: (names) {
          setState(() {
            _selectedConceptTagNames
              ..clear()
              ..addAll(names);
            _selectedConceptTags
              ..clear()
              ..addAll(names);
          });
          _emit();
        },
      ),
      KnowledgeCardGroupView(
        groups: widget.knowledgeCardGroups,
        selectedTitles: _selectedKnowledgeCardTitles,
        compact: true,
        onChanged: (titles) {
          setState(() {
            _selectedKnowledgeCardTitles
              ..clear()
              ..addAll(titles);
            _selectedKnowledgeCards
              ..clear()
              ..addAll(titles);
          });
          _emit();
        },
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChipGroup('年份', widget.yearOptions, _selectedYears),
          const SizedBox(height: 16),
          _buildChipGroup('地区', widget.regionOptions, _selectedRegions),
          if (widget.examTypeOptions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildChipGroup('考试类型', widget.examTypeOptions, _selectedExamTypes),
          ],
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.typeOptions.isNotEmpty) ...[
            _buildTypeChipGroup(widget.typeOptions, _selectedTypes),
            const SizedBox(height: 16),
          ],
          DifficultySlider(
            label: '难度范围',
            min: 0,
            max: 10,
            lower: _diffMin,
            upper: _diffMax,
            onChanged: (value) {
              setState(() {
                _diffMin = value.start;
                _diffMax = value.end;
              });
              _emit();
            },
          ),
          _buildSegmentDesc(_difficultySegments, _diffMin, _diffMax),
          const SizedBox(height: 16),
          DifficultySlider(
            label: '计算量范围',
            min: 0,
            max: 10,
            lower: _calcMin,
            upper: _calcMax,
            onChanged: (value) {
              setState(() {
                _calcMin = value.start;
                _calcMax = value.end;
              });
              _emit();
            },
          ),
          _buildSegmentDesc(_workloadSegments, _calcMin, _calcMax),
        ],
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.onLoadPreference != null) ...[
            InkWell(
              onTap: widget.onLoadPreference,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.bookmarks_outlined, color: colors.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        '筛选方案',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      MediaQuery.sizeOf(context).width < 600
                          ? '管理'
                          : '应用、保存与管理',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: colors.border),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildGroupedTab(0, '试题来源', _sourceGroupCount),
                      _buildGroupedTab(1, '题目特征', _featureGroupCount),
                      _buildGroupedTab(
                        2,
                        '概念标签',
                        _selectedConceptTagNames.length,
                      ),
                      _buildGroupedTab(
                        3,
                        '知识卡片',
                        _selectedKnowledgeCardTitles.length,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 4,
              children: [
                if (_currentGroupHasSelection)
                  TextButton.icon(
                    onPressed: _clearCurrentGroup,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('重置当前维度'),
                  ),
                TextButton.icon(
                  onPressed: clearAll,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('重置所有维度'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: groups[switch (_groupIndex) {
              0 => 2,
              1 => 3,
              2 => 0,
              _ => 1,
            }],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedTab(int index, String label, int count) {
    final colors = context.colors;
    final selected = _groupIndex == index;
    return InkWell(
      onTap: () => setState(() => _groupIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : colors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? colors.primaryBorder : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? colors.primary : colors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int get _sourceGroupCount => [
    _selectedYears.isNotEmpty,
    _selectedRegions.isNotEmpty,
    _selectedExamTypes.isNotEmpty,
  ].where((selected) => selected).length;

  int get _featureGroupCount => [
    _selectedTypes.isNotEmpty,
    _diffMin > 0 || _diffMax < 10,
    _calcMin > 0 || _calcMax < 10,
  ].where((selected) => selected).length;

  bool get _currentGroupHasSelection => switch (_groupIndex) {
    0 => _sourceGroupCount > 0,
    1 => _featureGroupCount > 0,
    2 => _selectedConceptTagNames.isNotEmpty,
    _ => _selectedKnowledgeCardTitles.isNotEmpty,
  };

  void _clearCurrentGroup() {
    setState(() {
      switch (_groupIndex) {
        case 0:
          _selectedYears.clear();
          _selectedRegions.clear();
          _selectedExamTypes.clear();
          break;
        case 1:
          _selectedTypes.clear();
          _diffMin = 0;
          _diffMax = 10;
          _calcMin = 0;
          _calcMax = 10;
          break;
        case 2:
          _selectedConceptTagNames.clear();
          _selectedConceptTags.clear();
          break;
        default:
          _selectedKnowledgeCardTitles.clear();
          _selectedKnowledgeCards.clear();
      }
    });
    _emit();
  }

  Widget _buildChipGroup(
    String label,
    List<String> options,
    Set<String> selected,
  ) {
    return FilterChoiceGroup(
      label: label,
      options: options,
      selected: selected,
      onChanged: (option, value) {
        setState(() => value ? selected.add(option) : selected.remove(option));
        _emit();
      },
    );
  }

  Widget _buildTypeChipGroup(List<String> rawOptions, Set<String> selected) {
    return FilterChoiceGroup(
      label: '题型',
      options: rawOptions,
      selected: selected,
      labelFor: QuestionTypeLabels.of,
      onChanged: (option, value) {
        setState(() => value ? selected.add(option) : selected.remove(option));
        _emit();
      },
    );
  }

  Widget _buildSegmentDesc(
    List<FilterRangeSegment> segments,
    double lower,
    double upper,
  ) {
    return FilterRangeDescription(
      segments: segments,
      lower: lower,
      upper: upper,
    );
  }
}
