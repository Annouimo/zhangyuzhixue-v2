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

void main() {
  setUp(setupTestHooks);

  testWidgets('question bank reuses full filters and keyword search', (
    tester,
  ) async {
    final repository = _QuestionLibraryRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StudentQuestionBankPage(
          examRepository: repository,
          virtualPaperRepository: repository,
          questionReviewRepository: repository,
          preferenceRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.text('套卷'), findsOneWidget);
    expect(find.text('专题'), findsOneWidget);
    expect(find.text('知识卡片'), findsOneWidget);
    expect(find.text('我的题目'), findsOneWidget);
    expect(find.text('函数测试题'), findsNothing);
    expect(repository.lastFilters, isNull);

    await tester.tap(find.text('我的题目'));
    await tester.pumpAndSettle();
    expect(find.text('当前错题'), findsOneWidget);
    expect(find.text('已订正'), findsOneWidget);
    expect(find.text('高考常用'), findsOneWidget);

    await tester.tap(find.text('高考常用'));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(repository.lastPreferenceId, 7);
    expect(repository.lastFilters?.examTypes, contains('高考'));

    await tester.ensureVisible(find.text('当前错题'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('当前错题'));
    await tester.pumpAndSettle();
    expect(repository.lastReviewScope, QuestionReviewScope.currentWrong);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1800));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('套卷'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('一模'));
    await tester.pumpAndSettle();
    expect(find.text('2025'), findsOneWidget);
    await tester.ensureVisible(find.text('海淀'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('海淀'));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(repository.lastFilters?.years, contains('2025'));
    expect(repository.lastFilters?.examTypes, contains('一模'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1800));
    await tester.pumpAndSettle();
    expect(find.text('2025年 · 海淀 · 一模'), findsOneWidget);
    expect(find.byTooltip('保存为常用范围'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '函数');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(repository.lastFilters?.keyword, '函数');
    expect(repository.lastFilters?.years, contains('2025'));
    expect(repository.lastFilters?.examTypes, contains('一模'));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.text('题目结果 · 1 题'), findsOneWidget);
    await tester.tap(find.text('手动选题'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('函数测试题'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('加入试卷'));
    await tester.pumpAndSettle();

    expect(find.text('已选 1 题'), findsOneWidget);
    expect(find.text('生成试卷'), findsOneWidget);
  });
}
