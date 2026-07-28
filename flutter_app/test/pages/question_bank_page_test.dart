import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/exam_repository.dart';
import 'package:flutter_app/pages/question_bank/question_bank_page.dart';
import 'package:shared/shared.dart';

import '../test_setup.dart';

class _QuestionLibraryRepository implements QuestionLibraryRepository {
  SearchFilters? lastFilters;

  @override
  Future<FilterOptions> getFilterOptions() async => const FilterOptions(
    years: ['2025'],
    regions: ['全国'],
    conceptTags: [],
    examTypes: ['高考'],
  );

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
        home: StudentQuestionBankPage(examRepository: repository),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.byType(FilterPanel), findsOneWidget);
    expect(find.text('函数测试题'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '函数');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(repository.lastFilters?.keyword, '函数');
    expect(repository.lastFilters?.years, contains('2025'));
    expect(repository.lastFilters?.examTypes, contains('高考'));
  });
}
