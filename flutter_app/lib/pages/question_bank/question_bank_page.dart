import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/daos/preference_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/helpers/pdf_helper.dart';
import '../../domain/exam_repository.dart';
import '../../domain/paper_creation_service.dart';
import '../../domain/paper_folder_repository.dart';
import '../../domain/question_review_repository.dart';
import '../../domain/smart_paper_draft_selector.dart';
import '../../domain/preference_repository.dart';
import '../../domain/user_repository.dart';
import '../../data/api/api_client.dart';
import '../../data/api/user_api.dart';
import '../../data/daos/user_dao.dart';
import '../../widgets/question_search_field.dart';
import '../../widgets/question_selection_workspace.dart';
import '../router.dart';
import 'question_detail_page.dart';
import 'paper_draft_dialog.dart';

// Legacy private browser types remain while older widget tests are migrated.
enum _VirtualPaperAction { addToBasket, createPaper, createAndDownload }

class StudentQuestionBankPage extends StatefulWidget {
  const StudentQuestionBankPage({
    super.key,
    this.examRepository,
    this.virtualPaperRepository,
    this.questionReviewRepository,
    this.initialReviewScope,
    this.preferenceRepository,
    this.scrollController,
  });

  final QuestionLibraryRepository? examRepository;
  @Deprecated('套卷已迁移到试卷空间')
  final VirtualPaperRepository? virtualPaperRepository;
  final QuestionReviewRepository? questionReviewRepository;
  final QuestionReviewScope? initialReviewScope;
  final PreferenceRepository? preferenceRepository;
  final ScrollController? scrollController;

  @override
  State<StudentQuestionBankPage> createState() =>
      _StudentQuestionBankPageState();
}

