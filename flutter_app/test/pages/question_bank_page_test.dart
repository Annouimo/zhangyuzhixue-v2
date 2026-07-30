import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/exam_repository.dart';
import 'package:flutter_app/domain/question_review_repository.dart';
import 'package:flutter_app/domain/preference_repository.dart';
import 'package:flutter_app/pages/question_bank/question_bank_page.dart';
import 'package:shared/shared.dart';

import '../test_setup.dart';

class _QuestionLibraryRepository
    implements
        QuestionLibraryRepository,
        VirtualPaperRepository,
        QuestionReviewRepository,
        PreferenceRepository {
  SearchFilters? lastFilters;
  QuestionReviewScope? lastReviewScope;
  int? lastPreferenceId;

  @override
  Future<FilterOptions> getFilterOptions() async => const FilterOptions(
    years: ['2025'],
    regions: ['全国'],
    conceptTags: [],
    examTypes: ['高考'],
  );

  @override
  Future<List<VirtualPaper>> getVirtualPapers() async => const [
    VirtualPaper(year: 2025, examType: '一模', region: '海淀', questionCount: 21),
  ];

  @override
  Future<QuestionReviewSummary> getSummary() async =>
      const QuestionReviewSummary(currentWrongCount: 1, correctedCount: 2);

  @override
  Future<List<SearchQuestion>> getQuestions(QuestionReviewScope scope) async {
    lastReviewScope = scope;
    return getFilteredQuestions(
      const SearchFilters(
        name: '',
        choiceCount: 0,
        fillCount: 0,
        solutionCount: 0,
        targetDifficulty: 0,
        years: [],
        regions: [],
        conceptTags: [],
        knowledgeCards: [],
      ),
    );
  }

  @override
  Future<List<PreferenceSummary>> getList() async => const [
    PreferenceSummary(id: 7, name: '高考常用', summary: '2025 全国'),
  ];

  @override
  Future<PreferenceEditData> getEdit(int id) async {
    lastPreferenceId = id;
    return const PreferenceEditData(
      name: '高考常用',
      filter: PreferenceFilter(
        years: ['2025'],
        regions: ['全国'],
        conceptTags: [],
        types: ['高考'],
      ),
    );
  }

  @override
  Future<int> getCount() async => 1;

  @override
  Future<int> save({
    required String name,
    required PreferenceFilter filter,
    int? existingId,
  }) async => existingId ?? 7;

  @override
  Future<void> delete(int id) async {}

  @override
  Future<List<SearchQuestion>> getFilteredQuestions(
    SearchFilters filters,
  ) async {
    lastFilters = filters;
    return const [
      SearchQuestion(
        id: 1,
        title: '函数测试题',
        questionType: 'choice',
        meta: '2025 高考 全国',
        difficulty: 4,
        calculation: 3,
      ),
    ];
  }
}

class _LargeQuestionLibraryRepository extends _QuestionLibraryRepository {
  @override
  Future<List<VirtualPaper>> getVirtualPapers() async {
    const regions = ['东城', '朝阳', '海淀', '西城'];
    return [
      for (final year in [2026, 2025, 2024, 2023])
        for (final region in regions)
          VirtualPaper(
            year: year,
            examType: '一模',
            region: region,
            questionCount: 21,
          ),
    ];
  }

  @override
  Future<List<SearchQuestion>> getFilteredQuestions(
    SearchFilters filters,
  ) async {
    lastFilters = filters;
    return List.generate(21, (index) {
      final type = index < 10
          ? 'choice'
          : index < 15
          ? 'fill'
          : 'solution';
      return SearchQuestion(
        id: index + 1,
        title:
            r'已知函数 $f(x)=x^2+1$，求对应结论。'
            '${index + 1}',
        questionType: type,
        meta: '2026 一模 东城',
        difficulty: 3.4,
        calculation: 3,
      );
    });
  }
}

void main() {
  setUp(setupTestHooks);

  Future<_QuestionLibraryRepository> pumpQuestionBank(
    WidgetTester tester, {
    _QuestionLibraryRepository? repository,
    ScrollController? scrollController,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final result = repository ?? _QuestionLibraryRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StudentQuestionBankPage(
          examRepository: result,
          virtualPaperRepository: result,
          questionReviewRepository: result,
          preferenceRepository: result,
          scrollController: scrollController,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('search and filters share one result flow', (tester) async {
    final repository = await pumpQuestionBank(tester);

    expect(find.text('搜索题目'), findsWidgets);
    expect(find.text('我的筛选方案'), findsNothing);
    expect(find.text('筛选条件'), findsOneWidget);
    expect(find.text('题目结果'), findsOneWidget);
    expect(find.text('选题'), findsNothing);
    expect(find.text('全部加入试题篮'), findsNothing);
    expect(find.text('智能选题'), findsNothing);
    expect(repository.lastFilters, isNull);

    await tester.enterText(find.byType(TextField).first, '函数');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(repository.lastFilters?.keyword, '函数');
    expect(repository.lastFilters?.years, isEmpty);
    expect(repository.lastFilters?.examTypes, isEmpty);
    expect(find.text('函数测试题'), findsOneWidget);
    expect(find.text('1 道'), findsOneWidget);
    expect(find.text('选择题 1'), findsOneWidget);
    expect(find.text('填空题 0'), findsOneWidget);
    expect(find.text('解答题 0'), findsOneWidget);
    expect(find.text('平均难度 4.0'), findsOneWidget);
  });

  testWidgets('checking a question exposes add-to-basket actions', (
    tester,
  ) async {
    await pumpQuestionBank(tester);
    await tester.enterText(find.byType(TextField).first, '函数');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(find.text('完成选题'), findsNothing);
    expect(find.text('全选当前结果'), findsOneWidget);
    expect(find.text('清空'), findsOneWidget);
    expect(find.text('智能选题'), findsOneWidget);
    expect(find.byTooltip('选择题目'), findsOneWidget);

    await tester.tap(find.byTooltip('选择题目'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('取消选择'), findsOneWidget);
    expect(find.text('智能补全'), findsOneWidget);
    expect(find.text('已选 1 道题'), findsOneWidget);
    expect(find.text('加入试题篮'), findsOneWidget);
    await tester.ensureVisible(find.text('函数测试题'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('取消选择'), findsOneWidget);
  });

  testWidgets('question list keeps scroll stable and can return to top', (
    tester,
  ) async {
    final repository = _LargeQuestionLibraryRepository();
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    await pumpQuestionBank(
      tester,
      repository: repository,
      scrollController: scrollController,
    );

    await tester.enterText(find.byType(TextField).first, '函数');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('21 道'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(scrollController.offset, greaterThan(0));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 2400));
    await tester.pumpAndSettle();
    expect(scrollController.offset, 0);
    expect(find.text('搜索题目'), findsWidgets);
    expect(find.text('筛选条件'), findsOneWidget);
  });
}
