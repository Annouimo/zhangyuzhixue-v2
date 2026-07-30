import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_status_badge.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_feature_banner.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_button.dart';
import 'package:shared/widgets/app_toast.dart';
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

/// 兼容入口：创建第一个常用选题范围。
class PreferenceWelcomePage extends StatefulWidget {
  final PreferenceRepository? preferenceRepository;
  final QuestionDao? questionDao;
  const PreferenceWelcomePage({
    super.key,
    this.preferenceRepository,
    this.questionDao,
  });

  @override
  State<PreferenceWelcomePage> createState() => _PreferenceWelcomePageState();
}

class _PreferenceWelcomePageState extends State<PreferenceWelcomePage> {
  late final PreferenceRepository _repo;
  late final QuestionDao _qDao;
  bool _saving = false;
  final _nameCtrl = TextEditingController(text: '我的筛选方案');

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
    super.initState();
    _repo =
        widget.preferenceRepository ??
        PreferenceRepository(PreferenceDao(DatabaseProvider()));
    _qDao = widget.questionDao ?? QuestionDao(DatabaseProvider());
    _loadOpts();
    _loadBonus();
    // 页面构建完成后弹出欢迎 Dialog
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcome(context));
  }

  Future<void> _loadOpts() async {
    try {
      final years = (await _qDao.getDistinctYears())
          .map((y) => y.toString())
          .toList();
      final regions = await _qDao.getDistinctRegions();
      final allTags = await _qDao.getAllConceptTags();
      final tagLinks = await _qDao.getAllQuestionTagLinks();
      final tags = allTags.map((t) => t.name).toList();
      final examTypes = await _qDao.getDistinctExamTypes();
      final allKcs = await _qDao.getAllKnowledgeCards();
      final knowledgeLinks = await _qDao.getAllQuestionKnowledgeCardLinks();
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
      });
      AuditLogger.instance.page('PreferenceWelcomePage', {
        'loaded': _yearOpts != null,
      });
    } catch (_) {}
  }

  Future<void> _loadBonus() async {
    try {
      final cfg = SystemConfigDao(DatabaseProvider());
      final pts = await cfg.getDouble('signup_bonus_amount', 10);
      if (!mounted) return;
      setState(() {
        _bonusPoints = pts;
        _bonusLoaded = true;
      });
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
      builder: (dialogContext) => AlertDialog(
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: BrandColors.gradient),
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: const Icon(
            Icons.celebration_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        title: const Text('欢迎加入章鱼智学'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '首次注册将获得 ${_bonusLoaded ? _bonusPoints.toStringAsFixed(0) : '…'} 积分',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colors.success),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '保存筛选方案后，可以更快恢复经常使用的查找条件。',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go(AppRoutes.mainShell);
            },
            child: const Text('稍后设置'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('开始设置'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndGoHome() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppToast.warning(context, '请输入方案名称');
      return;
    }
    if (_years.isEmpty &&
        _regions.isEmpty &&
        _conceptTags.isEmpty &&
        _examTypes.isEmpty) {
      AppToast.warning(context, '请至少选择一项筛选条件');
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
      AppToast.error(context, '保存失败，请重试');
      setState(() => _saving = false);
      return;
    }
    if (!mounted) return;
    context.go(AppRoutes.mainShell);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_yearOpts == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('创建筛选方案')),
        body: const LoadingIndicator(message: '正在准备可选条件…'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('创建筛选方案'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => context.go(AppRoutes.mainShell),
            child: const Text('跳过'),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: AppContentContainer(
        maxWidth: AppContentWidth.dashboard,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: [
            AppFeatureBanner(
              icon: Icons.auto_awesome_rounded,
              eyebrow: '个性化推荐',
              title: '告诉我们你想练什么',
              subtitle: '把经常使用的年份、地区、题型和知识范围保存下来，之后可以快速再次使用。',
              footer: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: const [
                  AppStatusBadge(label: '可保存多个范围', tone: AppStatusTone.info),
                  AppStatusBadge(label: '随时调整', tone: AppStatusTone.success),
                  AppStatusBadge(
                    label: '下次快速使用',
                    tone: AppStatusTone.recommendation,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= AppBreakpoints.medium;
                final nameCard = AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(
                        title: '方案名称',
                        subtitle: '给这组条件起一个容易识别的名称。',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: '名称',
                          hintText: '例如：高考选择题专项',
                          prefixIcon: Icon(Icons.bookmark_outline_rounded),
                        ),
                        enabled: !_saving,
                      ),
                    ],
                  ),
                );

                final filter = FilterPanel(
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
                    _years = state.years;
                    _regions = state.regions;
                    _types = state.types;
                    _conceptTags = state.conceptTags;
                    _examTypes = state.examTypes;
                    _knowledgeCards = state.knowledgeCards;
                    _diffMin = state.diffMin;
                    _diffMax = state.diffMax;
                    _calcMin = state.calcMin;
                    _calcMax = state.calcMax;
                  },
                );

                if (!wide) {
                  return Column(
                    children: [
                      nameCard,
                      const SizedBox(height: AppSpacing.lg),
                      filter,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 320, child: nameCard),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: filter),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: '保存筛选方案',
              icon: Icons.check_rounded,
              onPressed: _saving ? null : _saveAndGoHome,
              isLoading: _saving,
              fullWidth: true,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
