import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import '../../../lib/data/database/app_database.dart' as db;
import '../../../lib/data/daos/preference_dao.dart';

void main() {
  late db.AppDatabase database;
  late PreferenceDao dao;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    dao = PreferenceDao(database);
  });

  tearDown(() => database.close());

  group('PreferenceDao', () {
    test('listAll returns empty initially', () async {
      expect(await dao.listAll(), isEmpty);
    });

    test('save and listAll', () async {
      await dao.save(name: '我的偏好', years: '[2024]', regions: '["海淀"]', conceptTags: '["函数"]');
      final list = await dao.listAll();
      expect(list.length, 1);
      expect(list.first.name, '我的偏好');
    });

    test('getById returns saved preference', () async {
      final id = await dao.save(name: 'N', years: '[]', regions: '[]', conceptTags: '[]');
      final result = await dao.getById(id);
      expect(result, isNotNull);
      expect(result!.name, 'N');
    });

    test('getById returns null for nonexistent', () async {
      expect(await dao.getById(999), isNull);
    });

    test('delete removes preference', () async {
      final id = await dao.save(name: 'N', years: '[]', regions: '[]', conceptTags: '[]');
      await dao.delete(id);
      expect(await dao.getById(id), isNull);
    });

    test('count returns correct number', () async {
      expect(await dao.count(), 0);
      await dao.save(name: 'A', years: '[]', regions: '[]', conceptTags: '[]');
      await dao.save(name: 'B', years: '[]', regions: '[]', conceptTags: '[]');
      expect(await dao.count(), 2);
    });
  });
}
