import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import 'difficulty_slider.dart';

/// 筛选状态（替代 10 个 positional 参数）
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
  });
}

/// 筛选面板（智能组卷/自主选题 / 推荐 三页共用）
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
  final List<String> typeOptions; // 题型选项：choice/fill/solution
  final List<String> conceptTagOptions;
  final List<String> examTypeOptions;
  final List<String> knowledgeCardOptions;
  final FilterChangedCallback? onChanged;
  final VoidCallback? onSavePreference;
  final VoidCallback? onLoadPreference;

  const FilterPanel({
    super.key,
    required this.yearOptions,
    required this.regionOptions,
    this.typeOptions = const ['choice', 'fill', 'solution'],
    this.conceptTagOptions = const [],
    this.examTypeOptions = const [],
    this.knowledgeCardOptions = const [],
    this.onChanged,
    this.onSavePreference,
    this.onLoadPreference,
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
  double _diffMin = 0, _diffMax = 10;
  double _calcMin = 0, _calcMax = 10;

  bool _sourceExpanded = true;
  bool _conceptExpanded = true;
  bool _knowledgeExpanded = true;
  bool _diffExpanded = true;

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

  void applyFilter({
    Set<String>? years, Set<String>? regions, Set<String>? conceptTags,
    Set<String>? examTypes, Set<String>? knowledgeCards,
    Set<String>? types,
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
      _diffMin = 0; _diffMax = 10;
      _calcMin = 0; _calcMax = 10;
    });
    _emit();
  }

  void _emit() {
    widget.onChanged?.call(FilterState(
      years: _selectedYears,
      regions: _selectedRegions,
      types: _selectedTypes,
      conceptTags: _selectedConceptTags,
      examTypes: _selectedExamTypes,
      knowledgeCards: _selectedKnowledgeCards,
      diffMin: _diffMin,
      diffMax: _diffMax,
      calcMin: _calcMin,
      calcMax: _calcMax,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        // 标题行：筛选条件 + 清除全部
        Row(
          children: [
            const Text('筛选条件', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(
              onPressed: clearAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('清除全部', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        // 保存/读取预设
        if (widget.onSavePreference != null || widget.onLoadPreference != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (widget.onSavePreference != null)
                  TextButton.icon(
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('保存为学习偏好', style: TextStyle(fontSize: 12)),
                    onPressed: widget.onSavePreference,
                  ),
                if (widget.onLoadPreference != null)
                  TextButton.icon(
                    icon: const Icon(Icons.folder_open_outlined, size: 16),
                    label: const Text('读取学习偏好', style: TextStyle(fontSize: 12)),
                    onPressed: widget.onLoadPreference,
                  ),
              ],
            ),
          ),
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
        if (widget.conceptTagOptions.isNotEmpty)
          _buildSection('按概念标签筛选', _conceptExpanded, () {
            setState(() => _conceptExpanded = !_conceptExpanded);
          }, [
            _buildChipGroup('', widget.conceptTagOptions, _selectedConceptTags),
          ]),
        if (widget.conceptTagOptions.isNotEmpty)
          const SizedBox(height: 8),
        if (widget.knowledgeCardOptions.isNotEmpty)
          _buildSection('按知识卡片筛选', _knowledgeExpanded, () {
            setState(() => _knowledgeExpanded = !_knowledgeExpanded);
          }, [
            _buildChipGroup('', widget.knowledgeCardOptions, _selectedKnowledgeCards),
          ]),
        if (widget.knowledgeCardOptions.isNotEmpty)
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
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, bool expanded, VoidCallback onToggle, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              const Spacer(),
              Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
        const Divider(height: 1),
        if (expanded) ...[const SizedBox(height: 6), ...children],
        const SizedBox(height: 4),
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
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          )).toList(),
        ),
      ],
    );
  }

  /// 题型 chip 组：options 存储原始值（choice/fill/solution），显示中文标签
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
            side: BorderSide.none,
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
