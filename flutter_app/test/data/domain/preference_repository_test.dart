import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/app_database.dart' as db;
import 'package:flutter_app/data/daos/preference_dao.dart';
import 'package:flutter_app/domain/preference_repository.dart';
import 'package:flutter_app/data/database/database_provider.dart';

void main() {
  late db.AppDatabase database;
  late PreferenceDao dao;
  late PreferenceRepository repo;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    DatabaseProvider().setAppDbForTesting(database);
    dao = PreferenceDao(DatabaseProvider());
    repo = PreferenceRepository(dao);
  });

  tearDown(() => database.close());

  group('PreferenceRepository', () {
    test('save then getList returns items', () async {
      await repo.save(name: '海淀卷', filter: const PreferenceFilter(years: ['2024'], regions: ['海淀'], conceptTags: ['函数']));
      final list = await repo.getList();
      expect(list.length, 1);
      expect(list.first.name, '海淀卷');
    });

    test('getCount returns correct count', () async {
      expect(await repo.getCount(), 0);
      await repo.save(name: 'a', filter: const PreferenceFilter(years: [], regions: [], conceptTags: []));
      expect(await repo.getCount(), 1);
    });

    test('delete removes item', () async {
      await repo.save(name: 'x', filter: const PreferenceFilter(years: [], regions: [], conceptTags: []));
      expect(await repo.getCount(), 1);
      await repo.delete(1);
      expect(await repo.getCount(), 0);
    });
  });
}
