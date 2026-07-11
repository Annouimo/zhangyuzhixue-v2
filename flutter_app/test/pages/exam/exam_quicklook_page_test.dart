import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/exam_repository.dart';
import 'package:flutter_app/pages/exam/exam_quicklook_page.dart';

class _MockQuicklookRepo implements ExamRepository {
  final ExamPreview? preview;
  _MockQuicklookRepo({this.preview});

  @override Future<ExamPreview> getPreview(int id) async =>
    preview ?? ExamPreview(name: '测试卷', authorInfo: '',
      choiceCount: 5, fillCount: 3, solutionCount: 2, totalCount: 10, questions: []);
  @override Future<List<ExamSummary>> getMyExams() async => throw UnimplementedError();
  @override Future<List<ExploreExamSummary>> getExploreList() async => throw UnimplementedError();
  @override Future<List<FavoriteExamSummary>> getFavorites() async => throw UnimplementedError();
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
  @override Future<void> downloadPdf(int id) async {}
  @override Future<List<FilterPreset>> getFilterPresets() async => [];
}

void main() {
  group('ExamQuicklookPage', () {
    testWidgets('shows loading then preview', (tester) async {
      final repo = _MockQuicklookRepo(preview: ExamPreview(
        name: '测试卷', authorInfo: '', choiceCount: 5, fillCount: 3,
        solutionCount: 2, totalCount: 10, questions: [],
      ));
      await tester.pumpWidget(
        MaterialApp(home: ExamQuicklookPage(examId: 1, examRepository: repo)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('测试卷'), findsAtLeast(1));
      expect(find.textContaining('共 10 题'), findsOneWidget);
    });
  });
}
