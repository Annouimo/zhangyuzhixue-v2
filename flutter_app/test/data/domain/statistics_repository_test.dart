import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/app_database.dart' as udb;
import 'package:flutter_app/data/daos/statistics_dao.dart';
import 'package:flutter_app/domain/statistics_repository.dart';

void main() {
  late udb.AppDatabase uDb;
  late StatisticsDao dao;
  late StatisticsRepository repo;

  setUp(() {
    uDb = udb.AppDatabase(NativeDatabase.memory());
    dao = StatisticsDao(uDb);
    repo = StatisticsRepository(dao);
  });

  tearDown(() => uDb.close());

  group('StatisticsRepository', () {
    test('totalQuestions returns 0 initially', () async {
      expect(await repo.totalQuestions(), 0);
    });

    test('accuracy returns 0 initially', () async {
      expect(await repo.accuracy(), 0);
    });

    test('getOverview returns zero stats', () async {
      final ov = await repo.getOverview();
      expect(ov.totalQuestions, 0);
      expect(ov.accuracyPercent, 0);
    });

    test('getDailyRecords returns empty', () async {
      expect(await repo.getDailyRecords(7), isEmpty);
    });
  });
}
