import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/exam_repository.dart';
import 'package:flutter_app/pages/exam/exam_favorites_page.dart';
import '../../test_setup.dart';

class _MockFavRepo implements ExamRepository {
  final List<FavoriteExamSummary> list;
  _MockFavRepo({this.list = const []});

  @override Future<List<FavoriteExamSummary>> getFavorites() async => list;
  @override Future<List<ExamSummary>> getMyExams() async => throw UnimplementedError();
  @override Future<List<ExploreExamSummary>> getExploreList() async => throw UnimplementedError();
  @override Future<ExamPreview> getPreview(int id) async => throw UnimplementedError();
  @override Future<ExamPreviewOther> getPreviewOther(int id) async => throw UnimplementedError();
  @override Future<List<AnswerItem>> getQuickAnswers(int id) async => throw UnimplementedError();
  @override Future<FilterOptions> getFilterOptions() async => throw UnimplementedError();
  @override Future<List<SearchQuestion>> getFilteredQuestions(SearchFilters f) async => throw UnimplementedError();
  @override Future<PoolStats> getPoolStats(SearchFilters f) async => throw UnimplementedError();
  @override Future<int> getTotalCount(SearchFilters f) async => throw UnimplementedError();
  @override Future<int> confirm(SearchFilters f, {bool allowShortfall = false}) async => throw UnimplementedError();
  @override Future<void> toggleLike(int id) async {}
  @override Future<void> toggleCollect(int id) async {}
  @override Future<void> togglePublic(int id) async {}
  @override Future<void> deleteExam(int id) async {}
  @override Future<void> removeFavorite(int id) async {}
  @override Future<void> downloadPdf(int id, {BuildContext? context}) async {}
  @override Future<List<FilterPreset>> getFilterPresets() async => [];
}

void main() {
    setUp(() => setupTestHooks());
  group('ExamFavoritesPage', () {
    testWidgets('shows loading then list', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ExamFavoritesPage(examRepository: _MockFavRepo(list: [
        const FavoriteExamSummary(id: 1, name: '海淀一模', authorInfo: '老师A', summary: '2025'),
      ]))));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('海淀一模'), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ExamFavoritesPage(examRepository: _MockFavRepo())));
      await tester.pumpAndSettle();
      expect(find.text('你还没有收藏任何试卷，发现好试卷可以收藏哦'), findsOneWidget);
    });
  });
}
