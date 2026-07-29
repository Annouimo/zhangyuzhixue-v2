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

enum _QuestionLibraryMode { papers, topics, knowledge, mine }

enum _VirtualPaperAction { addToBasket, createPaper, createAndDownload }

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
  final _resultsKey = GlobalKey();
  final _scrollController = ScrollController();
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
  bool _creatingPaper = false;
  final Map<int, SearchQuestion> _selectedQuestions = {};
  QuestionReviewScope? _reviewScope;
  int? _selectedRangeId;
  VirtualPaper? _selectedVirtualPaper;
  _QuestionLibraryMode _mode = _QuestionLibraryMode.papers;
  bool _advancedExpanded = false;
  bool _revealResultsAfterSearch = false;
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
    _scrollController.dispose();
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
    _revealResultsAfterSearch = true;
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
      _selectedVirtualPaper = paper;
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
    if (_selectedVirtualPaper != null &&
        (_years.length != 1 ||
            !_years.contains(_selectedVirtualPaper!.year.toString()) ||
            _regions.length != 1 ||
            !_regions.contains(_selectedVirtualPaper!.region) ||
            _examTypes.length != 1 ||
            !_examTypes.contains(_selectedVirtualPaper!.examType))) {
      _selectedVirtualPaper = null;
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
    _revealResultsAfterSearch = true;
    _applyingExternalScope = true;
    _queryController.clear();
    _applyFilterState(const FilterState());
    _applyingExternalScope = false;
    setState(() {
      _reviewScope = scope;
      _selectedRangeId = null;
      _selectedVirtualPaper = null;
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
      _revealResultsIfRequested();
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
      _revealResultsAfterSearch = true;
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
      _selectedVirtualPaper = null;
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
      _revealResultsIfRequested();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '题库加载失败，请稍后重试';
        _loadingQuestions = false;
      });
    }
  }

  void _revealResultsIfRequested() {
    if (!_revealResultsAfterSearch) return;
    _revealResultsAfterSearch = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _resultsKey.currentContext;
      if (!mounted || target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  String? get _currentScopeLabel {
    if (_reviewScope == QuestionReviewScope.currentWrong) return '当前错题';
    if (_reviewScope == QuestionReviewScope.corrected) return '已订正';
    if (_selectedRangeId != null) {
      for (final range in _savedRanges) {
        if (range.id == _selectedRangeId) return range.name;
      }
    }
    final keyword = _queryController.text.trim();
    final paper = _selectedVirtualPaper;
    if (paper != null) {
      final paperLabel = '${paper.year}年 · ${paper.region} · ${paper.examType}';
      return keyword.isEmpty ? paperLabel : '“$keyword” · $paperLabel';
    }
    final labels = <String>[
      if (_years.isNotEmpty) _years.join('/'),
      if (_regions.isNotEmpty) _regions.join('/'),
      if (_examTypes.isNotEmpty) _examTypes.join('/'),
      if (_conceptTags.isNotEmpty) '专题 ${_conceptTags.length}',
      if (_knowledgeCards.isNotEmpty) '知识卡片 ${_knowledgeCards.length}',
      if (_questionTypes.isNotEmpty) '题型 ${_questionTypes.length}',
    ];
    if (keyword.isNotEmpty) labels.insert(0, '“$keyword”');
    return labels.isEmpty ? null : labels.join(' · ');
  }

  void _clearScope() {
    _debounce?.cancel();
    _queryController.clear();
    _applyFilterState(const FilterState());
    setState(() {
      _reviewScope = null;
      _selectedRangeId = null;
      _selectedVirtualPaper = null;
      _questions = null;
      _loadingQuestions = false;
      _error = null;
    });
  }

  void _applyTopicSelection(Set<String> names) {
    _applyFilterState(_currentFilterState.copyWith(conceptTags: names));
    setState(() {
      _reviewScope = null;
      _selectedRangeId = null;
      _selectedVirtualPaper = null;
    });
    _scheduleSearch();
  }

  void _applyKnowledgeSelection(Set<String> titles) {
    _applyFilterState(_currentFilterState.copyWith(knowledgeCards: titles));
    setState(() {
      _reviewScope = null;
      _selectedRangeId = null;
      _selectedVirtualPaper = null;
    });
    _scheduleSearch();
  }

  void _changeMode(_QuestionLibraryMode mode) {
    if (mode == _mode) return;
    _debounce?.cancel();
    _applyingExternalScope = true;
    _applyFilterState(
      _currentFilterState.copyWith(
        years: const {},
        regions: const {},
        conceptTags: const {},
        examTypes: const {},
        knowledgeCards: const {},
      ),
    );
    _applyingExternalScope = false;
    setState(() {
      _mode = mode;
      _reviewScope = null;
      _selectedRangeId = null;
      _selectedVirtualPaper = null;
      if (!_hasExplicitScope) _questions = null;
    });
    if (_hasExplicitScope) _scheduleSearch();
  }

  Future<void> _saveCurrentRange() async {
    if (!_hasExplicitScope || _reviewScope != null) return;
    final controller = TextEditingController(
      text: _currentScopeLabel ?? '常用范围',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('保存常用范围'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '范围名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          AppButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.of(dialogContext).pop(value);
            },
            label: '保存',
            expanded: false,
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !mounted) return;
    try {
      final id = await _preferenceRepository.save(
        name: name,
        filter: PreferenceFilter(
          years: _years.toList(),
          regions: _regions.toList(),
          conceptTags: _conceptTags.toList(),
          types: _examTypes.toList(),
          knowledgeCards: _knowledgeCards.toList(),
          questionTypes: _questionTypes.toList(),
          diffMin: _difficultyMin > 0 ? _difficultyMin : null,
          diffMax: _difficultyMax < 10 ? _difficultyMax : null,
          calcMin: _calculationMin > 0 ? _calculationMin : null,
          calcMax: _calculationMax < 10 ? _calculationMax : null,
        ),
      );
      final ranges = await _preferenceRepository.getList();
      if (!mounted) return;
      setState(() {
        _savedRanges = ranges;
        _selectedRangeId = id;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已保存为常用范围')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存失败，请稍后重试')));
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
      if (clearBasketOnSuccess) {
        setState(() {
          _selectedQuestions.clear();
        });
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

  Future<List<SearchQuestion>> _loadVirtualPaperQuestions(VirtualPaper paper) {
    return _repository.getFilteredQuestions(
      SearchFilters(
        name: '',
        choiceCount: 0,
        fillCount: 0,
        solutionCount: 0,
        targetDifficulty: 0,
        years: [paper.year.toString()],
        regions: [paper.region],
        conceptTags: const [],
        knowledgeCards: const [],
        examTypes: [paper.examType],
      ),
    );
  }

  Future<void> _handleVirtualPaperAction(
    VirtualPaper paper,
    _VirtualPaperAction action,
  ) async {
    if (_creatingPaper) return;
    setState(() => _creatingPaper = true);
    try {
      final questions = await _loadVirtualPaperQuestions(paper);
      if (!mounted) return;
      if (action == _VirtualPaperAction.addToBasket) {
        setState(() {
          for (final question in questions) {
            _selectedQuestions[question.id] = question;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已将 ${questions.length} 题加入试卷篮')),
        );
      } else {
        setState(() => _creatingPaper = false);
        await _createManualDraft(
          questions,
          initialName: paper.title,
          clearBasketOnSuccess: false,
          downloadAfterCreate: action == _VirtualPaperAction.createAndDownload,
        );
        return;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('套卷加载失败，请稍后重试')));
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
      bottomNavigationBar: _selectedQuestions.isNotEmpty
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
                  controller: _scrollController,
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
                    if (_currentScopeLabel != null)
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _PinnedScopeHeaderDelegate(
                          backgroundColor: context.colors.background,
                          child: _CurrentScopeBar(
                            label: _currentScopeLabel!,
                            resultCount: _questions?.length,
                            loading: _loadingQuestions,
                            onSave: _reviewScope == null && _hasExplicitScope
                                ? _saveCurrentRange
                                : null,
                            onClear: _clearScope,
                          ),
                        ),
                      ),
                    if (options != null)
                      SliverPadding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        sliver: SliverToBoxAdapter(
                          child: _QuestionLibraryModeSelector(
                            value: _mode,
                            onChanged: _changeMode,
                          ),
                        ),
                      ),
                    if (options != null && _mode == _QuestionLibraryMode.papers)
                      SliverPadding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        sliver: SliverToBoxAdapter(
                          child: _VirtualPaperBrowser(
                            papers: _virtualPapers,
                            selected: _selectedVirtualPaper,
                            onSelected: _selectVirtualPaper,
                            onAction: _handleVirtualPaperAction,
                          ),
                        ),
                      ),
                    if (options != null && _mode == _QuestionLibraryMode.topics)
                      SliverPadding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        sliver: SliverToBoxAdapter(
                          child: _TopicBrowser(
                            nodes: options.conceptTagTree,
                            selectedNames: _conceptTags,
                            onChanged: _applyTopicSelection,
                          ),
                        ),
                      ),
                    if (options != null &&
                        _mode == _QuestionLibraryMode.knowledge)
                      SliverPadding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        sliver: SliverToBoxAdapter(
                          child: _KnowledgeBrowser(
                            groups: options.knowledgeCardGroups,
                            selectedTitles: _knowledgeCards,
                            onChanged: _applyKnowledgeSelection,
                          ),
                        ),
                      ),
                    if (options != null && _mode == _QuestionLibraryMode.mine)
                      SliverPadding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              _QuestionReviewBrowser(
                                summary: _reviewSummary,
                                selectedScope: _reviewScope,
                                onSelected: _selectReviewScope,
                              ),
                              if (_savedRanges.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.lg),
                                _SavedRangeBrowser(
                                  ranges: _savedRanges,
                                  selectedId: _selectedRangeId,
                                  onSelected: _applySavedRange,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    if (options != null)
                      SliverPadding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        sliver: SliverToBoxAdapter(
                          child: ExpansionTile(
                            initiallyExpanded: _advancedExpanded,
                            onExpansionChanged: (expanded) =>
                                setState(() => _advancedExpanded = expanded),
                            tilePadding: EdgeInsets.zero,
                            title: const Text('更多筛选'),
                            subtitle: const Text('按来源、题型、难度和计算量进一步限定'),
                            children: [
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
                                showConceptSection: false,
                                showKnowledgeSection: false,
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
                          key: _resultsKey,
                          title: _questions == null
                              ? '题目结果'
                              : '题目结果 · ${_questions!.length} 题',
                          subtitle: _questions?.isNotEmpty == true
                              ? _resultSummary(_questions!)
                              : null,
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
            selected: _selectedQuestions.containsKey(question.id),
            onToggle: () => _toggleQuestion(question),
          );
        },
      ),
    ];
  }

  String _resultSummary(List<SearchQuestion> questions) {
    final choice = questions
        .where((question) => question.questionType == 'choice')
        .length;
    final fill = questions
        .where((question) => question.questionType == 'fill')
        .length;
    final solution = questions
        .where((question) => question.questionType == 'solution')
        .length;
    final averageDifficulty =
        questions.fold<double>(
          0,
          (sum, question) => sum + question.difficulty,
        ) /
        questions.length;
    return '选择题 $choice · 填空题 $fill · 解答题 $solution · 平均难度 ${averageDifficulty.toStringAsFixed(1)}';
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
              bottom: AppSpacing.sm,
            ),
            leading: const Icon(Icons.description_outlined),
            title: Text(entry.key),
            subtitle: Text('${entry.value.length} 套'),
            children: years.map((year) {
              final papers = yearGroups[year]!
                ..sort((a, b) => a.region.compareTo(b.region));
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                                onSelected: () => widget.onSelected(paper),
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
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
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
          PopupMenuButton<_VirtualPaperAction>(
            tooltip: '${paper.year}年${paper.region}${paper.examType}操作',
            padding: EdgeInsets.zero,
            iconSize: 18,
            onSelected: onAction,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _VirtualPaperAction.addToBasket,
                child: Text('加入试卷篮'),
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

class _QuestionLibraryModeSelector extends StatelessWidget {
  const _QuestionLibraryModeSelector({
    required this.value,
    required this.onChanged,
  });

  final _QuestionLibraryMode value;
  final ValueChanged<_QuestionLibraryMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<_QuestionLibraryMode>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: _QuestionLibraryMode.papers, label: Text('套卷')),
          ButtonSegment(value: _QuestionLibraryMode.topics, label: Text('专题')),
          ButtonSegment(
            value: _QuestionLibraryMode.knowledge,
            label: Text('知识卡片'),
          ),
          ButtonSegment(value: _QuestionLibraryMode.mine, label: Text('我的题目')),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _CurrentScopeBar extends StatelessWidget {
  const _CurrentScopeBar({
    required this.label,
    required this.resultCount,
    required this.loading,
    required this.onSave,
    required this.onClear,
  });

  final String label;
  final int? resultCount;
  final bool loading;
  final VoidCallback? onSave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_outlined, size: 18, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (resultCount != null)
            Text('$resultCount题', style: TextStyle(color: colors.primary)),
          if (onSave != null)
            IconButton(
              tooltip: '保存为常用范围',
              visualDensity: VisualDensity.compact,
              onPressed: onSave,
              icon: const Icon(Icons.bookmark_add_outlined),
            ),
          IconButton(
            tooltip: '清除当前范围',
            visualDensity: VisualDensity.compact,
            onPressed: onClear,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _PinnedScopeHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedScopeHeaderDelegate({
    required this.child,
    required this.backgroundColor,
  });

  final Widget child;
  final Color backgroundColor;

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedScopeHeaderDelegate oldDelegate) =>
      oldDelegate.child != child ||
      oldDelegate.backgroundColor != backgroundColor;
}

class _TopicBrowser extends StatefulWidget {
  const _TopicBrowser({
    required this.nodes,
    required this.selectedNames,
    required this.onChanged,
  });

  final List<ConceptTagNode> nodes;
  final Set<String> selectedNames;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<_TopicBrowser> createState() => _TopicBrowserState();
}

class _TopicBrowserState extends State<_TopicBrowser> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ConceptTagNode> _filteredNodes() {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.nodes;

    ConceptTagNode? filterNode(ConceptTagNode node) {
      if (node.name.toLowerCase().contains(query)) return node;
      final children = node.children
          .map(filterNode)
          .whereType<ConceptTagNode>();
      if (children.isEmpty) return null;
      return ConceptTagNode(
        id: node.id,
        name: node.name,
        parentId: node.parentId,
        questionCount: node.questionCount,
        children: children.toList(),
      );
    }

    return widget.nodes.map(filterNode).whereType<ConceptTagNode>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleNodes = _filteredNodes();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: '按专题浏览', subtitle: '先选择大类，需要时再逐级展开。'),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: '搜索专题',
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (widget.nodes.isEmpty)
          EmptyPlaceholder(icon: Icons.account_tree_outlined, message: '暂无专题目录')
        else if (visibleNodes.isEmpty)
          EmptyPlaceholder(icon: Icons.search_off_rounded, message: '没有匹配的专题')
        else
          ConceptTagTreeView(
            nodes: visibleNodes,
            selectedNames: widget.selectedNames,
            onChanged: widget.onChanged,
            compactLeaves: true,
          ),
      ],
    );
  }
}

class _KnowledgeBrowser extends StatelessWidget {
  const _KnowledgeBrowser({
    required this.groups,
    required this.selectedTitles,
    required this.onChanged,
  });

  final List<KnowledgeCardGroup> groups;
  final Set<String> selectedTitles;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: '按知识卡片浏览', subtitle: '选择需要巩固的知识卡片。'),
        const SizedBox(height: AppSpacing.sm),
        if (groups.isEmpty)
          EmptyPlaceholder(icon: Icons.style_outlined, message: '暂无知识卡片')
        else
          KnowledgeCardGroupView(
            groups: groups,
            selectedTitles: selectedTitles,
            onChanged: onChanged,
            compact: true,
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
