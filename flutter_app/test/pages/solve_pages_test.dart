import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/solve/solve_choice_page.dart';
import 'package:flutter_app/pages/solve/solve_fill_page.dart';
import 'package:flutter_app/pages/solve/solve_rate_page.dart';
import 'package:flutter_app/domain/question_repository.dart';
import 'package:flutter_app/domain/rating_repository.dart';

/// mock QuestionRepository
class _MockQRepo implements QuestionRepository {
  @override
  Future<QuestionDetail> getDetail(int id) async {
    return QuestionDetail(
      id: id,
      stem: '测试题目 $id 的题干',
      difficulty: 5.0,
      conceptTags: ['函数'],
      questionType: 'choice',
      options: {'A': '选项A', 'B': '选项B', 'C': '选项C', 'D': '选项D'},
      answer: 'B',
    );
  }

  @override
  Future<SolveAttempt> startSolve(int questionId) async =>
      SolveAttempt(id: 1, questionId: questionId, attemptNumber: 1, createdAt: DateTime.now(), isCompleted: false, isStarted: true);

  @override
  Future<List<SolveAttempt>> getAttempts(int questionId) async => [];

  @override
  Future<int?> nextQuestion(int currentId) async => currentId < 3 ? currentId + 1 : null;
}

class _MockRatingRepo implements RatingRepository {
  @override
  Future<Rating> getRating(int questionId) async =>
      const Rating(algorithmDifficulty: 0, algorithmCalculation: 0);

  @override
  Future<void> submitRating({
    required int questionId,
    required double difficulty,
    required double calculation,
    required double elegance,
  }) async {}
}

void main() {
  group('SolveChoicePage', () {
    testWidgets('renders choice page with real data', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SolveChoicePage(
          questionId: 1,
          questionRepository: _MockQRepo(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('测试题目 1 的题干'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
      expect(find.text('选项A'), findsOneWidget);
    });

    testWidgets('can select an option', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SolveChoicePage(
          questionId: 1,
          questionRepository: _MockQRepo(),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pump();
      // A 选项背景变为 primaryLight（选中态）
    });
  });

  group('SolveFillPage', () {
    testWidgets('renders fill page with real stem', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SolveFillPage(
          questionId: 1,
          questionRepository: _MockQRepo(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('测试题目 1 的题干'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('SolveRatePage', () {
    testWidgets('renders 3 star ratings', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SolveRatePage(
          questionId: 1,
          ratingRepository: _MockRatingRepo(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('难度'), findsOneWidget);
      expect(find.text('计算量'), findsOneWidget);
      expect(find.text('优雅度'), findsOneWidget);
    });

    testWidgets('can submit rating', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SolveRatePage(
          questionId: 1,
          ratingRepository: _MockRatingRepo(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('提交评分'));
      await tester.pump();
      expect(find.text('已评分'), findsOneWidget);
      expect(find.text('修改评分'), findsOneWidget);
    });
  });
}
