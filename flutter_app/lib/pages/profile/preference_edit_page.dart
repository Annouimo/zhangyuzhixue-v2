import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_button.dart';
import 'package:shared/widgets/app_dialog.dart';
import 'package:shared/widgets/app_toast.dart';
import '../../data/daos/preference_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/preference_repository.dart';
import '../../domain/exam_repository.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/filter_panel.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

/// 常用选题范围编辑页（新建/编辑）
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
  String? _existingKeyword;

  // 筛选选项（内存缓存）
  List<String>? _yearOpts,
      _regionOpts,
      _tagOpts,
      _examTypeOpts,
      _knowledgeCardOpts;
  List<ConceptTagNode>? _tagTree;
  List<KnowledgeCardGroup>? _kcGroups;

  @override
  void initState() {
    super.initState();
    _repo =
        widget.preferenceRepository ??
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
      final years = (await qDao.getDistinctYears())
          .map((y) => y.toString())
          .toList();
      final regions = await qDao.getDistinctRegions();
      final allTags = await qDao.getAllConceptTags();
      final tagLinks = await qDao.getAllQuestionTagLinks();
      final tags = allTags.map((t) => t.name).toList();
      final examTypes = await qDao.getDistinctExamTypes();
      final allKcs = await qDao.getAllKnowledgeCards();
      final knowledgeLinks = await qDao.getAllQuestionKnowledgeCardLinks();
      final kcs = allKcs.map((k) => k.title).toList();
      if (!mounted) return;
      setState(() {
        _yearOpts = years;
        _regionOpts = regions;
        _tagOpts = tags;
        _tagTree = ExamRepository.buildTagTree(allTags, links: tagLinks);
        _examTypeOpts = examTypes;
        _knowledgeCardOpts = kcs;
        _kcGroups = ExamRepository.buildKnowledgeCardGroups(
          allKcs,
          ExamRepository.buildKnowledgeCardCounts(knowledgeLinks),
        );
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
      _existingKeyword = editData.filter.keyword;
      // 先渲染 FilterPanel，再 applyFilter（否则 currentState 为 null 被静默丢弃）
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
      });
      AuditLogger.instance.page('PreferenceEditPage', {'loaded': true});
    } catch (e) {
      OperationLog.instance.error('preference_edit_page_load', e);
      AuditLogger.instance.error('PreferenceEditPage._loadExisting', e);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppToast.warning(context, '请输入名称');
      return;
    }
    final state = _filterKey.currentState;
    if (state == null) return;
    setState(() => _saving = true);
    try {
      await _repo.save(
        name: name,
        filter: PreferenceFilter(
          keyword: _existingKeyword,
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
      AppToast.success(context, '保存成功');
      if (context.mounted) context.pop(true);
    } catch (e) {
      OperationLog.instance.error('preference_edit_page_load', e);
      AuditLogger.instance.error('PreferenceEditPage._save', e);
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.error(context, '保存失败: $e');
    }
  }

  Future<void> _delete() async {
    final id = widget.editId;
    if (id == null || _saving) return;
    final confirmed = await AppDialog.confirm(
      context,
      title: '删除筛选方案？',
      message: '删除后无法恢复，但不会影响已有的练习和试卷。',
      icon: Icons.delete_outline_rounded,
      confirmLabel: '确认删除',
      destructive: true,
    );
    if (!confirmed) return;
    setState(() => _saving = true);
    try {
      await _repo.delete(id);
      if (!mounted) return;
      AppToast.success(context, '筛选方案已删除');
      context.pop(true);
    } catch (error) {
      OperationLog.instance.error('preference_edit_page_delete', error);
      AuditLogger.instance.error('PreferenceEditPage._delete', error);
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.error(context, '删除失败，请稍后重试');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.editId != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? '编辑范围' : '新建范围')),
      body: _loading || _loadingOpts
          ? const LoadingIndicator(message: '正在准备筛选条件…')
          : _error != null
          ? ErrorPlaceholder(
              message: _error!,
              onRetry: () {
                setState(() {
                  _error = null;
                  _loading = true;
                });
                _loadExisting();
              },
            )
          : AppContentContainer(
              maxWidth: AppContentWidth.dashboard,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppSectionHeader(
                          title: '方案名称',
                          subtitle: '建议使用目标明确、容易识别的名称。',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: '名称',
                            hintText: '例如：函数选择题专项',
                            prefixIcon: Icon(Icons.bookmark_outline_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                    selectAllInitially: false,
                    allowGlobalSelectAll: false,
                    showConceptSection: true,
                    showKnowledgeSection: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: editing ? '保存修改' : '创建范围',
                    icon: Icons.check_rounded,
                    onPressed: _saving ? null : _save,
                    isLoading: _saving,
                    fullWidth: true,
                  ),
                  if (editing) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _delete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('删除方案'),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }
}
