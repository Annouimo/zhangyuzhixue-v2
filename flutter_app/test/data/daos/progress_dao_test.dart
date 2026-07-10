import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/app_database.dart' as db;
import 'package:flutter_app/data/daos/progress_dao.dart';

void main() {
  late db.AppDatabase database;
  late ProgressDao dao;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    dao = ProgressDao(database);
  });

  tearDown(() => database.close());

  group('ProgressDao', () {
    test('getAttempts returns empty initially', () async {
      expect(await dao.getAttempts(1), isEmpty);
    });

    test('createAttempt creates first attempt', () async {
      final id = await dao.createAttempt(questionId: 42);
      expect(id, greaterThan(0));
      final attempts = await dao.getAttempts(42);
      expect(attempts.length, 1);
      expect(attempts.first.attemptNumber, 1);
      expect(attempts.first.status, 'in_progress');
    });

    test('createAttempt increments attempt number', () async {
      await dao.createAttempt(questionId: 42);
      await dao.createAttempt(questionId: 42);
      final attempts = await dao.getAttempts(42);
      expect(attempts.length, 2);
      expect(attempts[0].attemptNumber, 1);
      expect(attempts[1].attemptNumber, 2);
    });

    test('getLatestAttempt returns most recent', () async {
      await dao.createAttempt(questionId: 42);
      final id2 = await dao.createAttempt(questionId: 42);
      final latest = await dao.getLatestAttempt(42);
      expect(latest, isNotNull);
      expect(latest!.id, id2);
    });

    test('updateAttemptStatus updates status', () async {
      final id = await dao.createAttempt(questionId: 42);
      await dao.updateAttemptStatus(id, 'completed');
      final attempt = (await dao.getAttempts(42)).first;
      expect(attempt.status, 'completed');
    });

    test('updateAttemptAnswer sets answer and completes', () async {
      final id = await dao.createAttempt(questionId: 42);
      await dao.updateAttemptAnswer(id, 'A', 1);
      final attempt = (await dao.getAttempts(42)).first;
      expect(attempt.answerText, 'A');
      expect(attempt.isCorrect, 1);
      expect(attempt.status, 'completed');
    });

    test('insertStepFeedback creates feedback', () async {
      final aId = await dao.createAttempt(questionId: 42);
      final fId = await dao.insertStepFeedback(
        submissionDetailId: aId, questionId: 42, stepNumber: 1, status: '全对',
      );
      expect(fId, greaterThan(0));
      final feedbacks = await dao.getStepFeedbacks(aId);
      expect(feedbacks.length, 1);
    });

    test('insertCardFeedback creates feedback', () async {
      final aId = await dao.createAttempt(questionId: 42);
      final fId = await dao.insertCardFeedback(
        submissionDetailId: aId, questionId: 42, cardTitle: '正弦定理', cardStatus: '完全掌握',
      );
      expect(fId, greaterThan(0));
      final feedbacks = await dao.getCardFeedbacks(aId);
      expect(feedbacks.length, 1);
    });

    test('hasAttempt returns false when no attempt', () async {
      expect(await dao.hasAttempt(42), false);
    });

    test('hasAttempt returns true after attempt', () async {
      await dao.createAttempt(questionId: 42);
      expect(await dao.hasAttempt(42), true);
    });
  });
}
