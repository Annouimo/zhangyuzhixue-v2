import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app_theme.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/exam_repository.dart';
import '../../../domain/preference_repository.dart';
import '../../../data/daos/preference_dao.dart';
import '../../../widgets/shared/loading_indicator.dart';
import 'widgets/filter_panel.dart';
import 'widgets/difficulty_slider.dart';
import '../../data/debug/audit_logger.dart';

/// 智能组卷
class ExamAutoPage extends StatefulWidget {
  final ExamRepository? examRepository;
  final PreferenceRepository? preferenceRepository;
  const ExamAutoPage({super.key, this.examRepository, this.preferenceRepository});

  @override
  State<ExamAutoPage> createState() => _ExamAutoPageState();
}

class _ExamAutoPageState extends State<ExamAutoPage> {
  late final ExamRepository _repo;
  final _filterKey = GlobalKey<FilterPanelState>();
  late final PreferenceRepository _prefRepo = widget.preferenceRepository ??
      PreferenceRepository(PreferenceDao(DatabaseProvider().appDb));
  FilterOptions? _filterOpts;
  bool _loadingOpts = true;
  final _nameController = TextEditingController(text: '智能练习卷');
  int _choiceCount = 10, _fillCount = 5, _solutionCount = 6;
  double _targetDifficulty = 5;
  bool _generating = false;
  Set<String> _years = {}, _regions = {}, _conceptTags = {};
  double _diffMin = 0, _diffMax = 10, _calcMin = 0, _calcMax = 10;
  PoolStats? _poolStats;

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.examRepository ?? ExamRepository(
      QuestionDao(db.assetsDb), ExamDao(db.appDb),
    );
    _loadFilterOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final opts = await _repo.getFilterOptions();
      if (!mounted) return;
      setState(() { _filterOpts = opts; _loadingOpts = false; });
      AuditLogger.instance.page('ExamAutoPage', {'count': _choiceCount, 'difficulty': _targetDifficulty});
    } catch (e) { AuditLogger.instance.error('ExamAutoPage._loadFilterOptions', e); if (mounted) setState(() { _loadingOpts = false; }); }
  }

  /// 保存当前筛选条件为学习偏好
  Future<void> _savePreference() async {
    final state = _filterKey.currentState;
    if (state == null) return;
    if (!context.mounted) return;
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('保存为学习偏好'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            hintText: '偏好名称（如"北京高考模拟"）',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, nameCtrl.text), child: const Text('保存')),
        ],
      ),
    );
    nameCtrl.dispose();
    if (name == null || name.trim().isEmpty) return;
    await _prefRepo.save(
      name: name.trim(),
      filter: PreferenceFilter(
        years: state.selectedYears.toList(),
        regions: state.selectedRegions.toList(),
        conceptTags: state.selectedConceptTags.toList(),
        diffMin: state.diffMin,
        diffMax: state.diffMax,
        calcMin: state.calcMin,
        calcMax: state.calcMax,
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('偏好已保存'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  /// 读取学习偏好并应用到筛选面板
  Future<void> _loadPreference() async {
    final state = _filterKey.currentState;
    if (state == null) return;
    final presets = await _prefRepo.getList();
    if (!context.mounted) return;
    if (presets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无保存的学习偏好'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择学习偏好'),
        children: presets.map((p) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, p.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500)),
              if (p.summary.isNotEmpty)
                Text(p.summary, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        )).toList(),
      ),
    );
    if (selected == null) return;
    final filter = await _prefRepo.getEdit(selected);
    if (!context.mounted) return;
    state.applyFilter(
      years: filter.years.toSet(),
      regions: filter.regions.toSet(),
      conceptTags: filter.conceptTags.toSet(),
      diffMin: filter.diffMin,
      diffMax: filter.diffMax,
      calcMin: filter.calcMin,
      calcMax: filter.calcMax,
    );
  }

  Future<void> _updatePoolStats() async {
    try {
      final filters = SearchFilters(
        name: _nameController.text, choiceCount: 0, fillCount: 0, solutionCount: 0, targetDifficulty: 0,
        years: _years.toList(), regions: _regions.toList(), conceptTags: _conceptTags.toList(),
        knowledgeCards: [], diffMin: _diffMin, diffMax: _diffMax, calcMin: _calcMin, calcMax: _calcMax,
      );
      final stats = await _repo.getPoolStats(filters);
      if (mounted) setState(() => _poolStats = stats);
    } catch (_) {}
  }

  Future<void> _confirm() async {
    setState(() => _generating = true);
    try {
      final filters = SearchFilters(
        name: _nameController.text, choiceCount: _choiceCount, fillCount: _fillCount,
        solutionCount: _solutionCount, targetDifficulty: _targetDifficulty,
        years: _years.toList(), regions: _regions.toList(),
        conceptTags: _conceptTags.toList(), knowledgeCards: [],
        diffMin: _diffMin, diffMax: _diffMax, calcMin: _calcMin, calcMax: _calcMax,
      );
      final paperId = await _repo.confirm(filters);
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('组卷成功！'), behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: '查看', onPressed: () => context.push('/exam/quicklook?id=$paperId')),
          ),
        );
      }
    } catch (e) {
      AuditLogger.instance.error('ExamAutoPage._confirm', e);
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally { if (mounted) setState(() => _generating = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('智能组卷')),
    body: _loadingOpts
        ? const LoadingIndicator()
        : Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '试卷名称',
                          hintText: '输入试卷名称',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    if (_filterOpts != null)
                      FilterPanel(
                        key: _filterKey,
                        yearOptions: _filterOpts!.years,
                        regionOptions: _filterOpts!.regions,
                        conceptTagOptions: _filterOpts!.conceptTags,
                        onSavePreference: _savePreference,
                        onLoadPreference: _loadPreference,
                        onChanged: (y, r, t, ct, dmn, dmx, cmn, cmx) async {
                          setState(() { _years = y; _regions = r; _conceptTags = ct;
                            _diffMin = dmn; _diffMax = dmx; _calcMin = cmn; _calcMax = cmx; });
                          _updatePoolStats();
                        },
                      ),
                    const Divider(height: 1),
                    if (_poolStats != null)
                      Padding(
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
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('题型配比', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          _countStepper('选择题', _choiceCount, (v) => _choiceCount = v),
                          _countStepper('填空题', _fillCount, (v) => _fillCount = v),
                          _countStepper('解答题', _solutionCount, (v) => _solutionCount = v),
                          const SizedBox(height: 16),
                          DifficultySlider(
                            label: '目标难度', min: 0, max: 10,
                            lower: _targetDifficulty, upper: _targetDifficulty,
                            onChanged: (v) => setState(() => _targetDifficulty = v.start),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity, color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _generating ? null : _confirm,
                  child: _generating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('确认组卷'),
                ),
              ),
            ],
          ),
  );

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

  Widget _countStepper(String label, int count, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: count > 0 ? () => setState(() => onChanged(count - 1)) : null),
          SizedBox(width: 32, child: Center(child: Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
          IconButton(icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: count < 30 ? () => setState(() => onChanged(count + 1)) : null),
        ],
      ),
    );
  }
}
