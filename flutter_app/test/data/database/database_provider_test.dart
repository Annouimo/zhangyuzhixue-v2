import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'dart:io';
import '../../../lib/data/database/database_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('db_provider_test_');
  });

  tearDown(() async {
    await DatabaseProvider().reset();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('DatabaseProvider', () {
    test('initWithPath opens three databases', () async {
      final provider = DatabaseProvider();
      await provider.initWithPath(tempDir.path);
      expect(provider.assetsDb, isNotNull);
      expect(provider.lecturesDb, isNotNull);
      expect(provider.appDb, isNotNull);
    });

    test('initWithPath is idempotent', () async {
      final provider = DatabaseProvider();
      await provider.initWithPath(tempDir.path);
      final ref = provider.assetsDb;
      await provider.initWithPath(tempDir.path);
      expect(provider.assetsDb, same(ref));
    });

    test('getters throw StateError before init', () {
      final provider = DatabaseProvider();
      expect(() => provider.appDb, throwsStateError);
      expect(() => provider.assetsDb, throwsStateError);
      expect(() => provider.lecturesDb, throwsStateError);
    });

    test('replaceAssetsDb swaps file', () async {
      final provider = DatabaseProvider();
      await provider.initWithPath(tempDir.path);

      // Write data
      await provider.assetsDb.customInsert(
        'INSERT INTO questions (year, exam_type, region, number, question_type, stem) VALUES (2024, ?, ?, ?, ?, ?)',
        variables: [Variable('高考'), Variable('北京'), Variable('1'), Variable('choice'), Variable('旧')],
      );
      final count = (await provider.assetsDb.customSelect(
        'SELECT COUNT(*) AS c FROM questions',
        readsFrom: {provider.assetsDb.questions},
      ).getSingle()).read<int>('c')!;
      expect(count, 1);

      // Copy file and replace
      final newPath = tempDir.path + '/new_assets.db';
      await File(tempDir.path + '/assets.db').copy(newPath);
      await provider.replaceAssetsDb(newPath);

      // Still usable
      final tables = await provider.assetsDb.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='questions'",
        readsFrom: {},
      ).get();
      expect(tables.length, 1);
    });

    test('replaceLecturesDb swaps file', () async {
      final provider = DatabaseProvider();
      await provider.initWithPath(tempDir.path);
      // Trigger lazy open
      await provider.lecturesDb.customSelect('SELECT 1', readsFrom: {}).get();
      final newPath = tempDir.path + '/new_lectures.db';
      await File(tempDir.path + '/lectures.db').copy(newPath);
      await provider.replaceLecturesDb(newPath);
      final tables = await provider.lecturesDb.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table'",
        readsFrom: {},
      ).get();
      expect(tables.isNotEmpty, true);
    });

    test('clearUserDb clears data', () async {
      final provider = DatabaseProvider();
      await provider.initWithPath(tempDir.path);
      await provider.appDb.customInsert(
        'INSERT INTO user_profiles (id, name, updated_at) VALUES (?, ?, ?)',
        variables: [Variable(1), Variable('小明'), Variable(DateTime.now().toIso8601String())],
      );
      var rows = await provider.appDb.customSelect(
        'SELECT * FROM user_profiles',
        readsFrom: {provider.appDb.userProfiles},
      ).get();
      expect(rows.length, 1);

      await provider.clearUserDb();

      rows = await provider.appDb.customSelect(
        'SELECT * FROM user_profiles',
        readsFrom: {provider.appDb.userProfiles},
      ).get();
      expect(rows, isEmpty);
    });
  });
}
