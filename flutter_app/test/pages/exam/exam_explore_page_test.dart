import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/exam_repository.dart';
import 'package:flutter_app/pages/exam/exam_explore_page.dart';
import '../../test_setup.dart';

class _MockExploreRepo implements ExamRepository {
  final List<ExploreExamSummary> list;
  _MockExploreRepo({this.list = const []});

  @override
  Future<List<ExploreExamSummary>> getExploreList() async => list;
  @override
  Future<List<ExamSummary>> getMyExams() async => throw UnimplementedError();
  @override
  Future<List<FavoriteExamSummary>> getFavorites() async =>
      throw UnimplementedError();
  @override
  Future<ExamPreview> getPreview(int id) async => throw UnimplementedError();
  @override
  Future<ExamPreviewOther> getPreviewOther(int id) async =>
      throw UnimplementedError();
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
  Future<void> setLike(int id, bool active) async {}
  @override
  Future<void> toggleCollect(int id) async {}
  @override
  Future<void> setCollect(int id, bool active) async {}
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
  group('ExamExplorePage', () {
    testWidgets('shows loading then list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExamExplorePage(
            examRepository: _MockExploreRepo(
              list: [
                ExploreExamSummary(
                  id: 1,
                  name: '海淀一模',
                  authorInfo: '老师A',
                  summary: '',
                  likeCount: 5,
                  collectCount: 3,
                  createdAt: '2025-01-01',
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('海淀一模'), findsOneWidget);
      expect(find.textContaining('5 赞'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('综合热度'), findsOneWidget);
      expect(find.byTooltip('收藏试卷'), findsNothing);
    });

    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ExamExplorePage(examRepository: _MockExploreRepo())),
      );
      await tester.pumpAndSettle();
      expect(find.text('暂时没有公开试卷，可以先创建并分享一份'), findsOneWidget);
    });
  });
}
