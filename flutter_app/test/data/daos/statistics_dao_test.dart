import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import '../../../lib/data/database/app_database.dart' as db;
import '../../../lib/data/daos/statistics_dao.dart';

void main() {
  late db.AppDatabase database;
  late StatisticsDao dao;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    dao = StatisticsDao(database);
  });

  tearDown(() => database.close());

  group('StatisticsDao', () {
    test('getTotalQuestions returns 0 initially', () async {
      expect(await dao.getTotalQuestions(), 0);
    });

    test('getAccuracy returns 0 when no data', () async {
      expect(await dao.getAccuracy(), 0.0);
    });

    test('getTotalQuestions counts completed attempts', () async {
      final now = DateTime.now().toIso8601String();
      await database.into(database.submissionDetails).insert(db.SubmissionDetailsCompanion(
        questionId: Value(1), attemptNumber: Value(1), status: Value('completed'),
        isCorrect: Value(1), createdAt: Value(now), updatedAt: Value(now),
      ));
      await database.into(database.submissionDetails).insert(db.SubmissionDetailsCompanion(
        questionId: Value(2), attemptNumber: Value(1), status: Value('completed'),
        isCorrect: Value(0), createdAt: Value(now), updatedAt: Value(now),
      ));
      await database.into(database.submissionDetails).insert(db.SubmissionDetailsCompanion(
        questionId: Value(3), attemptNumber: Value(1), status: Value('in_progress'),
        createdAt: Value(now), updatedAt: Value(now),
      ));
      // in_progress should not be counted (is_correct IS NOT NULL)
      expect(await dao.getTotalQuestions(), 2);
    });

    test('getAccuracy returns correct ratio', () async {
      final now = DateTime.now().toIso8601String();
      await database.into(database.submissionDetails).insert(db.SubmissionDetailsCompanion(
        questionId: Value(1), attemptNumber: Value(1), status: Value('completed'),
        isCorrect: Value(1), createdAt: Value(now), updatedAt: Value(now),
      ));
      await database.into(database.submissionDetails).insert(db.SubmissionDetailsCompanion(
        questionId: Value(2), attemptNumber: Value(1), status: Value('completed'),
        isCorrect: Value(0), createdAt: Value(now), updatedAt: Value(now),
      ));
      expect(await dao.getAccuracy(), closeTo(0.5, 0.01));
    });
  });
}
