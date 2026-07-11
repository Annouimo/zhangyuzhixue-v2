import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/exam_repository.dart';
import 'package:flutter_app/pages/exam/exam_auto_page.dart';

class _MockAutoRepo implements ExamRepository {
  @override Future<FilterOptions> getFilterOptions() async => const FilterOptions(
    years: ['2025'], regions: ['海淀'], conceptTags: ['函数'], knowledgeCards: []);
  @override Future<PoolStats> getPoolStats(SearchFilters f) async => const PoolStats(
    availableChoice: 10, availableFill: 5, availableSolution: 3,
    poolDiffMin: 2, poolDiffMax: 8, gaokaoDiffMin: 3, gaokaoDiffAvg: 5, gaokaoDiffMax: 7);
  @override Future<int> confirm(SearchFilters f, {bool allowShortfall = false}) async => 1;
  @override Future<List<ExamSummary>> getMyExams() async => throw UnimplementedError();
  @override Future<List<ExploreExamSummary>> getExploreList() async => throw UnimplementedError();
  @override Future<List<FavoriteExamSummary>> getFavorites() async => throw UnimplementedError();
  @override Future<ExamPreview> getPreview(int id) async => throw UnimplementedError();
  @override Future<ExamPreviewOther> getPreviewOther(int id) async => throw UnimplementedError();
  @override Future<List<AnswerItem>> getQuickAnswers(int id) async => throw UnimplementedError();
  @override Future<List<SearchQuestion>> getFilteredQuestions(SearchFilters f) async => throw UnimplementedError();
  @override Future<int> getTotalCount(SearchFilters f) async => throw UnimplementedError();
  @override Future<void> toggleLike(int id) async {}
  @override Future<void> toggleCollect(int id) async {}
  @override Future<void> togglePublic(int id) async {}
  @override Future<void> deleteExam(int id) async {}
  @override Future<void> removeFavorite(int id) async {}
  @override Future<void> downloadPdf(int id) async {}
  @override Future<List<FilterPreset>> getFilterPresets() async => [];
}

void main() {
  group('ExamAutoPage', () {
    testWidgets('loads filter options and renders', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ExamAutoPage(examRepository: _MockAutoRepo())));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      // AppBar visible + confirm button
      expect(find.text('智能组卷'), findsOneWidget);
      expect(find.text('确认组卷'), findsOneWidget);
    });
  });
}
