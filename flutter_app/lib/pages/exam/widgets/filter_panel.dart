import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import 'difficulty_slider.dart';

/// 筛选面板（智能组卷/自主选题/推荐 三页共用）
typedef FilterChangedCallback = void Function(
  Set<String> years, Set<String> regions, Set<String> types,
  Set<String> conceptTags,
  double diffMin, double diffMax, double calcMin, double calcMax,
);

class FilterPanel extends StatefulWidget {
  final List<String> yearOptions;
  final List<String> regionOptions;
  final List<String> conceptTagOptions;
  final FilterChangedCallback? onChanged;

  const FilterPanel({
    super.key,
    required this.yearOptions,
    required this.regionOptions,
    this.conceptTagOptions = const [],
    this.onChanged,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  final _selectedYears = <String>{};
  final _selectedRegions = <String>{};
  final _selectedTypes = <String>{};
  final _selectedConceptTags = <String>{};
  double _diffMin = 0, _diffMax = 10;
  double _calcMin = 0, _calcMax = 10;

  void _emit() {
    widget.onChanged?.call(
      _selectedYears, _selectedRegions, _selectedTypes, _selectedConceptTags,
      _diffMin, _diffMax, _calcMin, _calcMax,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.baseSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChipGroup('年份', widget.yearOptions, _selectedYears),
          const SizedBox(height: 12),
          _buildChipGroup('地区', widget.regionOptions, _selectedRegions),
          const SizedBox(height: 12),
          if (widget.conceptTagOptions.isNotEmpty) ...[
            _buildChipGroup('概念标签', widget.conceptTagOptions, _selectedConceptTags),
            const SizedBox(height: 12),
          ],
          _buildTypeGroup(),
          const SizedBox(height: 16),
          DifficultySlider(
            label: '难度范围', min: 0, max: 10,
            lower: _diffMin, upper: _diffMax,
            onChanged: (v) { setState(() { _diffMin = v.start; _diffMax = v.end; }); _emit(); },
          ),
          const SizedBox(height: 12),
          DifficultySlider(
            label: '计算量范围', min: 0, max: 10,
            lower: _calcMin, upper: _calcMax,
            onChanged: (v) { setState(() { _calcMin = v.start; _calcMax = v.end; }); _emit(); },
          ),
        ],
      ),
    );
  }

  Widget _buildChipGroup(String label, List<String> options, Set<String> selected) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
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
        const Text('题型', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
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
