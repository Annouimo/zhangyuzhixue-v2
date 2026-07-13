import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/solve/solve_choice_page.dart';
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
      questionType: 'choice',
      options: {'A': '选项A', 'B': '选项B', 'C': '选项C', 'D': '选项D'},
      answer: 'B',
    );
  }
  @override Future<SolveAttempt> startSolve(int questionId) async =>
      SolveAttempt(id: 1, questionId: questionId, attemptNumber: 1, createdAt: DateTime.now(), isCompleted: false, isStarted: true);
  @override Future<List<SolveAttempt>> getAttempts(int questionId) async => [];
  @override Future<int?> nextQuestion(int currentId) async => currentId < 3 ? currentId + 1 : null;
  @override Future<void> saveAttempt(int questionId, {String? answerText, bool isCorrect = false}) async {}
}

void main() {
    setUp(() => setupTestHooks());
  group('SolveChoicePage', () {
    testWidgets('renders choice page with real data', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SolveChoicePage(questionId: 1, questionRepository: _MockQRepo()),
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
        home: SolveChoicePage(questionId: 1, questionRepository: _MockQRepo()),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A'));
      await tester.pump();
    });
  });
}
