import 'package:drift/native.dart';
import 'package:flutter_app/data/database/courses_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('version 1 database creates video tables during upgrade', () async {
    final database = CoursesDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(database.close);

    expect(await database.select(database.videoCategories).get(), isEmpty);
    expect(await database.select(database.videos).get(), isEmpty);
    expect(await database.select(database.videoDocumentLinks).get(), isEmpty);
  });

  test('published version 0 database keeps existing video tables', () async {
    final database = CoursesDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE video_category (
              id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              description TEXT NOT NULL,
              sort_order INTEGER NOT NULL
            )
          ''');
          raw.execute('''
            CREATE TABLE video (
              id INTEGER PRIMARY KEY,
              category_id INTEGER NOT NULL,
              title TEXT NOT NULL,
              description TEXT NOT NULL,
              cover_url TEXT NOT NULL,
              platform_name TEXT NOT NULL,
              video_url TEXT NOT NULL,
              published_at TEXT,
              sort_order INTEGER NOT NULL
            )
          ''');
          raw.execute('''
            CREATE TABLE video_document_link (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              video_id INTEGER NOT NULL,
              chapter_id INTEGER NOT NULL,
              relation_label TEXT NOT NULL,
              sort_order INTEGER NOT NULL
            )
          ''');
          raw.execute('PRAGMA user_version = 0');
        },
      ),
    );
    addTearDown(database.close);

    expect(await database.select(database.videoCategories).get(), isEmpty);
    expect(await database.select(database.videos).get(), isEmpty);
    expect(await database.select(database.videoDocumentLinks).get(), isEmpty);
  });
}
