import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_theme.dart';
import '../../data/daos/preference_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/preference_repository.dart';
import '../../domain/exam_repository.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/filter_panel.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

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
  final _filterKey = GlobalKey<FilterPanelState>();
  bool _loading = true;
  bool _loadingOpts = true;
  bool _saving = false;
  String? _error;

  // 筛选选项（内存缓存）
  List<String>? _yearOpts, _regionOpts, _tagOpts, _examTypeOpts, _knowledgeCardOpts;
  List<ConceptTagNode>? _tagTree;
  List<KnowledgeCardGroup>? _kcGroups;

  @override
  void initState() {
    super.initState();
    _repo = widget.preferenceRepository ??
        PreferenceRepository(PreferenceDao(DatabaseProvider()));
    _loadOptions().then((_) {
      if (widget.editId != null) {
        _loadExisting();
      } else {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  Future<void> _loadOptions() async {
    try {
      final qDao = QuestionDao(DatabaseProvider());
      final years = (await qDao.getDistinctYears()).map((y) => y.toString()).toList();
      final regions = await qDao.getDistinctRegions();
      final allTags = await qDao.getAllConceptTags();
      final tags = allTags.map((t) => t.name).toList();
      final examTypes = await qDao.getDistinctExamTypes();
      final allKcs = await qDao.getAllKnowledgeCards();
      final kcs = allKcs.map((k) => k.title).toList();
      if (!mounted) return;
      setState(() {
        _yearOpts = years;
        _regionOpts = regions;
        _tagOpts = tags;
        _tagTree = ExamRepository.buildTagTree(allTags);
        _examTypeOpts = examTypes;
        _knowledgeCardOpts = kcs;
        _kcGroups = ExamRepository.buildKnowledgeCardGroups(allKcs);
        _loadingOpts = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingOpts = false);
    }
  }

  Future<void> _loadExisting() async {
    try {
      final editData = await _repo.getEdit(widget.editId!);
      if (!mounted) return;
      _nameCtrl.text = editData.name;
      final filter = editData.filter;
      _filterKey.currentState?.applyFilter(
        years: filter.years.toSet(),
        regions: filter.regions.toSet(),
        conceptTags: filter.conceptTags.toSet(),
        examTypes: filter.types.toSet(),
        knowledgeCards: filter.knowledgeCards.toSet(),
        types: filter.questionTypes.toSet(),
        diffMin: filter.diffMin ?? 0,
        diffMax: filter.diffMax ?? 10,
        calcMin: filter.calcMin ?? 0,
        calcMax: filter.calcMax ?? 10,
      );
      setState(() => _loading = false);
      AuditLogger.instance.page('PreferenceEditPage', {'loaded': true});
    } catch (e) { OperationLog.instance.error('preference_edit_page_load', e); 
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
    final state = _filterKey.currentState;
    if (state == null) return;
    if (state.selectedYears.isEmpty && state.selectedRegions.isEmpty &&
        state.selectedConceptTags.isEmpty && state.selectedExamTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一项筛选条件'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.save(
        name: name,
        filter: PreferenceFilter(
          years: state.selectedYears.toList(),
          regions: state.selectedRegions.toList(),
          conceptTags: state.selectedConceptTags.toList(),
          types: state.selectedExamTypes.toList(),
          knowledgeCards: state.selectedKnowledgeCards.toList(),
          questionTypes: state.selectedTypes.toList(),
          diffMin: state.diffMin,
          diffMax: state.diffMax,
          calcMin: state.calcMin,
          calcMax: state.calcMax,
        ),
        existingId: widget.editId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功'), behavior: SnackBarBehavior.floating),
      );
      if (context.mounted) context.pop(true);
    } catch (e) { OperationLog.instance.error('preference_edit_page_load', e); 
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
    body: _loading || _loadingOpts
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
                  FilterPanel(
                    horizontalMargin: 0,
                    key: _filterKey,
                    yearOptions: _yearOpts ?? [],
                    regionOptions: _regionOpts ?? [],
                    conceptTagOptions: _tagOpts ?? [],
                    conceptTagTree: _tagTree ?? [],
                    examTypeOptions: _examTypeOpts ?? [],
                    knowledgeCardOptions: _knowledgeCardOpts ?? [],
                    knowledgeCardGroups: _kcGroups ?? [],
                  ),
                ],
              ),
  );
}

