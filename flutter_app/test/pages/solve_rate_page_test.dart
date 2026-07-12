import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/solve/solve_rate_page.dart';
import 'package:flutter_app/domain/rating_repository.dart';
import '../test_setup.dart';

class _MockRatingRepo implements RatingRepository {
  @override Future<Rating> getRating(int questionId) async =>
      const Rating(algorithmDifficulty: 0, algorithmCalculation: 0);
  @override Future<void> submitRating({required int questionId, required double difficulty, required double calculation, required double elegance}) async {}
}

void main() {
    setUp(() => setupTestHooks());
  group('SolveRatePage', () {
    testWidgets('renders 3 star ratings', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SolveRatePage(questionId: 1, ratingRepository: _MockRatingRepo()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('难度'), findsOneWidget);
      expect(find.text('计算量'), findsOneWidget);
      expect(find.text('优雅度'), findsOneWidget);
    });
    testWidgets('can submit rating', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SolveRatePage(questionId: 1, ratingRepository: _MockRatingRepo()),
      ));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.textContaining('提交评分'));
      await tester.pump();
      await tester.tap(find.textContaining('提交评分'));
      await tester.pump();
      expect(find.text('已评分'), findsOneWidget);
      expect(find.text('修改评分'), findsOneWidget);
    });
  });
}
