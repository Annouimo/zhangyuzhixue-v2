import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/exam_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/exam_repository.dart';
import '../../widgets/question_search_field.dart';
import '../../widgets/question_search_results.dart';
import 'question_detail_page.dart';

class StudentQuestionBankPage extends StatefulWidget {
  const StudentQuestionBankPage({super.key, this.examRepository});

  final QuestionLibraryRepository? examRepository;

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
  final _filterKey = GlobalKey<FilterPanelState>();
  final _queryController = TextEditingController();
  FilterOptions? _filterOptions;
  List<SearchQuestion>? _questions;
  Timer? _debounce;
  bool _loadingQuestions = false;
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
      final options = await _repository.getFilterOptions();
      if (!mounted) return;
      setState(() => _filterOptions = options);
    } catch (error) {
      if (mounted) setState(() => _error = '题库筛选条件加载失败，请稍后重试');
    }
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _search);
  }

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

  @override
  Widget build(BuildContext context) {
    final options = _filterOptions;
    return Scaffold(
      appBar: AppBar(title: const Text('题库')),
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
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        sliver: SliverToBoxAdapter(
                          child: FilterPanel(
                            key: _filterKey,
                            horizontalMargin: 0,
                            yearOptions: options.years,
                            regionOptions: options.regions,
                            typeOptions: options.questionTypes,
                            conceptTagOptions: options.conceptTags,
                            conceptTagTree: options.conceptTagTree,
                            examTypeOptions: options.examTypes,
                            knowledgeCardOptions: options.knowledgeCards,
                            knowledgeCardGroups: options.knowledgeCardGroups,
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
        itemBuilder: (context, index) => QuestionSearchResultCard(
          question: questions[index],
          onOpen: () => _openQuestion(questions[index]),
        ),
      ),
    ];
  }
}