class _StudentQuestionBankPageState extends State<StudentQuestionBankPage> {
  late final QuestionLibraryRepository _repository =
      widget.examRepository ??
      ExamRepository(
        QuestionDao(DatabaseProvider()),
        ExamDao(DatabaseProvider()),
      );
  late final QuestionReviewRepository _questionReviewRepository =
      widget.questionReviewRepository ??
      LocalQuestionReviewRepository(
        ProgressDao(DatabaseProvider()),
        QuestionDao(DatabaseProvider()),
      );
  late final PreferenceRepository _preferenceRepository =
      widget.preferenceRepository ??
      PreferenceRepository(PreferenceDao(DatabaseProvider()));
  late final ExamRepository _paperExamRepository = ExamRepository(
    QuestionDao(DatabaseProvider()),
    ExamDao(DatabaseProvider()),
  );
  late final PaperCreationService _paperCreationService = PaperCreationService(
    _paperExamRepository,
    UserRepository(
      UserDao(DatabaseProvider()),
      UserApi(ApiClient()),
      QuestionDao(DatabaseProvider()),
    ),
    DatabaseProvider(),
  );
  late final PaperFolderRepository _paperFolderRepository =
      PaperFolderRepository.local();
  static const _smartDraftSelector = SmartPaperDraftSelector();
  final _resultsKey = GlobalKey();
  late final ScrollController _scrollController =
      widget.scrollController ?? ScrollController();
  final _queryController = TextEditingController();
  FilterOptions? _filterOptions;
  List<PreferenceSummary> _savedRanges = const [];
  List<SearchQuestion>? _questions;
  Timer? _debounce;
  bool _loadingQuestions = false;
  bool _creatingPaper = false;
  final Map<int, SearchQuestion> _selectedQuestions = {};
  final QuestionWorkspaceController _workspaceController =
      QuestionWorkspaceController();
  QuestionReviewScope? _reviewScope;
  int? _selectedRangeId;
  bool _applyingExternalScope = false;
  bool _initialReviewScopeApplied = false;
  String? _error;
  Set<String> _years = {};
  Set<String> _regions = {};
  Set<String> _conceptTags = {};
  Set<String> _questionTypes = {};
  Set<String> _examTypes = {};
  Set<String> _knowledgeCards = {};
  double _difficultyMin = 0;
  double _difficultyMax = 10;
  double _calculationMin = 0;
  double _calculationMax = 10;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _workspaceController.dispose();
    if (widget.scrollController == null) _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final results = await Future.wait([
        _repository.getFilterOptions(),
        _preferenceRepository.getList(),
      ]);
      if (!mounted) return;
      setState(() {
        _filterOptions = results[0] as FilterOptions;
        _savedRanges = results[1] as List<PreferenceSummary>;
      });
      final initialReviewScope = widget.initialReviewScope;
      if (!_initialReviewScopeApplied && initialReviewScope != null) {
        _initialReviewScopeApplied = true;
        await _selectReviewScope(initialReviewScope);
      }
    } catch (error) {
      if (mounted) setState(() => _error = '题库筛选条件加载失败，请稍后重试');
    }
  }

  FilterState get _currentFilterState => FilterState(
    years: _years,
    regions: _regions,
    conceptTags: _conceptTags,
    types: _questionTypes,
    examTypes: _examTypes,
    knowledgeCards: _knowledgeCards,
    diffMin: _difficultyMin,
    diffMax: _difficultyMax,
    calcMin: _calculationMin,
    calcMax: _calculationMax,
  );

  void _applyFilterState(FilterState state) {
    _years = Set<String>.from(state.years);
    _regions = Set<String>.from(state.regions);
    _conceptTags = Set<String>.from(state.conceptTags);
    _questionTypes = Set<String>.from(state.types);
    _examTypes = Set<String>.from(state.examTypes);
    _knowledgeCards = Set<String>.from(state.knowledgeCards);
    _difficultyMin = state.diffMin;
    _difficultyMax = state.diffMax;
    _calculationMin = state.calcMin;
    _calculationMax = state.calcMax;
  }

  void _commitFilterState(FilterState state) {
    _applyFilterState(state);
    setState(() {
      _reviewScope = null;
      _selectedRangeId = null;
    });
    _scheduleSearch();
  }

  Future<void> _openFilters() async {
    final options = _filterOptions;
    if (options == null) return;
    var draft = _currentFilterState;
    // null = calculating, -1 = no filter selected, 0 = no matching questions.
    final visibleResultCount = ValueNotifier<int?>(
      _hasExplicitScope ? _questions?.length : -1,
    );
    final visibleSavedRanges = ValueNotifier<List<PreferenceSummary>>(
      _savedRanges,
    );
    final canSaveDraft = ValueNotifier<bool>(false);
    final filterPanelKey = GlobalKey<FilterPanelState>();
    var receivedInitialState = false;
    Timer? countDebounce;
    var countRequestId = 0;
    var saveAvailabilityRequestId = 0;
    var filterOverlayOpen = true;

    void updateVisibleCount(FilterState state) {
      countDebounce?.cancel();
      final requestId = ++countRequestId;
      final hasSelection =
          _queryController.text.trim().isNotEmpty ||
          state.years.isNotEmpty ||
          state.regions.isNotEmpty ||
          state.types.isNotEmpty ||
          state.conceptTags.isNotEmpty ||
          state.examTypes.isNotEmpty ||
          state.knowledgeCards.isNotEmpty ||
          state.diffMin > 0 ||
          state.diffMax < 10 ||
          state.calcMin > 0 ||
          state.calcMax < 10;
      if (!hasSelection) {
        visibleResultCount.value = -1;
        return;
      }
      visibleResultCount.value = null;
      countDebounce = Timer(const Duration(milliseconds: 250), () async {
        try {
          final questions = await _repository.getFilteredQuestions(
            SearchFilters(
              name: '',
              keyword: _queryController.text,
              choiceCount: 0,
              fillCount: 0,
              solutionCount: 0,
              targetDifficulty: 0,
              years: state.years.toList(),
              regions: state.regions.toList(),
              conceptTags: state.conceptTags.toList(),
              knowledgeCards: state.knowledgeCards.toList(),
              diffMin: state.diffMin,
              diffMax: state.diffMax,
              calcMin: state.calcMin,
              calcMax: state.calcMax,
              examTypes: state.examTypes.toList(),
              questionTypes: state.types.toList(),
            ),
          );
          if (filterOverlayOpen && requestId == countRequestId) {
            visibleResultCount.value = questions.length;
          }
        } catch (_) {
          if (filterOverlayOpen && requestId == countRequestId) {
            visibleResultCount.value = 0;
          }
        }
      });
    }

    Future<int?> countFor(PreferenceSummary summary) async {
      try {
        final data = await _preferenceRepository.getEdit(summary.id);
        final f = data.filter;
        final questions = await _repository.getFilteredQuestions(
          SearchFilters(
            name: '',
            keyword: '',
            choiceCount: 0,
            fillCount: 0,
            solutionCount: 0,
            targetDifficulty: 0,
            years: f.years,
            regions: f.regions,
            conceptTags: f.conceptTags,
            knowledgeCards: f.knowledgeCards,
            diffMin: f.diffMin ?? 0,
            diffMax: f.diffMax ?? 10,
            calcMin: f.calcMin ?? 0,
            calcMax: f.calcMax ?? 10,
            examTypes: f.types,
            questionTypes: f.questionTypes,
          ),
        );
        return questions.length;
      } catch (_) {
        return null;
      }
    }

    bool matchesSavedFilter(FilterState state, PreferenceFilter filter) =>
        _setsEqual(state.years, filter.years.toSet()) &&
        _setsEqual(state.regions, filter.regions.toSet()) &&
        _setsEqual(state.conceptTags, filter.conceptTags.toSet()) &&
        _setsEqual(state.examTypes, filter.types.toSet()) &&
        _setsEqual(state.knowledgeCards, filter.knowledgeCards.toSet()) &&
        _setsEqual(state.types, filter.questionTypes.toSet()) &&
        state.diffMin == (filter.diffMin ?? 0) &&
        state.diffMax == (filter.diffMax ?? 10) &&
        state.calcMin == (filter.calcMin ?? 0) &&
        state.calcMax == (filter.calcMax ?? 10);

    bool hasSchemeConditions(FilterState state) =>
        state.years.isNotEmpty ||
        state.regions.isNotEmpty ||
        state.types.isNotEmpty ||
        state.conceptTags.isNotEmpty ||
        state.examTypes.isNotEmpty ||
        state.knowledgeCards.isNotEmpty ||
        state.diffMin > 0 ||
        state.diffMax < 10 ||
        state.calcMin > 0 ||
        state.calcMax < 10;

    Future<void> updateSaveAvailability(FilterState state) async {
      final requestId = ++saveAvailabilityRequestId;
      if (!hasSchemeConditions(state)) {
        if (filterOverlayOpen && requestId == saveAvailabilityRequestId) {
          canSaveDraft.value = false;
        }
        return;
      }
      try {
        for (final summary in visibleSavedRanges.value) {
          final saved = await _preferenceRepository.getEdit(summary.id);
          if (matchesSavedFilter(state, saved.filter)) {
            if (filterOverlayOpen && requestId == saveAvailabilityRequestId) {
              canSaveDraft.value = false;
            }
            return;
          }
        }
        if (filterOverlayOpen && requestId == saveAvailabilityRequestId) {
          canSaveDraft.value = true;
        }
      } catch (_) {
        if (filterOverlayOpen && requestId == saveAvailabilityRequestId) {
          canSaveDraft.value = true;
        }
      }
    }

    Widget conditionsPanel() => Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: FilterPanel(
              key: filterPanelKey,
              horizontalMargin: AppSpacing.md,
              yearOptions: options.years,
              regionOptions: options.regions,
              typeOptions: options.questionTypes,
              conceptTagOptions: options.conceptTags,
              conceptTagTree: options.conceptTagTree,
              examTypeOptions: options.examTypes,
              knowledgeCardOptions: options.knowledgeCards,
              knowledgeCardGroups: options.knowledgeCardGroups,
              selectAllInitially: false,
              allowGlobalSelectAll: false,
              showConceptSection: true,
              showKnowledgeSection: true,
              initialState: draft,
              onChanged: (state) {
                draft = state;
                if (!receivedInitialState) {
                  receivedInitialState = true;
                  if (visibleResultCount.value == null) {
                    updateVisibleCount(state);
                  }
                  updateSaveAvailability(state);
                  return;
                }
                updateSaveAvailability(state);
                updateVisibleCount(state);
              },
            ),
          ),
        ),
        ValueListenableBuilder<int?>(
          valueListenable: visibleResultCount,
          builder: (_, count, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppButton(
              label: switch (count) {
                null => '正在计算题目数量',
                -1 => '请先选择筛选条件',
                0 => '当前条件下暂无题目',
                _ => '查看当前的$count道题',
              },
              size: AppButtonSize.md,
              onPressed: count != null && count > 0
                  ? () {
                      Navigator.of(context).pop();
                      _commitFilterState(draft);
                    }
                  : null,
            ),
          ),
        ),
      ],
    );

    Future<void> refreshSavedRanges() async {
      final ranges = await _preferenceRepository.getList();
      if (!filterOverlayOpen) return;
      _savedRanges = ranges;
      visibleSavedRanges.value = ranges;
      await updateSaveAvailability(draft);
    }

    Widget schemesPanel(BuildContext overlayContext) => Column(
      children: [
        ValueListenableBuilder<List<PreferenceSummary>>(
          valueListenable: visibleSavedRanges,
          builder: (_, ranges, _) => Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '已保存方案 ${ranges.length}个',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: canSaveDraft,
                  builder: (_, enabled, _) => OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      textStyle: Theme.of(context).textTheme.bodySmall,
                    ),
                    onPressed: enabled
                        ? () async {
                            await _saveCurrentRange(draft);
                            await refreshSavedRanges();
                            canSaveDraft.value = false;
                          }
                        : null,
                    child: const Text('保存为方案'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    textStyle: Theme.of(context).textTheme.bodySmall,
                  ),
                  onPressed: () async {
                    await RouterUtils.push(
                      context,
                      AppRoutes.profilePreferences,
                    );
                    await refreshSavedRanges();
                  },
                  child: const Text('管理'),
                ),
              ],
            ),
          ),
        ),
        ValueListenableBuilder<int?>(
          valueListenable: visibleResultCount,
          builder: (_, count, _) {
            final hasConditions = hasSchemeConditions(draft);
            final warning = !hasConditions
                ? '当前没有设置筛选条件，无法保存方案。'
                : count == 0
                ? '当前条件暂无匹配题目。仍可保存，题库更新后结果可能变化。'
                : null;
            if (warning == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  warning,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: hasConditions
                        ? context.colors.warning
                        : context.colors.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
        Expanded(
          child: ValueListenableBuilder<List<PreferenceSummary>>(
            valueListenable: visibleSavedRanges,
            builder: (_, ranges, _) => ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: ranges.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, index) {
                final summary = ranges[index];
                final selected = _selectedRangeId == summary.id;
                return AppCard(
                  selected: selected,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  onTap: () async {
                    await _applySavedRange(summary);
                    if (overlayContext.mounted) {
                      Navigator.of(overlayContext).pop();
                    }
                  },
                  child: Row(
                    children: [
                      if (selected) ...[
                        Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: context.colors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    summary.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                FutureBuilder<int?>(
                                  future: countFor(summary),
                                  builder: (_, snapshot) => Text(
                                    snapshot.data == null
                                        ? '计算中'
                                        : '${snapshot.data}道',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: context.colors.textSecondary,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              summary.summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: context.colors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );

    Widget panel(BuildContext overlayContext) => DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              tabs: [
                Tab(text: '筛选条件'),
                Tab(text: '筛选方案'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _KeepAliveTab(child: conditionsPanel()),
                  _KeepAliveTab(child: schemesPanel(overlayContext)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final isPhone = MediaQuery.sizeOf(context).width < AppBreakpoints.medium;
    if (isPhone) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheetContext) => FractionallySizedBox(
          heightFactor: 0.82,
          child: panel(sheetContext),
        ),
      );
      filterOverlayOpen = false;
      countDebounce?.cancel();
      visibleResultCount.dispose();
      visibleSavedRanges.dispose();
      return;
    }

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭筛选条件',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, _) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Theme.of(dialogContext).colorScheme.surface,
          elevation: 8,
          child: SizedBox(
            width: 480,
            height: double.infinity,
            child: panel(dialogContext),
          ),
        ),
      ),
      transitionBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
    filterOverlayOpen = false;
    countDebounce?.cancel();
    visibleResultCount.dispose();
    visibleSavedRanges.dispose();
    canSaveDraft.dispose();
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    if (_applyingExternalScope) return;
    if (_reviewScope != null && _hasExplicitScope) {
      _reviewScope = null;
    }
    if (_selectedRangeId != null) {
      _selectedRangeId = null;
    }
    if (!_hasExplicitScope) {
      if (_questions != null || _loadingQuestions) {
        setState(() {
          _questions = null;
          _loadingQuestions = false;
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), _search);
  }

  Future<void> _selectReviewScope(QuestionReviewScope scope) async {
    _applyingExternalScope = true;
    _queryController.clear();
    _applyFilterState(const FilterState());
    _applyingExternalScope = false;
    setState(() {
      _reviewScope = scope;
      _selectedRangeId = null;
      _loadingQuestions = true;
      _error = null;
    });
    try {
      final questions = await _questionReviewRepository.getQuestions(scope);
      if (!mounted || _reviewScope != scope) return;
      setState(() {
        _questions = questions;
        _loadingQuestions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingQuestions = false;
        _error = '错题记录加载失败，请稍后重试';
      });
    }
  }

  Future<void> _applySavedRange(PreferenceSummary summary) async {
    try {
      final data = await _preferenceRepository.getEdit(summary.id);
      if (!mounted) return;
      final filter = data.filter;
      _applyingExternalScope = true;
      _applyFilterState(
        FilterState(
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
        ),
      );
      _applyingExternalScope = false;
      setState(() => _reviewScope = null);
      _scheduleSearch();
      setState(() => _selectedRangeId = summary.id);
    } catch (_) {
      _applyingExternalScope = false;
      if (!mounted) return;
      AppToast.error(context, '筛选方案加载失败，请稍后重试');
    }
  }

  bool get _hasExplicitScope =>
      _queryController.text.trim().isNotEmpty ||
      _years.isNotEmpty ||
      _regions.isNotEmpty ||
      _conceptTags.isNotEmpty ||
      _questionTypes.isNotEmpty ||
      _examTypes.isNotEmpty ||
      _knowledgeCards.isNotEmpty ||
      _difficultyMin > 0 ||
      _difficultyMax < 10 ||
      _calculationMin > 0 ||
      _calculationMax < 10;

  Future<void> _search() async {
    setState(() {
      _loadingQuestions = true;
      _error = null;
    });
    try {
      final questions = await _repository.getFilteredQuestions(
        SearchFilters(
          name: '',
          keyword: _queryController.text,
          choiceCount: 0,
          fillCount: 0,
          solutionCount: 0,
          targetDifficulty: 0,
          years: _years.toList(),
          regions: _regions.toList(),
          conceptTags: _conceptTags.toList(),
          knowledgeCards: _knowledgeCards.toList(),
          diffMin: _difficultyMin,
          diffMax: _difficultyMax,
          calcMin: _calculationMin,
          calcMax: _calculationMax,
          examTypes: _examTypes.toList(),
          questionTypes: _questionTypes.toList(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loadingQuestions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '题库加载失败，请稍后重试';
        _loadingQuestions = false;
      });
    }
  }

  int get _selectedFilterGroupCount => [
    _conceptTags.isNotEmpty,
    _knowledgeCards.isNotEmpty,
    _years.isNotEmpty,
    _regions.isNotEmpty,
    _examTypes.isNotEmpty,
    _questionTypes.isNotEmpty,
    _difficultyMin > 0 || _difficultyMax < 10,
    _calculationMin > 0 || _calculationMax < 10,
  ].where((selected) => selected).length;

  bool _setsEqual<T>(Set<T> left, Set<T> right) =>
      left.length == right.length && left.containsAll(right);

  Future<void> _saveCurrentRange([FilterState? draft]) async {
    if (_reviewScope != null) return;
    final state = draft ?? _currentFilterState;
    final controller = TextEditingController(text: '我的筛选方案');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('保存筛选方案'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: '方案名称'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('保存内容', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              if (state.conceptTags.isNotEmpty)
                Text('概念标签：${state.conceptTags.length}项'),
              if (state.knowledgeCards.isNotEmpty)
                Text('知识卡片：${state.knowledgeCards.length}项'),
              if (state.years.isNotEmpty) Text('年份：${state.years.join('、')}'),
              if (state.regions.isNotEmpty)
                Text('地区：${state.regions.join('、')}'),
              if (state.examTypes.isNotEmpty)
                Text('考试类型：${state.examTypes.join('、')}'),
              if (state.types.isNotEmpty)
                Text('题型：${state.types.map(QuestionTypeLabels.of).join('、')}'),
              Text(
                '难度：${state.diffMin.toStringAsFixed(0)}—${state.diffMax.toStringAsFixed(0)}',
              ),
              Text(
                '计算量：${state.calcMin.toStringAsFixed(0)}—${state.calcMax.toStringAsFixed(0)}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          AppButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(dialogContext).pop(value);
              }
            },
            label: '保存',
            expanded: false,
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    try {
      final id = await _preferenceRepository.save(
        name: result,
        filter: PreferenceFilter(
          years: state.years.toList(),
          regions: state.regions.toList(),
          conceptTags: state.conceptTags.toList(),
          types: state.examTypes.toList(),
          knowledgeCards: state.knowledgeCards.toList(),
          questionTypes: state.types.toList(),
          diffMin: state.diffMin > 0 ? state.diffMin : null,
          diffMax: state.diffMax < 10 ? state.diffMax : null,
          calcMin: state.calcMin > 0 ? state.calcMin : null,
          calcMax: state.calcMax < 10 ? state.calcMax : null,
        ),
      );
      final ranges = await _preferenceRepository.getList();
      if (!mounted) return;
      setState(() {
        _savedRanges = ranges;
        _selectedRangeId = id;
      });
      AppToast.success(context, '已保存筛选方案');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, '保存失败，请稍后重试');
    }
  }

  void _openQuestion(SearchQuestion question) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentQuestionDetailPage(questionId: question.id),
      ),
    );
  }

  // Retained for compatibility with older deep-link flows during migration.
  // ignore: unused_element
  Future<void> _createPaper() async {
    if (_selectedQuestions.isEmpty || _creatingPaper) return;
    await _createManualDraft(
      _selectedQuestions.values.toList(growable: false),
      initialName: '我的选题卷',
      clearBasketOnSuccess: true,
    );
  }

  Future<void> _createManualDraft(
    List<SearchQuestion> questions, {
    required String initialName,
    required bool clearBasketOnSuccess,
    bool downloadAfterCreate = false,
  }) async {
    final draft = await showDialog<PaperDraft>(
      context: context,
      builder: (_) => PaperDraftDialog(
        initialName: initialName,
        questions: questions,
        cost: paperCreationCost,
      ),
    );
    if (draft == null || !mounted) return;

    setState(() => _creatingPaper = true);
    try {
      final paperId = await _paperCreationService.createManualPaper(
        name: draft.name,
        selectedIds: draft.questions
            .map((question) => question.id)
            .toList(growable: false),
      );
      if (!mounted) return;
      if (clearBasketOnSuccess) {
        setState(() {
          _selectedQuestions.clear();
        });
        _workspaceController.clear();
      }
      if (downloadAfterCreate && mounted) {
        await PdfHelper.downloadPdf(
          sourceId: paperId,
          sourceType: 'paper',
          context: context,
        );
      }
      if (!mounted) return;
      RouterUtils.push(context, '${AppRoutes.examQuicklook}?id=$paperId');
    } on InsufficientPointsException catch (error) {
      if (!mounted) return;
      AppToast.warning(context, '积分不足，生成手选试卷需要 ${error.requiredPoints} 积分');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, '生成试卷失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _creatingPaper = false);
    }
  }

  Future<void> _createSmartPaper() async {
    final candidates = _questions;
    if (candidates == null || candidates.isEmpty || _creatingPaper) return;
    final candidateIds = candidates.map((question) => question.id).toSet();
    final selectedOutsidePool = _selectedQuestions.keys
        .where((id) => !candidateIds.contains(id))
        .length;
    final totalAvailable = candidates.length + selectedOutsidePool;
    final requestedCount = await showDialog<int>(
      context: context,
      builder: (_) => _SmartPaperCountDialog(
        lockedCount: _selectedQuestions.length,
        totalAvailable: totalAvailable,
      ),
    );
    if (requestedCount == null || !mounted) return;

    final selected = _selectedQuestions.values.toList(growable: false);
    final draftQuestions = _smartDraftSelector.select(
      locked: selected,
      candidates: candidates,
      requestedCount: requestedCount,
    );
    setState(() => _creatingPaper = true);
    try {
      setState(() {
        _selectedQuestions
          ..clear()
          ..addEntries(
            draftQuestions.map((question) => MapEntry(question.id, question)),
          );
      });
      _workspaceController.replace(_selectedQuestions.keys);
      if (!mounted) return;
      AppToast.success(context, selected.isEmpty ? '已完成智能选题' : '已完成智能补全');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, '智能选题失败，请调整条件后重试');
    } finally {
      if (mounted) setState(() => _creatingPaper = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _filterOptions;
    final isReviewList = widget.initialReviewScope != null;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(switch (widget.initialReviewScope) {
          QuestionReviewScope.currentWrong => '当前错题',
          QuestionReviewScope.corrected => '已订正',
          null => '题库选题',
        }),
      ),
      body: options == null && _error == null
          ? const LoadingIndicator(message: '正在加载题库')
          : AppContentContainer(
              maxWidth: AppContentWidth.standard,
              child: RefreshIndicator(
                onRefresh: _loadFilterOptions,
                child: QuestionWorkspace(
                  controller: _workspaceController,
                  basketRepository: _paperFolderRepository,
                  scrollController: _scrollController,
                  items: (_questions ?? const <SearchQuestion>[])
                      .map(
                        (question) => QuestionWorkspaceItem(
                          id: question.id,
                          title: question.title,
                          questionType: question.questionType,
                          subtitle: question.meta,
                          difficulty: question.difficulty,
                        ),
                      )
                      .toList(growable: false),
                  onOpen: (item) => _openQuestion(
                    _questions!.firstWhere(
                      (question) => question.id == item.id,
                    ),
                  ),
                  onSelectionChanged: (ids) {
                    final questionsById = {
                      for (final question
                          in _questions ?? const <SearchQuestion>[])
                        question.id: question,
                    };
                    setState(() {
                      _selectedQuestions.removeWhere(
                        (id, question) => !ids.contains(id),
                      );
                      for (final id in ids) {
                        final question = questionsById[id];
                        if (question != null) _selectedQuestions[id] = question;
                      }
                    });
                  },
                  stateSlivers: _buildResultSlivers(),
                  headerSliversBuilder: (context, selectedIds) => [
                    if (isReviewList)
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.md),
                      ),
                    if (!isReviewList) ...[
                      if (options != null)
                        SliverPadding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          sliver: SliverToBoxAdapter(
                            child: _KeywordSearchBrowser(
                              controller: _queryController,
                              onChanged: (_) => _scheduleSearch(),
                              onSubmitted: (_) => _search(),
                              hasActiveFilters: _selectedFilterGroupCount > 0,
                              onOpenFilters: _openFilters,
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.md,
                          bottom: AppSpacing.xs,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _QuestionResultsHeader(
                            key: _resultsKey,
                            questions: _questions,
                            onSmartPaper: _createSmartPaper,
                            creatingPaper: _creatingPaper,
                            hasSelectedQuestions: _selectedQuestions.isNotEmpty,
                            showTitle: _selectedFilterGroupCount > 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget>? _buildResultSlivers() {
    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorPlaceholder(
            message: _error!,
            onRetry: _loadFilterOptions,
          ),
        ),
      ];
    }
    if (_loadingQuestions) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: LoadingIndicator(message: '正在搜索题目'),
        ),
      ];
    }
    final questions = _questions;
    if (questions == null || questions.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyPlaceholder(
            icon: questions == null
                ? Icons.manage_search_rounded
                : Icons.search_off_rounded,
            message: questions == null ? '设置筛选条件后显示题目' : '没有找到匹配的题目',
          ),
        ),
      ];
    }
    return null;
  }
}

class _VirtualPaperBrowser extends StatefulWidget {
  const _VirtualPaperBrowser({
    required this.papers,
    required this.selected,
    required this.onSelected,
    required this.onAction,
  });

  final List<VirtualPaper> papers;
  final VirtualPaper? selected;
  final ValueChanged<VirtualPaper> onSelected;
  final void Function(VirtualPaper, _VirtualPaperAction) onAction;

  @override
  State<_VirtualPaperBrowser> createState() => _VirtualPaperBrowserState();
}

class _VirtualPaperBrowserState extends State<_VirtualPaperBrowser> {
  String? _expandedExamType;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<VirtualPaper>>{};
    for (final paper in widget.papers) {
      groups.putIfAbsent(paper.examType, () => []).add(paper);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: '按套卷浏览', subtitle: '先选择考试类型，再进入具体年份和地区。'),
        const SizedBox(height: AppSpacing.sm),
        ...groups.entries.map((entry) {
          final yearGroups = <int, List<VirtualPaper>>{};
          for (final paper in entry.value) {
            yearGroups.putIfAbsent(paper.year, () => []).add(paper);
          }
          final years = yearGroups.keys.toList()
            ..sort((a, b) => b.compareTo(a));
          return ExpansionTile(
            key: ValueKey('${entry.key}:${_expandedExamType == entry.key}'),
            initiallyExpanded: _expandedExamType == entry.key,
            onExpansionChanged: (expanded) =>
                setState(() => _expandedExamType = expanded ? entry.key : null),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(
              left: AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            leading: const Icon(Icons.description_outlined),
            title: Text(entry.key),
            subtitle: Text('${entry.value.length} 套'),
            children: years.map((year) {
              final papers = yearGroups[year]!
                ..sort((a, b) => a.region.compareTo(b.region));
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 52,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          '$year',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: papers
                            .map(
                              (paper) => _VirtualPaperChip(
                                paper: paper,
                                selected:
                                    widget.selected?.year == paper.year &&
                                    widget.selected?.region == paper.region &&
                                    widget.selected?.examType == paper.examType,
                                onSelected: () {
                                  setState(() => _expandedExamType = null);
                                  widget.onSelected(paper);
                                },
                                onAction: (action) =>
                                    widget.onAction(paper, action),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}

class _VirtualPaperChip extends StatelessWidget {
  const _VirtualPaperChip({
    required this.paper,
    required this.selected,
    required this.onSelected,
    required this.onAction,
  });

  final VirtualPaper paper;
  final bool selected;
  final VoidCallback onSelected;
  final ValueChanged<_VirtualPaperAction> onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? context.colors.primaryContainer : null,
        border: Border.all(
          color: selected ? context.colors.primary : context.colors.border,
        ),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            onTap: onSelected,
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 8, selected ? 6 : 10, 8),
              child: Text(
                paper.region,
                style: TextStyle(
                  color: selected
                      ? context.colors.primary
                      : context.colors.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
          if (selected)
            PopupMenuButton<_VirtualPaperAction>(
              tooltip: '${paper.year}年${paper.region}${paper.examType}操作',
              padding: EdgeInsets.zero,
              iconSize: 18,
              onSelected: onAction,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _VirtualPaperAction.addToBasket,
                  child: Text('加入试题篮'),
                ),
                PopupMenuItem(
                  value: _VirtualPaperAction.createPaper,
                  child: Text('整套组卷'),
                ),
                PopupMenuItem(
                  value: _VirtualPaperAction.createAndDownload,
                  child: Text('生成并下载'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _QuestionResultsHeader extends StatelessWidget {
  const _QuestionResultsHeader({
    super.key,
    required this.questions,
    required this.onSmartPaper,
    required this.creatingPaper,
    required this.hasSelectedQuestions,
    required this.showTitle,
  });

  final List<SearchQuestion>? questions;
  final VoidCallback onSmartPaper;
  final bool creatingPaper;
  final bool hasSelectedQuestions;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final items = questions;
    if (items == null || items.isEmpty) {
      return showTitle
          ? const AppSectionHeader(title: '题目结果')
          : const SizedBox.shrink();
    }
    final choice = items
        .where((question) => question.questionType == 'choice')
        .length;
    final fill = items
        .where((question) => question.questionType == 'fill')
        .length;
    final solution = items
        .where((question) => question.questionType == 'solution')
        .length;
    final averageDifficulty =
        items.fold<double>(0, (sum, question) => sum + question.difficulty) /
        items.length;
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: context.colors.textMuted);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (showTitle) const TextSpan(text: '题目结果 · '),
                      TextSpan(
                        text: '共 ${items.length} 道',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                ),
                onPressed: creatingPaper ? null : onSmartPaper,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(hasSelectedQuestions ? '智能补全' : '智能选题'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          LayoutBuilder(
            builder: (context, constraints) {
              final typeSummary = '选择题 $choice · 填空题 $fill · 解答题 $solution';
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(typeSummary, style: style),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '平均难度 ${averageDifficulty.toStringAsFixed(1)}',
                      style: style,
                    ),
                  ],
                );
              }
              return Text(
                '$typeSummary · 难度 ${averageDifficulty.toStringAsFixed(1)}',
                style: style,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _KeywordSearchBrowser extends StatelessWidget {
  const _KeywordSearchBrowser({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.hasActiveFilters,
    required this.onOpenFilters,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final bool hasActiveFilters;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionSearchField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          trailing: TextButton(
            onPressed: onOpenFilters,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              textStyle: Theme.of(context).textTheme.bodyMedium,
              foregroundColor: context.colors.primary,
              backgroundColor: hasActiveFilters
                  ? context.colors.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tune_rounded, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text(hasActiveFilters ? '已筛选' : '筛选'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SmartPaperCountDialog extends StatefulWidget {
  const _SmartPaperCountDialog({
    required this.lockedCount,
    required this.totalAvailable,
  });

  final int lockedCount;
  final int totalAvailable;

  @override
  State<_SmartPaperCountDialog> createState() => _SmartPaperCountDialogState();
}

class _SmartPaperCountDialogState extends State<_SmartPaperCountDialog> {
  late final TextEditingController _controller;
  String? _error;

  int get _minimum => widget.lockedCount == 0 ? 1 : widget.lockedCount;

  @override
  void initState() {
    super.initState();
    final defaultCount = widget.lockedCount == 0 ? 21 : widget.lockedCount + 5;
    _controller = TextEditingController(
      text: defaultCount.clamp(_minimum, widget.totalAvailable).toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final count = int.tryParse(_controller.text.trim());
    if (count == null || count < _minimum || count > widget.totalAvailable) {
      setState(() => _error = '请输入 $_minimum—${widget.totalAvailable} 之间的数量');
      return;
    }
    Navigator.of(context).pop(count);
  }

  @override
  Widget build(BuildContext context) {
    final supplementing = widget.lockedCount > 0;
    final presets = <int>{10, 15, 21}
        .where((count) => count >= _minimum && count <= widget.totalAvailable)
        .toList();
    return AlertDialog(
      title: Text(supplementing ? '智能补全' : '智能选题'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            supplementing
                ? '试题篮已有 ${widget.lockedCount} 道，请设置补全后的数量。'
                : '设置选题数量，系统会从当前 ${widget.totalAvailable} 道结果中均衡选取。',
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '最终数量',
              suffixText: '道',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (presets.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: presets
                  .map(
                    (count) => ActionChip(
                      label: Text('$count 道'),
                      onPressed: () => setState(() {
                        _controller.text = count.toString();
                        _error = null;
                      }),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(supplementing ? '开始补全' : '开始选题'),
        ),
      ],
    );
  }
}

class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child});

  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
