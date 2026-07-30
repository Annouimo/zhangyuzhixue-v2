import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/exam_repository.dart';
import 'package:flutter_app/pages/exam/exam_quicklook_other_page.dart';
import '../../test_setup.dart';

class _MockOtherRepo implements ExamRepository {
  @override
  Future<ExamPreviewOther> getPreviewOther(int id) async => ExamPreviewOther(
    name: '试卷',
    authorInfo: '',
    choiceCount: 3,
    fillCount: 2,
    solutionCount: 1,
    totalCount: 6,
    likeCount: 10,
    collectCount: 5,
    questions: const [
      ExamQuestion(
        questionId: 2,
        title: '公开试卷中的题干',
        questionType: 'choice',
        source: '2024 北京 模拟',
        difficulty: 3,
      ),
    ],
  );
  @override
  Future<List<ExamSummary>> getMyExams() async => throw UnimplementedError();
  @override
  Future<List<ExploreExamSummary>> getExploreList() async =>
      throw UnimplementedError();
  @override
  Future<List<FavoriteExamSummary>> getFavorites() async =>
      throw UnimplementedError();
  @override
  Future<ExamPreview> getPreview(int id) async => throw UnimplementedError();
  @override
  Future<List<AnswerItem>> getQuickAnswers(int id) async =>
      throw UnimplementedError();
  @override
  Future<FilterOptions> getFilterOptions() async => throw UnimplementedError();
  @override
  Future<List<SearchQuestion>> getFilteredQuestions(SearchFilters f) async =>
      throw UnimplementedError();
  @override
  Future<PoolStats> getPoolStats(SearchFilters f) async =>
      throw UnimplementedError();
  @override
  Future<int> getTotalCount(SearchFilters f) async =>
      throw UnimplementedError();
  @override
  Future<int> confirm(SearchFilters f, {bool allowShortfall = false}) async =>
      throw UnimplementedError();
  @override
  Future<void> toggleLike(int id) async {}
  @override
  Future<void> toggleCollect(int id) async {}
  @override
  Future<void> togglePublic(int id) async {}
  @override
  Future<void> deleteExam(int id) async {}
  @override
  Future<void> removeFavorite(int id) async {}
  @override
  Future<void> downloadPdf(int id, {BuildContext? context}) async {}
  @override
  Future<List<FilterPreset>> getFilterPresets() async => [];
}

void main() {
  setUp(() => setupTestHooks());
  group('ExamQuicklookOtherPage', () {
    testWidgets('shows loading then preview with like/collect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExamQuicklookOtherPage(
            examId: 1,
            examRepository: _MockOtherRepo(),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('试卷'), findsAtLeast(1));
      expect(find.text('快速对答案'), findsOneWidget);
      expect(find.text('打印试卷'), findsNothing);
      expect(find.text('10 点赞'), findsNothing);
      expect(find.text('5 收藏'), findsOneWidget);
      expect(find.text('公开试卷中的题干'), findsOneWidget);
      expect(find.text('1. 2024 北京 模拟'), findsOneWidget);
      await tester.tap(find.byTooltip('更多试卷操作'));
      await tester.pumpAndSettle();
      expect(find.text('打印试卷'), findsOneWidget);
      expect(find.text('10 点赞'), findsOneWidget);
    });
  });
}
