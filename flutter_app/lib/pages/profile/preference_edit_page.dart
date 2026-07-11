import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../data/daos/preference_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/preference_repository.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../data/debug/audit_logger.dart';

/// 学习偏好编辑页（新建/编辑）
class PreferenceEditPage extends StatefulWidget {
  final int? editId;
  final PreferenceRepository? preferenceRepository;

  const PreferenceEditPage({super.key, this.editId, this.preferenceRepository});

  @override
  State<PreferenceEditPage> createState() => _PreferenceEditPageState();
}

class _PreferenceEditPageState extends State<PreferenceEditPage> {
  late final PreferenceRepository _repo;
  final _nameCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  // 筛选条件 state
  List<String> _selectedYears = [];
  List<String> _selectedRegions = [];
  List<String> _selectedTypes = [];
  List<String> _selectedConceptTags = [];
  double _diffMin = 0;
  double _diffMax = 10;
  double _calcMin = 0;
  double _calcMax = 10;

  // 折叠面板
  bool _sourceExpanded = true;
  bool _tagExpanded = true;
  bool _diffExpanded = true;

  // 候选列表（可从 DB 加载，这里用 HTML 原型中的示例值）
  static const List<String> _yearOptions = ['2025', '2024', '2023', '2022', '2021'];
  static const List<String> _regionOptions = ['海淀', '东城', '西城', '朝阳', '丰台', '石景山', '通州', '顺义', '昌平', '大兴'];
  static const List<String> _typeOptions = ['一模', '二模', '期末', '期中', '月考', '高考'];
  static const List<String> _tagOptions = ['集合', '函数', '导数', '三角函数', '数列', '不等式', '向量', '复数', '概率统计', '立体几何', '解析几何', '排列组合'];

  @override
  void initState() {
    super.initState();
    _repo = widget.preferenceRepository ??
        PreferenceRepository(PreferenceDao(DatabaseProvider().appDb));
    if (widget.editId != null) {
      _loadExisting();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadExisting() async {
    try {
      final filter = await _repo.getEdit(widget.editId!);
      if (!mounted) return;
      _nameCtrl.text = '偏好 ${widget.editId}';
      setState(() {
        _selectedYears = List.from(filter.years);
        _selectedRegions = List.from(filter.regions);
        _selectedTypes = List.from(filter.types);
        _selectedConceptTags = List.from(filter.conceptTags);
        _diffMin = filter.diffMin ?? 0;
        _diffMax = filter.diffMax ?? 10;
        _calcMin = filter.calcMin ?? 0;
        _calcMax = filter.calcMax ?? 10;
        _loading = false;
      });
      AuditLogger.instance.page('PreferenceEditPage', {'loaded': !_loading});
    } catch (e) {
      AuditLogger.instance.error('PreferenceEditPage._loadExisting', e);
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入名称'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.save(
        name: name,
        filter: PreferenceFilter(
          years: _selectedYears,
          regions: _selectedRegions,
          conceptTags: _selectedConceptTags,
          types: _selectedTypes,
          diffMin: _diffMin,
          diffMax: _diffMax,
          calcMin: _calcMin,
          calcMax: _calcMax,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功'), behavior: SnackBarBehavior.floating),
      );
      if (context.mounted) context.pop(true);
    } catch (e) {
      AuditLogger.instance.error('PreferenceEditPage._save', e);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.editId != null ? '编辑偏好' : '新建偏好'),
      actions: [
        TextButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('保存', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    ),
    body: _loading
        ? const LoadingIndicator()
        : _error != null
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('加载失败', style: TextStyle(color: AppColors.error)),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () { setState(() { _error = null; _loading = true; }); _loadExisting(); }, child: const Text('重试')),
              ]))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '偏好名称',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildFilterCard(),
                ],
              ),
  );

  Widget _buildFilterCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('筛选条件', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildCollapsibleSection(
          title: '按来源筛选',
          expanded: _sourceExpanded,
          onToggle: () => setState(() => _sourceExpanded = !_sourceExpanded),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCheckboxGroup('年份', _yearOptions, _selectedYears),
              const SizedBox(height: 10),
              _buildCheckboxGroup('地区', _regionOptions, _selectedRegions),
              const SizedBox(height: 10),
              _buildCheckboxGroup('考试', _typeOptions, _selectedTypes),
            ],
          ),
        ),
        const Divider(height: 16),
        _buildCollapsibleSection(
          title: '按概念标签筛选',
          expanded: _tagExpanded,
          onToggle: () => setState(() => _tagExpanded = !_tagExpanded),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _tagOptions.map((tag) => FilterChip(
              label: Text(tag, style: const TextStyle(fontSize: 13)),
              selected: _selectedConceptTags.contains(tag),
              onSelected: (sel) {
                setState(() {
                  if (sel) {
                    _selectedConceptTags.add(tag);
                  } else {
                    _selectedConceptTags.remove(tag);
                  }
                });
              },
              selectedColor: AppColors.primaryLight,
              checkmarkColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          ),
        ),
        const Divider(height: 16),
        _buildCollapsibleSection(
          title: '按难度/计算量筛选',
          expanded: _diffExpanded,
          onToggle: () => setState(() => _diffExpanded = !_diffExpanded),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRangeSlider('难度', _diffMin, _diffMax, (min, max) {
                setState(() { _diffMin = min; _diffMax = max; });
              }, ['基础', '中档', '中难', '较难', '压轴']),
              const SizedBox(height: 20),
              _buildRangeSlider('计算量', _calcMin, _calcMax, (min, max) {
                setState(() { _calcMin = min; _calcMax = max; });
              }, ['少量', '较少', '适中', '较多', '繁琐']),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildCollapsibleSection({
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InkWell(
        onTap: onToggle,
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const Spacer(),
            Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
      if (expanded) ...[
        const SizedBox(height: 8),
        child,
      ],
    ],
  );

  Widget _buildCheckboxGroup(String label, List<String> options, List<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 2,
          children: options.map((opt) => FilterChip(
            label: Text(opt, style: const TextStyle(fontSize: 13)),
            selected: selected.contains(opt),
            onSelected: (sel) {
              setState(() {
                if (sel) {
                  selected.add(opt);
                } else {
                  selected.remove(opt);
                }
              });
            },
            selectedColor: AppColors.primaryLight,
            checkmarkColor: AppColors.primary,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildRangeSlider(
    String label,
    double minVal,
    double maxVal,
    void Function(double min, double max) onChanged,
    List<String> segments,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        RangeSlider(
          values: RangeValues(minVal, maxVal),
          min: 0,
          max: 10,
          divisions: 20,
          labels: RangeLabels(
            minVal.toStringAsFixed(1),
            maxVal.toStringAsFixed(1),
          ),
          activeColor: AppColors.primary,
          inactiveColor: const Color(0xFFE5E7EB),
          onChanged: (v) => onChanged(v.start, v.end),
        ),
        // 分段标签
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: segments.map((s) => Text(s,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          )).toList(),
        ),
      ],
    );
  }
}
