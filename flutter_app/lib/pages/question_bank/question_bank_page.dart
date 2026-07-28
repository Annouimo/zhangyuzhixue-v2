import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/daos/preference_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/exam_repository.dart';
import '../../domain/paper_creation_service.dart';
import '../../domain/question_review_repository.dart';
import '../../domain/smart_paper_draft_selector.dart';
import '../../domain/preference_repository.dart';
import '../../domain/user_repository.dart';
import '../../data/api/api_client.dart';
import '../../data/api/user_api.dart';
import '../../data/daos/user_dao.dart';
import '../../widgets/question_search_field.dart';
import '../../widgets/question_search_results.dart';
import '../router.dart';
import 'question_detail_page.dart';
import 'paper_draft_dialog.dart';

class StudentQuestionBankPage extends StatefulWidget {
  const StudentQuestionBankPage({
    super.key,
    this.examRepository,
    this.virtualPaperRepository,
    this.questionReviewRepository,
    this.preferenceRepository,
  });

  final QuestionLibraryRepository? examRepository;
  final VirtualPaperRepository? virtualPaperRepository;
  final QuestionReviewRepository? questionReviewRepository;
  final PreferenceRepository? preferenceRepository;

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
  late final VirtualPaperRepository _virtualPaperRepository =
      widget.virtualPaperRepository ??
      LocalVirtualPaperRepository(QuestionDao(DatabaseProvider()));
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
  static const _smartDraftSelector = SmartPaperDraftSelector();
  final _filterKey = GlobalKey<FilterPanelState>();
  final _queryController = TextEditingController();
  FilterOptions? _filterOptions;
  List<VirtualPaper> _virtualPapers = const [];
  QuestionReviewSummary _reviewSummary = const QuestionReviewSummary(
    currentWrongCount: 0,
    correctedCount: 0,
  );
  List<PreferenceSummary> _savedRanges = const [];
  List<SearchQuestion>? _questions;
  Timer? _debounce;
  bool _loadingQuestions = false;
  bool _selectionMode = false;
  bool _creatingPaper = false;
  final Map<int, SearchQuestion> _selectedQuestions = {};
  QuestionReviewScope? _reviewScope;
  int? _selectedRangeId;
  bool _applyingExternalScope = false;
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
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final results = await Future.wait([
        _repository.getFilterOptions(),
        _virtualPaperRepository.getVirtualPapers(),
        _questionReviewRepository.getSummary(),
        _preferenceRepository.getList(),
      ]);
      if (!mounted) return;
      setState(() {
        _filterOptions = results[0] as FilterOptions;
        _virtualPapers = results[1] as List<VirtualPaper>;
        _reviewSummary = results[2] as QuestionReviewSummary;
        _savedRanges = results[3] as List<PreferenceSummary>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = '题库筛选条件加载失败，请稍后重试');
    }
  }

  void _selectVirtualPaper(VirtualPaper paper) {
    _queryController.clear();
    _applyFilterState(
      FilterState(
        years: {paper.year.toString()},
        regions: {paper.region},
        examTypes: {paper.examType},
      ),
    );
    setState(() {
      _reviewScope = null;
      _selectedRangeId = null;
    });
    _scheduleSearch();
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
    _filterKey.currentState?.applyFilter(
      years: state.years,
      regions: state.regions,
      conceptTags: state.conceptTags,
      examTypes: state.examTypes,
      knowledgeCards: state.knowledgeCards,
      types: state.types,
      diffMin: state.diffMin,
      diffMax: state.diffMax,
      calcMin: state.calcMin,
      calcMax: state.calcMax,
      sort: state.sort,
    );
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
      _queryController.clear();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('常用范围加载失败，请稍后重试')));
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

  void _openQuestion(SearchQuestion question) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentQuestionDetailPage(questionId: question.id),
      ),
    );
  }

  void _toggleQuestion(SearchQuestion question) {
    setState(() {
      if (_selectedQuestions.containsKey(question.id)) {
        _selectedQuestions.remove(question.id);
      } else {
        _selectedQuestions[question.id] = question;
      }
    });
  }

  Future<void> _createPaper() async {
    if (_selectedQuestions.isEmpty || _creatingPaper) return;
    final draft = await showDialog<PaperDraft>(
      context: context,
      builder: (_) => PaperDraftDialog(
        initialName: '我的选题卷',
        questions: _selectedQuestions.values.toList(growable: false),
        cost: manualPaperCost,
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
      setState(() {
        _selectedQuestions.clear();
        _selectionMode = false;
      });
      RouterUtils.push(context, '${AppRoutes.examQuicklook}?id=$paperId');
    } on InsufficientPointsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('积分不足，生成手选试卷需要 ${error.requiredPoints} 积分')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('生成试卷失败，请稍后重试')));
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
    final countOptions = <int>{
      10.clamp(1, totalAvailable),
      15.clamp(1, totalAvailable),
      21.clamp(1, totalAvailable),
    }.toList()..sort();
    final requestedCount = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(_selectedQuestions.isEmpty ? '智能选题' : '智能补足'),
        children: countOptions
            .map(
              (count) => SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(count),
                child: Text('生成 $count 题'),
              ),
            )
            .toList(growable: false),
      ),
    );
    if (requestedCount == null || !mounted) return;

    final selected = _selectedQuestions.values.toList(growable: false);
    final draftQuestions = _smartDraftSelector.select(
      locked: selected,
      candidates: candidates,
      requestedCount: requestedCount,
    );
    final cost = selected.isEmpty ? smartPaperCost : manualPaperCost;
    final description = selected.isEmpty ? '智能选题' : '智能补足';
    final draft = await showDialog<PaperDraft>(
      context: context,
      builder: (_) => PaperDraftDialog(
        initialName: '智能练习卷',
        questions: draftQuestions,
        cost: cost,
      ),
    );
    if (draft == null || !mounted) return;

    setState(() => _creatingPaper = true);
    try {
      final paperId = await _paperCreationService.createDraftPaper(
        name: draft.name,
        questionIds: draft.questions
            .map((question) => question.id)
            .toList(growable: false),
        cost: cost,
        description: description,
      );
      if (!mounted) return;
      setState(() {
        _selectedQuestions.clear();
        _selectionMode = false;
      });
      RouterUtils.push(context, '${AppRoutes.examQuicklook}?id=$paperId');
    } on InsufficientPointsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('积分不足，本次生成需要 ${error.requiredPoints} 积分')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('智能选题失败，请调整范围后重试')));
    } finally {
      if (mounted) setState(() => _creatingPaper = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _filterOptions;
    return Scaffold(
      appBar: AppBar(title: const Text('题库')),
      bottomNavigationBar: _selectionMode
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border(top: BorderSide(color: context.colors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '已选 ${_selectedQuestions.length} 题',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: _selectedQuestions.isEmpty
                          ? null
                          : () => setState(_selectedQuestions.clear),
                      child: const Text('清空'),
                    ),
                    IconButton(
                      tooltip: '智能补足',
                      onPressed: _creatingPaper ? null : _createSmartPaper,
                      icon: const Icon(Icons.auto_awesome_rounded),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      onPressed: _selectedQuestions.isEmpty || _creatingPaper
                          ? null
                          : _createPaper,
                      icon: Icons.description_outlined,
                      label: '生成试卷',
                      expanded: false,
                      loading: _creatingPaper,
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: options == null && _error == null
          ? const LoadingIndicator(message: '正在加载题库')
          : AppContentContainer(
              maxWidth: AppContentWidth.standard,
              child: RefreshIndicator(
                onRefresh: _loadFilterOptions,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      sliver: SliverToBoxAdapter(
                        child: QuestionSearchField(
                          controller: _queryController,
                          onChanged: (_) => _scheduleSearch(),
                          onSubmitted: (_) => _search(),
                        ),
                      ),
                    ),
                    if (options != null)
                      SliverPadding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        sliver: SliverToBoxAdapter(
                          child: _QuestionReviewBrowser(
                            summary: _reviewSummary,
                            selectedScope: _reviewScope,
                            onSelected: _selectReviewScope,
                          ),
                        ),
                      ),
                    if (options != null && _savedRanges.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        sliver: SliverToBoxAdapter(
                          child: _SavedRangeBrowser(
                            ranges: _savedRanges,
                            selectedId: _selectedRangeId,
                            onSelected: _applySavedRange,
                          ),
                        ),
                      ),
                    if (options != null)
                      SliverPadding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        sliver: SliverToBoxAdapter(
                          child: _VirtualPaperBrowser(
                            papers: _virtualPapers,
                            onSelected: _selectVirtualPaper,
                          ),
                        ),
                      ),
                    if (options != null)
                      SliverPadding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppSectionHeader(
                                title: '自定义范围',
                                subtitle: '需要更精确时，再按来源、专题、知识卡片或难度限定。',
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              FilterPanel(
                                key: _filterKey,
                                horizontalMargin: 0,
                                yearOptions: options.years,
                                regionOptions: options.regions,
                                typeOptions: options.questionTypes,
                                conceptTagOptions: options.conceptTags,
                                conceptTagTree: options.conceptTagTree,
                                examTypeOptions: options.examTypes,
                                knowledgeCardOptions: options.knowledgeCards,
                                knowledgeCardGroups:
                                    options.knowledgeCardGroups,
                                selectAllInitially: false,
                                allowGlobalSelectAll: false,
                                initialState: _currentFilterState,
                                onChanged: (state) {
                                  _years = state.years;
                                  _regions = state.regions;
                                  _conceptTags = state.conceptTags;
                                  _questionTypes = state.types;
                                  _examTypes = state.examTypes;
                                  _knowledgeCards = state.knowledgeCards;
                                  _difficultyMin = state.diffMin;
                                  _difficultyMax = state.diffMax;
                                  _calculationMin = state.calcMin;
                                  _calculationMax = state.calcMax;
                                  _scheduleSearch();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.lg,
                        bottom: AppSpacing.sm,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: AppSectionHeader(
                          title: _questions == null
                              ? '题目结果'
                              : '题目结果 · ${_questions!.length} 题',
                          action: _questions?.isNotEmpty == true
                              ? Wrap(
                                  spacing: AppSpacing.xs,
                                  children: [
                                    TextButton.icon(
                                      onPressed: _creatingPaper
                                          ? null
                                          : _createSmartPaper,
                                      icon: const Icon(
                                        Icons.auto_awesome_rounded,
                                      ),
                                      label: const Text('智能选题'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => setState(
                                        () => _selectionMode = !_selectionMode,
                                      ),
                                      icon: Icon(
                                        _selectionMode
                                            ? Icons.close_rounded
                                            : Icons.playlist_add_rounded,
                                      ),
                                      label: Text(
                                        _selectionMode ? '退出选题' : '手动选题',
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                    ..._buildResultSlivers(),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xl),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildResultSlivers() {
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
    return [
      SliverList.builder(
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          return QuestionSearchResultCard(
            question: question,
            onOpen: () => _openQuestion(question),
            selected: _selectionMode
                ? _selectedQuestions.containsKey(question.id)
                : null,
            onToggle: _selectionMode ? () => _toggleQuestion(question) : null,
          );
        },
      ),
    ];
  }
}

class _VirtualPaperBrowser extends StatelessWidget {
  const _VirtualPaperBrowser({required this.papers, required this.onSelected});

  final List<VirtualPaper> papers;
  final ValueChanged<VirtualPaper> onSelected;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<VirtualPaper>>{};
    for (final paper in papers) {
      groups.putIfAbsent(paper.examType, () => []).add(paper);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: '按套卷浏览', subtitle: '先选择考试类型，再进入具体年份和地区。'),
        const SizedBox(height: AppSpacing.sm),
        ...groups.entries.map(
          (entry) => ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(left: AppSpacing.md),
            leading: const Icon(Icons.description_outlined),
            title: Text(entry.key),
            subtitle: Text('${entry.value.length} 套'),
            children: entry.value
                .map(
                  (paper) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${paper.year}年 · ${paper.region}'),
                    subtitle: Text('${paper.questionCount}题'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => onSelected(paper),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _QuestionReviewBrowser extends StatelessWidget {
  const _QuestionReviewBrowser({
    required this.summary,
    required this.selectedScope,
    required this.onSelected,
  });

  final QuestionReviewSummary summary;
  final QuestionReviewScope? selectedScope;
  final ValueChanged<QuestionReviewScope> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: '我的内容'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ReviewScopeTile(
                icon: Icons.error_outline_rounded,
                label: '当前错题',
                count: summary.currentWrongCount,
                selected: selectedScope == QuestionReviewScope.currentWrong,
                onTap: () => onSelected(QuestionReviewScope.currentWrong),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ReviewScopeTile(
                icon: Icons.task_alt_rounded,
                label: '已订正',
                count: summary.correctedCount,
                selected: selectedScope == QuestionReviewScope.corrected,
                onTap: () => onSelected(QuestionReviewScope.corrected),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SavedRangeBrowser extends StatelessWidget {
  const _SavedRangeBrowser({
    required this.ranges,
    required this.selectedId,
    required this.onSelected,
  });

  final List<PreferenceSummary> ranges;
  final int? selectedId;
  final ValueChanged<PreferenceSummary> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: '常用范围', subtitle: '快速恢复保存过的选题条件。'),
        const SizedBox(height: AppSpacing.sm),
        ...ranges.map(
          (range) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              selectedId == range.id
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_outline_rounded,
              color: selectedId == range.id
                  ? context.colors.primary
                  : context.colors.textSecondary,
            ),
            title: Text(range.name),
            subtitle: range.summary.isEmpty ? null : Text(range.summary),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => onSelected(range),
          ),
        ),
      ],
    );
  }
}

class _ReviewScopeTile extends StatelessWidget {
  const _ReviewScopeTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      semanticLabel: '$label $count题',
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            icon,
            color: selected
                ? context.colors.primary
                : context.colors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label)),
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: selected
                  ? context.colors.primary
                  : context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
