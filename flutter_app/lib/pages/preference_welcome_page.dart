import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_theme.dart';
import '../data/daos/preference_dao.dart';
import '../data/daos/question_dao.dart';
import '../data/daos/system_config_dao.dart';
import '../data/database/database_provider.dart';
import '../domain/preference_repository.dart';
import '../domain/exam_repository.dart';
import 'package:shared/widgets/filter_panel.dart';
import 'router.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

/// 首次引导流程 — 欢迎弹窗 → 偏好设置 → 跳主框架
class PreferenceWelcomePage extends StatefulWidget {
  final PreferenceRepository? preferenceRepository;
  final QuestionDao? questionDao;
  const PreferenceWelcomePage({super.key, this.preferenceRepository, this.questionDao});

  @override State<PreferenceWelcomePage> createState() => _PreferenceWelcomePageState();
}

class _PreferenceWelcomePageState extends State<PreferenceWelcomePage> {
  late final PreferenceRepository _repo;
  late final QuestionDao _qDao;
  bool _saving = false;
  final _nameCtrl = TextEditingController(text: '我的偏好');

  Set<String> _years = {};
  Set<String> _regions = {};
  Set<String> _types = {};
  Set<String> _conceptTags = {};
  Set<String> _examTypes = {};
  Set<String> _knowledgeCards = {};
  double _diffMin = 0, _diffMax = 10, _calcMin = 0, _calcMax = 10;

  // 筛选选项（内存缓存）
  List<String>? _yearOpts;
  List<String>? _regionOpts;
  List<String>? _tagOpts;
  List<String>? _examTypeOpts;
  List<String>? _knowledgeCardOpts;
  List<ConceptTagNode>? _tagTree;
  List<KnowledgeCardGroup>? _kcGroups;

  // 积分值
  double _bonusPoints = 0;
  bool _bonusLoaded = false;

  @override
  void initState() {
      final colors = context.colors;
    super.initState();
    _repo = widget.preferenceRepository ?? PreferenceRepository(PreferenceDao(DatabaseProvider()));
    _qDao = widget.questionDao ?? QuestionDao(DatabaseProvider());
    _loadOpts();
    _loadBonus();
    // 页面构建完成后弹出欢迎 Dialog
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcome(context));
  }

  Future<void> _loadOpts() async {
      final colors = context.colors;
    try {
      final years = (await _qDao.getDistinctYears()).map((y) => y.toString()).toList();
      final regions = await _qDao.getDistinctRegions();
      final allTags = await _qDao.getAllConceptTags();
      final tags = allTags.map((t) => t.name).toList();
      final examTypes = await _qDao.getDistinctExamTypes();
      final allKcs = await _qDao.getAllKnowledgeCards();
      final kcs = allKcs.map((k) => k.title).toList();
      if (!mounted) return;
      setState(() {
        _yearOpts = years; _regionOpts = regions; _tagOpts = tags;
        _tagTree = ExamRepository.buildTagTree(allTags);
        _examTypeOpts = examTypes; _knowledgeCardOpts = kcs;
        _kcGroups = ExamRepository.buildKnowledgeCardGroups(allKcs);
      });
      AuditLogger.instance.page('PreferenceWelcomePage', {'loaded': _yearOpts != null});
    } catch (_) {}
  }

  Future<void> _loadBonus() async {
      final colors = context.colors;
    try {
      final cfg = SystemConfigDao(DatabaseProvider());
      final pts = await cfg.getDouble('signup_bonus_amount', 10);
      if (!mounted) return;
      setState(() { _bonusPoints = pts; _bonusLoaded = true; });
    } catch (e) {
      OperationLog.instance.error('PreferenceWelcomePage._loadBonus', e); 
      AuditLogger.instance.error('PreferenceWelcomePage._loadBonus', e);
      if (!mounted) return;
      setState(() => _bonusLoaded = true);
    }
  }

  void _showWelcome(BuildContext context) {
      final colors = context.colors;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: colors.scrim,
      builder: (ctx) => PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          // 遮罩点击 → 跳主框架
          context.go(AppRoutes.mainShell);
        },
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.celebration, size: 64, color: colors.primary),
            const SizedBox(height: 16),
            const Text('欢迎加入章鱼智学！', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('首次注册赠送 ${_bonusLoaded ? _bonusPoints.toStringAsFixed(0) : '...'} 积分',
              style: TextStyle(fontSize: 16, color: colors.success)),
            const SizedBox(height: 4),
            Text('可用于组卷等消费功能', style: TextStyle(fontSize: 14, color: colors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () { Navigator.of(ctx).pop(); },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.thumb_up_alt, size: 20, color: Colors.white),
                  SizedBox(width: 6),
                  Text('开始设置学习偏好'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go(AppRoutes.mainShell);
              },
              child: Text('跳过', style: TextStyle(color: colors.textSecondary)),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _saveAndGoHome() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入偏好名称'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_years.isEmpty && _regions.isEmpty && _conceptTags.isEmpty && _examTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一项筛选条件'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.save(
        name: _nameCtrl.text.trim(),
        filter: PreferenceFilter(
          years: _years.toList(),
          regions: _regions.toList(),
          conceptTags: _conceptTags.toList(),
          types: _examTypes.toList(),
          knowledgeCards: _knowledgeCards.toList(),
          questionTypes: _types.toList(),
          diffMin: _diffMin,
          diffMax: _diffMax,
          calcMin: _calcMin,
          calcMax: _calcMax,
        ),
      );
    } catch (e) {
      OperationLog.instance.error('PreferenceWelcomePage._save', e); 
      AuditLogger.instance.error('PreferenceWelcomePage._save', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败，请重试'), behavior: SnackBarBehavior.floating),
      );
      setState(() => _saving = false);
      return;
    }
    if (!mounted) return;
    context.go(AppRoutes.mainShell);
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
      final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('设置学习偏好')),
      body: _yearOpts == null
          ? const LoadingIndicator()
          : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero 卡片
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.auto_awesome, size: 56, color: colors.primary),
                        const SizedBox(height: 12),
                        const Text('选择你的学习偏好', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('我们为你推荐最合适的题目', style: TextStyle(fontSize: 14, color: colors.textSecondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '偏好名称',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  enabled: !_saving,
                ),
                const SizedBox(height: 20),
                FilterPanel(
                  horizontalMargin: 0,
                  yearOptions: _yearOpts!,
                  regionOptions: _regionOpts!,
                  typeOptions: const ['choice', 'fill', 'solution'],
                  conceptTagOptions: _tagOpts ?? [],
                  conceptTagTree: _tagTree ?? [],
                  examTypeOptions: _examTypeOpts ?? [],
                  knowledgeCardOptions: _knowledgeCardOpts ?? [],
                  knowledgeCardGroups: _kcGroups ?? [],
                  onChanged: (state) {
                    _years = state.years; _regions = state.regions; _types = state.types; _conceptTags = state.conceptTags;
                    _examTypes = state.examTypes; _knowledgeCards = state.knowledgeCards;
                    _diffMin = state.diffMin; _diffMax = state.diffMax; _calcMin = state.calcMin; _calcMax = state.calcMax;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveAndGoHome,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.save, size: 20, color: Colors.white),
                            SizedBox(width: 6),
                            Text('保存偏好'),
                          ],
                        ),
                  ),
                ),
              ],
            )),
    );
  }
}

