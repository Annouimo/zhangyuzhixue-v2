import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import 'difficulty_slider.dart';

/// 筛选面板（智能组卷/自主选题/推荐 三页共用）
typedef FilterChangedCallback = void Function(
  Set<String> years, Set<String> regions, Set<String> types,
  Set<String> conceptTags, Set<String> examTypes, Set<String> knowledgeCards,
  double diffMin, double diffMax, double calcMin, double calcMax,
);

class FilterPanel extends StatefulWidget {
  final List<String> yearOptions;
  final List<String> regionOptions;
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
    widget.onChanged?.call(
      _selectedYears, _selectedRegions, _selectedTypes, _selectedConceptTags,
      _selectedExamTypes, _selectedKnowledgeCards,
      _diffMin, _diffMax, _calcMin, _calcMax,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
          const SizedBox(height: 8),
          DifficultySlider(
            label: '计算量范围', min: 0, max: 10,
            lower: _calcMin, upper: _calcMax,
            onChanged: (v) { setState(() { _calcMin = v.start; _calcMax = v.end; }); _emit(); },
          ),
          const SizedBox(height: 4),
          _buildTypeGroup(),
        ]),
      ],
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

  Widget _buildTypeGroup() {
    const types = ['choice', 'fill', 'solution'];
    const labels = {'choice': '选择题', 'fill': '填空题', 'solution': '解答题'};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('题型', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6, runSpacing: 4,
          children: types.map((t) => FilterChip(
            label: Text(labels[t]!, style: const TextStyle(fontSize: 12)),
            selected: _selectedTypes.contains(t),
            onSelected: (v) { setState(() { v ? _selectedTypes.add(t) : _selectedTypes.remove(t); }); _emit(); },
            selectedColor: AppColors.primaryLight,
            checkmarkColor: AppColors.primary,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          )).toList(),
        ),
      ],
    );
  }
}
