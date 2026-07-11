import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/exam_repository.dart';
import 'package:flutter_app/pages/exam/answer_sheet_page.dart';

class _MockAnswerRepo implements ExamRepository {
  final List<AnswerItem> answers;
  _MockAnswerRepo({this.answers = const []});

  @override Future<List<AnswerItem>> getQuickAnswers(int id) async => answers;
  @override Future<List<ExamSummary>> getMyExams() async => throw UnimplementedError();
  @override Future<List<ExploreExamSummary>> getExploreList() async => throw UnimplementedError();
  @override Future<List<FavoriteExamSummary>> getFavorites() async => throw UnimplementedError();
  @override Future<ExamPreview> getPreview(int id) async => throw UnimplementedError();
  @override Future<ExamPreviewOther> getPreviewOther(int id) async => throw UnimplementedError();
  @override Future<FilterOptions> getFilterOptions() async => throw UnimplementedError();
  @override Future<ExamBuildState> getBuildSession() async => throw UnimplementedError();
  @override Future<List<SearchQuestion>> getFilteredQuestions(SearchFilters f) async => throw UnimplementedError();
  @override Future<PoolStats> getPoolStats(SearchFilters f) async => throw UnimplementedError();
  @override Future<int> getTotalCount(SearchFilters f) async => throw UnimplementedError();
  @override Future<int> confirm(SearchFilters f, {bool allowShortfall = false}) async => throw UnimplementedError();
  @override Future<void> toggleLike(int id) async {}
  @override Future<void> toggleCollect(int id) async {}
  @override Future<void> togglePublic(int id) async {}
  @override Future<void> deleteExam(int id) async {}
  @override Future<void> removeFavorite(int id) async {}
  @override Future<void> downloadPdf(int id) async {}
  @override Future<List<FilterPreset>> getFilterPresets() async => [];
  @override Future<void> saveFilterPreset(String name) async {}
  @override Future<SearchFilters> loadFilterPreset(int id) async => throw UnimplementedError();
}

void main() {
  group('AnswerSheetPage', () {
    testWidgets('shows loading then answers', (tester) async {
      await tester.pumpWidget(MaterialApp(home: AnswerSheetPage(examId: 1, examRepository: _MockAnswerRepo(answers: [
        const AnswerItem(title: '#1', questionType: 'choice', answer: 'x^2'),
      ]))));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.textContaining('x^2'), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(MaterialApp(home: AnswerSheetPage(examId: 1, examRepository: _MockAnswerRepo())));
      await tester.pumpAndSettle();
      expect(find.text('暂无答案'), findsOneWidget);
    });
  });
}
