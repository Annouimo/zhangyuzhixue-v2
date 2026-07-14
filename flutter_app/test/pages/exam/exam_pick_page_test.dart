import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/exam_repository.dart';
import 'package:flutter_app/pages/exam/exam_pick_page.dart';
import '../../test_setup.dart';

class _MockPickRepo implements ExamRepository {
  @override Future<FilterOptions> getFilterOptions() async => const FilterOptions(
    years: ['2025', '2024'], regions: ['海淀', '西城'], conceptTags: ['函数'], knowledgeCards: []);
  @override Future<List<SearchQuestion>> getFilteredQuestions(SearchFilters f) async => [
    const SearchQuestion(id: 1, title: '测试题', questionType: 'choice', meta: '2025·海淀·选择题·3分', difficulty: 5.0, calculation: 3.0),
  ];
  @override Future<int> confirm(SearchFilters f, {bool allowShortfall = false}) async => 1;
  @override Future<List<ExamSummary>> getMyExams() async => throw UnimplementedError();
  @override Future<List<ExploreExamSummary>> getExploreList() async => throw UnimplementedError();
  @override Future<List<FavoriteExamSummary>> getFavorites() async => throw UnimplementedError();
  @override Future<ExamPreview> getPreview(int id) async => throw UnimplementedError();
  @override Future<ExamPreviewOther> getPreviewOther(int id) async => throw UnimplementedError();
  @override Future<List<AnswerItem>> getQuickAnswers(int id) async => throw UnimplementedError();
  @override Future<PoolStats> getPoolStats(SearchFilters f) async => throw UnimplementedError();
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
  setUp(() => setupTestHooks());
  group('ExamPickPage', () {
    testWidgets('loads empty state (desktop size)', (tester) async {
      await tester.pumpWidget(
        MediaQuery(data: const MediaQueryData(size: Size(1266, 627)),
          child: MaterialApp(home: ExamPickPage(examRepository: _MockPickRepo()))),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      // Bottom bar with button should be visible
      expect(find.textContaining('已选 0 题'), findsOneWidget);
      expect(find.text('确认组卷 (0)'), findsOneWidget);
      // Filter panel loaded
      expect(find.text('年份'), findsOneWidget);
    });
  });
}
