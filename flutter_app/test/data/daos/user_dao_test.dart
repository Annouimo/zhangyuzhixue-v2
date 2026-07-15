import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/app_database.dart' as db;
import 'package:flutter_app/data/daos/user_dao.dart';
import 'package:flutter_app/data/database/database_provider.dart';

void main() {
  late db.AppDatabase database;
  late UserDao dao;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    DatabaseProvider().setAppDbForTesting(database);
    dao = UserDao(DatabaseProvider());
  });

  tearDown(() => database.close());

  group('UserDao', () {
    test('getProfile returns null initially', () async {
      expect(await dao.getProfile(), isNull);
    });

    test('saveProfile inserts new profile', () async {
      await dao.saveProfile(id: 1, name: '小明');
      final profile = await dao.getProfile();
      expect(profile, isNotNull);
      expect(profile!.name, '小明');
    });

    test('saveProfile updates existing profile', () async {
      await dao.saveProfile(id: 1, name: '小明');
      await dao.saveProfile(id: 1, name: '大明');
      final profile = await dao.getProfile();
      expect(profile!.name, '大明');
    });

    test('getPointsHistory returns empty initially', () async {
      expect(await dao.getPointsHistory(), isEmpty);
    });

    test('getEarnedPoints aggregates correctly', () async {
      final now = DateTime.now().toIso8601String();
      await database.into(database.pointsTransactions).insert(
        db.PointsTransactionsCompanion(amount: Value(5), transactionType: Value('EARN'), source: Value('PRACTICE_REWARD'), createdAt: Value(now)),
      );
      await database.into(database.pointsTransactions).insert(
        db.PointsTransactionsCompanion(amount: Value(3), transactionType: Value('EARN'), source: Value('LOGIN_BONUS'), createdAt: Value(now)),
      );
      expect(await dao.getEarnedPoints(), 8);
    });

    test('getStreakDays returns 0 initially', () async {
      expect(await dao.getStreakDays(), 0);
    });
  });
}
