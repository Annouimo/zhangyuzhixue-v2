import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app_theme.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/exam_repository.dart';
import '../../../widgets/shared/loading_indicator.dart';
import 'widgets/filter_panel.dart';
import 'widgets/difficulty_slider.dart';
import '../../data/debug/audit_logger.dart';

/// 智能组卷
class ExamAutoPage extends StatefulWidget {
  final ExamRepository? examRepository;
  const ExamAutoPage({super.key, this.examRepository});

  @override
  State<ExamAutoPage> createState() => _ExamAutoPageState();
}

class _ExamAutoPageState extends State<ExamAutoPage> {
  late final ExamRepository _repo;
  FilterOptions? _filterOpts;
  bool _loadingOpts = true;
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

  Future<void> _loadFilterOptions() async {
    try {
      final opts = await _repo.getFilterOptions();
      if (!mounted) return;
      setState(() { _filterOpts = opts; _loadingOpts = false; });
      AuditLogger.instance.page('ExamAutoPage', {'count': _choiceCount, 'difficulty': _targetDifficulty});
    } catch (e) { AuditLogger.instance.error('ExamAutoPage._loadFilterOptions', e); if (mounted) setState(() { _loadingOpts = false; }); }
  }

  Future<void> _updatePoolStats() async {
    try {
      final filters = SearchFilters(
        name: '', choiceCount: 0, fillCount: 0, solutionCount: 0, targetDifficulty: 0,
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
        name: '', choiceCount: _choiceCount, fillCount: _fillCount,
        solutionCount: _solutionCount, targetDifficulty: _targetDifficulty,
        years: _years.toList(), regions: _regions.toList(),
        conceptTags: [], knowledgeCards: [],
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
                    if (_filterOpts != null)
                      FilterPanel(
                        yearOptions: _filterOpts!.years,
                        regionOptions: _filterOpts!.regions,
                        conceptTagOptions: _filterOpts!.conceptTags,
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
