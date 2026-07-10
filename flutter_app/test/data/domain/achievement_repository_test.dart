import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/app_database.dart' as db;
import 'package:flutter_app/data/daos/achievement_dao.dart';
import 'package:flutter_app/domain/achievement_repository.dart';

void main() {
  late db.AppDatabase database;
  late AchievementDao dao;
  late AchievementRepository repo;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    dao = AchievementDao(database);
    repo = AchievementRepository(dao);
  });

  tearDown(() => database.close());

  group('AchievementRepository', () {
    test('getSummary returns 0 unlocked', () async {
      final s = await repo.getSummary();
      expect(s.unlockedCount, 0);
    });

    test('unlockedCount returns 0 initially', () async {
      expect(await repo.unlockedCount(), 0);
    });

    test('getCategories returns empty when no progress', () async {
      final cats = await repo.getCategories();
      expect(cats, isEmpty);
    });
  });
}
