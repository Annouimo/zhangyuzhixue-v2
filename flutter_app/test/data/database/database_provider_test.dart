@Tags(['smoke'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_app/data/database/assets_database.dart' as assets_db;
import 'package:flutter_app/data/database/app_database.dart' as app_db;
import 'package:flutter_app/data/database/courses_database.dart' as courses_db;
import 'package:flutter_app/data/database/database_provider.dart';
import 'dart:io';

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
      expect(provider.coursesDb, isNotNull);
      expect(provider.appDb, isNotNull);
    });

    test('initWithPath is idempotent', () async {
      final provider = DatabaseProvider();
      await provider.initWithPath(tempDir.path);
      final ref = provider.assetsDb;
      await provider.initWithPath(tempDir.path);
      expect(provider.assetsDb, same(ref));
    });

    test('dataVersion reads the open database meta rows', () async {
      final provider = DatabaseProvider();
      await provider.initWithPath(tempDir.path);
      await provider.assetsDb
          .into(provider.assetsDb.meta)
          .insert(
        assets_db.MetaCompanion.insert(
              schemaVersion: 1,
              dataVersion: 15,
              checksum: 'qbank',
              builtAt: 'now',
            ),
          );
      await provider.coursesDb
          .into(provider.coursesDb.meta)
          .insert(
        courses_db.MetaCompanion.insert(
              schemaVersion: 1,
              dataVersion: 7,
              checksum: 'courses',
              builtAt: 'now',
            ),
          );

      expect(await provider.dataVersion('qbank'), 15);
      expect(await provider.dataVersion('courses'), 7);
      expect(() => provider.dataVersion('user'), throwsArgumentError);
    });

    test('getters throw StateError before init', () {
      final provider = DatabaseProvider();
      expect(() => provider.appDb, throwsStateError);
      expect(() => provider.assetsDb, throwsStateError);
      expect(() => provider.coursesDb, throwsStateError);
    });

    test('replaceAssetsDb swaps file', () async {
      final provider = DatabaseProvider();
      await provider.initWithPath(tempDir.path);

      await provider.assetsDb
          .into(provider.assetsDb.questions)
          .insert(
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
      var count =
          (await provider.assetsDb.select(provider.assetsDb.questions).get())
              .length;
      expect(count, 1);

      final newPath = '${tempDir.path}/new_assets.db';
      await File('${tempDir.path}/assets.db').copy(newPath);
      await provider.replaceAssetsDb(newPath);

      final tables = await provider.assetsDb
          .select(provider.assetsDb.questions)
          .get();
      expect(tables.length, 1);
    });

    test('replaceCoursesDb swaps file', () async {
      final provider = DatabaseProvider();
      await provider.initWithPath(tempDir.path);
      await provider.coursesDb.select(provider.coursesDb.courses).get();
      final newPath = '${tempDir.path}/new_courses.db';
      await File('${tempDir.path}/courses.db').copy(newPath);
      await provider.replaceCoursesDb(newPath);
      final courses = await provider.coursesDb
          .select(provider.coursesDb.courses)
          .get();
      expect(courses, isEmpty);
    });

    test('clearUserDb clears data', () async {
      final provider = DatabaseProvider();
      await provider.initWithPath(tempDir.path);

      await provider.appDb
          .into(provider.appDb.userProfiles)
          .insert(
            app_db.UserProfilesCompanion(
              id: Value(1),
              name: Value('小明'),
              updatedAt: Value(DateTime.now().toIso8601String()),
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
