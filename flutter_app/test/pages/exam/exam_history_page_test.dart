import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/exam_repository.dart';
import 'package:flutter_app/pages/exam/exam_history_page.dart';
import '../../test_setup.dart';

class _MockExamRepo implements ExamRepository {
  final List<ExamSummary> exams;
  _MockExamRepo({this.exams = const []});

  @override
  Future<List<ExamSummary>> getMyExams() async => exams;
  @override
  Future<List<ExploreExamSummary>> getExploreList() async =>
      throw UnimplementedError();
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
  group('ExamHistoryPage', () {
    testWidgets('shows loading then list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExamHistoryPage(
            examRepository: _MockExamRepo(
              exams: [
                const ExamSummary(
                  id: 1,
                  name: '函数练习',
                  createdAt: '2025-01-01',
                  summary: 'summary',
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('函数练习'), findsOneWidget);
      expect(find.text('打印试卷'), findsNothing);
      expect(find.text('快速对答案'), findsNothing);
      expect(find.text('删除'), findsNothing);
      await tester.tap(find.byTooltip('选择试卷'));
      await tester.pump();
      expect(find.textContaining('已选 1'), findsOneWidget);
      expect(find.text('管理试卷'), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ExamHistoryPage(examRepository: _MockExamRepo())),
      );
      await tester.pumpAndSettle();
      expect(find.text('还没有创建过试卷，前往题库与组卷创建吧'), findsOneWidget);
    });
  });
}
