import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import '../../../lib/data/database/app_database.dart' as db;
import '../../../lib/data/daos/rating_dao.dart';

void main() {
  late db.AppDatabase database;
  late RatingDao dao;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    dao = RatingDao(database);
  });

  tearDown(() => database.close());

  group('RatingDao', () {
    test('getRating returns null for unrated question', () async {
      final result = await dao.getRating(1);
      expect(result, isNull);
    });

    test('upsertRating creates new rating', () async {
      await dao.upsertRating(
        questionId: 1,
        difficultyScore: 5,
        calculationScore: 6,
        eleganceScore: 7,
      );
      final result = await dao.getRating(1);
      expect(result, isNotNull);
      expect(result!.difficultyScore, 5);
      expect(result.calculationScore, 6);
      expect(result.eleganceScore, 7);
    });

    test('upsertRating updates existing rating', () async {
      await dao.upsertRating(questionId: 1, difficultyScore: 5, calculationScore: 6, eleganceScore: 7);
      await dao.upsertRating(questionId: 1, difficultyScore: 8, calculationScore: 9, eleganceScore: 10);
      final result = await dao.getRating(1);
      expect(result!.difficultyScore, 8);
      expect(result.calculationScore, 9);
    });

    test('ratings are isolated per question', () async {
      await dao.upsertRating(questionId: 1, difficultyScore: 1, calculationScore: 2, eleganceScore: 3);
      await dao.upsertRating(questionId: 2, difficultyScore: 4, calculationScore: 5, eleganceScore: 6);
      expect(await dao.getRating(1), isNotNull);
      expect(await dao.getRating(2), isNotNull);
      expect(await dao.getRating(3), isNull);
    });
  });
}
