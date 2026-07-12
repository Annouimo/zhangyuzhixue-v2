import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/solve/solve_fill_page.dart';
import 'package:flutter_app/domain/question_repository.dart';
import '../test_setup.dart';

class _MockQRepo implements QuestionRepository {
  @override
  Future<QuestionDetail> getDetail(int id) async {
    return QuestionDetail(
      id: id,
      stem: '测试题目 $id 的题干',
      difficulty: 5.0,
      conceptTags: ['函数'],
      questionType: 'fill',
      options: {},
      answer: '42',
    );
  }
  @override Future<SolveAttempt> startSolve(int questionId) async =>
      SolveAttempt(id: 1, questionId: questionId, attemptNumber: 1, createdAt: DateTime.now(), isCompleted: false, isStarted: true);
  @override Future<List<SolveAttempt>> getAttempts(int questionId) async => [];
  @override Future<int?> nextQuestion(int currentId) async => currentId < 3 ? currentId + 1 : null;
}

void main() {
    setUp(() => setupTestHooks());
  group('SolveFillPage', () {
    testWidgets('renders fill page with real stem', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SolveFillPage(questionId: 1, questionRepository: _MockQRepo()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('测试题目 1 的题干'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
