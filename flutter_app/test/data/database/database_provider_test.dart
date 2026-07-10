import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'dart:io';
import '../../../lib/data/database/assets_database.dart' as assets_db;
import '../../../lib/data/database/lectures_database.dart' as lectures_db;
import '../../../lib/data/database/app_database.dart' as app_db;
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

      // Write a question via typed API
      final now = DateTime.now().toIso8601String();
      await provider.assetsDb.into(provider.assetsDb.questions).insert(
        assets_db.QuestionsCompanion(
          year: Value(2024),
          examType: Value('高考'),
          region: Value('北京'),
          number: Value('1'),
          questionType: Value('choice'),
          difficulty: Value(5.0),
          calculation: Value(5.0),
          stem: Value('旧数据'),
        ),
      );

      var count = (await provider.assetsDb.select(provider.assetsDb.questions).get()).length;
      expect(count, 1);

      // Copy file and replace
      final newPath = tempDir.path + '/new_assets.db';
      await File(tempDir.path + '/assets.db').copy(newPath);
      await provider.replaceAssetsDb(newPath);

      // Still usable
      final tables = await provider.assetsDb.select(provider.assetsDb.questions).get();
      expect(tables.length, 1);
    });

    test('replaceLecturesDb swaps file', () async {
      final provider = DatabaseProvider();
      await provider.initWithPath(tempDir.path);
      // Trigger lazy open
      await provider.lecturesDb.select(provider.lecturesDb.courses).get();
      final newPath = tempDir.path + '/new_lectures.db';
      await File(tempDir.path + '/lectures.db').copy(newPath);
      await provider.replaceLecturesDb(newPath);
      final courses = await provider.lecturesDb.select(provider.lecturesDb.courses).get();
      expect(courses, isEmpty);
    });

    test('clearUserDb clears data', () async {
      final provider = DatabaseProvider();
      await provider.initWithPath(tempDir.path);
      final now = DateTime.now().toIso8601String();

      // Write via typed API
      await provider.appDb.into(provider.appDb.userProfiles).insert(
        app_db.UserProfilesCompanion(
          id: Value(1),
          name: Value('小明'),
          updatedAt: Value(now),
        ),
      );

      var rows = await provider.appDb.select(provider.appDb.userProfiles).get();
      expect(rows.length, 1);

      await provider.clearUserDb();

      rows = await provider.appDb.select(provider.appDb.userProfiles).get();
      expect(rows, isEmpty);
    });
  });
}
