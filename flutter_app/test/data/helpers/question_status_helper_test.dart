import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/helpers/question_status_helper.dart';
import 'package:flutter_app/data/database/app_database.dart' as db;

/// 构建一个 submission_detail 行用于测试
db.SubmissionDetailRow makeDetail({
  int id = 1,
  int questionId = 1,
  int attemptNumber = 1,
  String status = 'in_progress',
  int? isCorrect,
}) {
  return db.SubmissionDetailRow(
    id: id,
    questionId: questionId,
    attemptNumber: attemptNumber,
    status: status,
    isCorrect: isCorrect,
    createdAt: '2026-07-10T10:00:00',
    updatedAt: '2026-07-10T10:00:00',
  );
}

void main() {
  group('QuestionStatusHelper.calculateGlobal', () {
    test('empty list returns undone', () {
      final result = QuestionStatusHelper.calculateGlobal([]);
      expect(result.status, QuestionStatus.undone);
      expect(result.shouldPrompt, false);
    });

    test('has completed detail returns done', () {
      final details = [
        makeDetail(attemptNumber: 1, isCorrect: 1),
      ];
      final result = QuestionStatusHelper.calculateGlobal(details);
      expect(result.status, QuestionStatus.done);
    });

    test('has completed status returns done', () {
      final details = [
        makeDetail(attemptNumber: 1, status: 'completed'),
      ];
      final result = QuestionStatusHelper.calculateGlobal(details);
      expect(result.status, QuestionStatus.done);
    });

    test('only inProgress returns inProgress', () {
      final details = [
        makeDetail(attemptNumber: 1, status: 'in_progress'),
      ];
      final result = QuestionStatusHelper.calculateGlobal(details);
      expect(result.status, QuestionStatus.inProgress);
    });

    test('any attempt done means done overall', () {
      final details = [
        makeDetail(id: 1, attemptNumber: 1, status: 'in_progress'),
        makeDetail(id: 2, attemptNumber: 2, isCorrect: 1),
      ];
      final result = QuestionStatusHelper.calculateGlobal(details);
      expect(result.status, QuestionStatus.done);
    });
  });

  group('QuestionStatusHelper.calculate', () {
    test('no match for attemptNumber returns undone', () {
      final details = [
        makeDetail(attemptNumber: 1, isCorrect: 1),
      ];
      final result = QuestionStatusHelper.calculate(
        submissionDetails: details,
        questionType: 'choice',
        attemptNumber: 2,
      );
      expect(result.status, QuestionStatus.undone);
    });

    test('no attemptNumber uses latest', () {
      final details = [
        makeDetail(id: 1, attemptNumber: 1, status: 'in_progress'),
        makeDetail(id: 2, attemptNumber: 2, isCorrect: 1),
      ];
      final result = QuestionStatusHelper.calculate(
        submissionDetails: details,
        questionType: 'choice',
      );
      expect(result.status, QuestionStatus.done);
      expect(result.attemptNumber, 2);
    });

    test('completed detail returns done', () {
      final details = [
        makeDetail(attemptNumber: 1, isCorrect: 1),
      ];
      final result = QuestionStatusHelper.calculate(
        submissionDetails: details,
        questionType: 'choice',
        attemptNumber: 1,
      );
      expect(result.status, QuestionStatus.done);
      expect(result.attemptNumber, 1);
    });

    test('inProgress with solution type prompts', () {
      final details = [
        makeDetail(attemptNumber: 1, status: 'in_progress'),
      ];
      final result = QuestionStatusHelper.calculate(
        submissionDetails: details,
        questionType: 'solution',
        attemptNumber: 1,
      );
      expect(result.status, QuestionStatus.inProgress);
      expect(result.shouldPrompt, true);
    });

    test('inProgress with choice type does not prompt', () {
      final details = [
        makeDetail(attemptNumber: 1, status: 'in_progress'),
      ];
      final result = QuestionStatusHelper.calculate(
        submissionDetails: details,
        questionType: 'choice',
        attemptNumber: 1,
      );
      expect(result.status, QuestionStatus.inProgress);
      expect(result.shouldPrompt, false);
    });

    test('completed status returns done', () {
      final details = [
        makeDetail(attemptNumber: 1, status: 'completed'),
      ];
      final result = QuestionStatusHelper.calculate(
        submissionDetails: details,
        questionType: 'choice',
        attemptNumber: 1,
      );
      expect(result.status, QuestionStatus.done);
    });
  });

  group('QuestionStatusHelper.calculateBatch', () {
    test('batch returns correct map', () {
      final map = {
        1: [makeDetail(questionId: 1, attemptNumber: 1, isCorrect: 1)],
        2: [makeDetail(questionId: 2, attemptNumber: 1, status: 'in_progress')],
        3: <db.SubmissionDetailRow>[],
      };
      final results = QuestionStatusHelper.calculateBatch(map);
      expect(results[1]!.status, QuestionStatus.done);
      expect(results[2]!.status, QuestionStatus.inProgress);
      expect(results[3]!.status, QuestionStatus.undone);
    });
  });

  group('QuestionStatusHelper.calculateBatchByAttempt', () {
    test('batch by attempt returns correct keys', () {
      final map = {
        1: [
          makeDetail(questionId: 1, attemptNumber: 1, status: 'in_progress'),
          makeDetail(id: 2, questionId: 1, attemptNumber: 2, isCorrect: 1),
        ],
      };
      final results = QuestionStatusHelper.calculateBatchByAttempt(map);
      expect(results['1_1']!.status, QuestionStatus.inProgress);
      expect(results['1_2']!.status, QuestionStatus.done);
    });
  });
}
