import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/app_database.dart' as db;
import 'package:flutter_app/data/database/assets_database.dart' as adb;
import 'package:flutter_app/data/daos/rating_dao.dart';
import 'package:flutter_app/data/daos/question_dao.dart';
import 'package:flutter_app/domain/rating_repository.dart';

void main() {
  late db.AppDatabase database;
  late adb.AssetsDatabase assetsDatabase;
  late RatingDao dao;
  late RatingRepository repo;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    assetsDatabase = adb.AssetsDatabase(NativeDatabase.memory());
    dao = RatingDao(database);
    repo = RatingRepository(dao, QuestionDao(assetsDatabase));
  });

  tearDown(() {
    database.close();
    assetsDatabase.close();
  });

  group('RatingRepository', () {
    test('getRating returns default when no rating', () async {
      final r = await repo.getRating(1);
      expect(r.algorithmDifficulty, 0);
      expect(r.algorithmCalculation, 0);
      expect(r.userDifficulty, isNull);
    });

    test('submitRating then getRating returns user values', () async {
      await repo.submitRating(questionId: 1, difficulty: 3, calculation: 5, elegance: 4);
      final r = await repo.getRating(1);
      expect(r.userDifficulty, 3.0);
      expect(r.userCalculation, 5.0);
      expect(r.userElegance, 4.0);
    });
  });
}
