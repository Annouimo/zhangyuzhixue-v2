import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/app_database.dart' as db;
import 'package:flutter_app/data/daos/statistics_dao.dart';

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

    test('getDailyRecords filters isCorrect.isNotNull', () async {
      final now = DateTime.now().toIso8601String();
      // 2 completed + 1 in_progress
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
      final records = await dao.getDailyRecords(0);
      expect(records.length, 1); // only 1 day with 2 completed records
      expect(records[0].count, 2);
      expect(records[0].correct, 1);
    });

    test('getOverviewRaw returns all 4 values from one query', () async {
      final now = DateTime.now().toIso8601String();
      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      await database.into(database.submissionDetails).insert(db.SubmissionDetailsCompanion(
        questionId: Value(1), attemptNumber: Value(1), status: Value('completed'),
        isCorrect: Value(1), createdAt: Value(yesterday), updatedAt: Value(yesterday),
      ));
      await database.into(database.submissionDetails).insert(db.SubmissionDetailsCompanion(
        questionId: Value(2), attemptNumber: Value(1), status: Value('completed'),
        isCorrect: Value(1), createdAt: Value(now), updatedAt: Value(now),
      ));
      await database.into(database.submissionDetails).insert(db.SubmissionDetailsCompanion(
        questionId: Value(3), attemptNumber: Value(1), status: Value('completed'),
        isCorrect: Value(0), createdAt: Value(now), updatedAt: Value(now),
      ));
      final raw = await dao.getOverviewRaw();
      expect(raw.totalQuestions, 3);
      expect(raw.accuracy, closeTo(2 / 3, 0.01));
      expect(raw.activeDays, 2);
    });
  });
}
