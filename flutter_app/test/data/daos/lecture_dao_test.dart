import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/courses_database.dart' as db;
import 'package:flutter_app/data/daos/lecture_dao.dart';
import 'package:flutter_app/data/database/database_provider.dart';

void main() {
  late db.CoursesDatabase database;
  late LectureDao dao;

  setUp(() {
    database = db.CoursesDatabase(NativeDatabase.memory());
    DatabaseProvider().setCoursesDbForTesting(database);
    dao = LectureDao(DatabaseProvider());
  });

  tearDown(() => database.close());

  group('LectureDao', () {
    test('getAllCourses returns empty initially', () async {
      expect(await dao.getAllCourses(), isEmpty);
    });

    test('getAllCourses returns all courses', () async {
      await database.into(database.courses).insert(db.CoursesCompanion(name: Value('代数')));
      await database.into(database.courses).insert(db.CoursesCompanion(name: Value('几何')));
      final result = await dao.getAllCourses();
      expect(result.length, 2);
    });

    test('getCourseById returns correct course', () async {
      final id = await database.into(database.courses).insert(
        db.CoursesCompanion(name: Value('三角函数'), description: Value('三角')),
      );
      final result = await dao.getCourseById(id);
      expect(result, isNotNull);
      expect(result!.name, '三角函数');
    });

    test('getCourseById returns null for nonexistent', () async {
      expect(await dao.getCourseById(999), isNull);
    });

    test('getChapters returns ordered chapters', () async {
      final cId = await database.into(database.courses).insert(db.CoursesCompanion(name: Value('C')));
      await database.into(database.chapters).insert(db.ChaptersCompanion(
        courseId: Value(cId), index: Value(2), title: Value('第2讲'),
      ));
      await database.into(database.chapters).insert(db.ChaptersCompanion(
        courseId: Value(cId), index: Value(1), title: Value('第1讲'),
      ));
      final result = await dao.getChapters(cId);
      expect(result.length, 2);
      expect(result[0].title, '第1讲');
      expect(result[1].title, '第2讲');
    });

    test('getChapters returns empty for course with no chapters', () async {
      expect(await dao.getChapters(999), isEmpty);
    });

    test('getContent returns correct content', () async {
      final cId = await database.into(database.courses).insert(db.CoursesCompanion(name: Value('C')));
      final chId = await database.into(database.chapters).insert(db.ChaptersCompanion(
        courseId: Value(cId), index: Value(1), title: Value('讲'),
      ));
      await database.into(database.lectureContents).insert(db.LectureContentsCompanion(
        chapterId: Value(chId), title: Value('内容'), mdContent: Value('## 正文'),
      ));
      final result = await dao.getContent(chId);
      expect(result, isNotNull);
      expect(result!.mdContent, '## 正文');
    });

    test('getContent returns null for nonexistent chapter', () async {
      expect(await dao.getContent(999), isNull);
    });

    test('courseCount returns correct count', () async {
      expect(await dao.courseCount(), 0);
      await database.into(database.courses).insert(db.CoursesCompanion(name: Value('A')));
      expect(await dao.courseCount(), 1);
    });

    test('chapterCount returns correct count', () async {
      final cId = await database.into(database.courses).insert(db.CoursesCompanion(name: Value('C')));
      await database.into(database.chapters).insert(db.ChaptersCompanion(
        courseId: Value(cId), index: Value(1), title: Value('讲'),
      ));
      expect(await dao.chapterCount(cId), 1);
    });
  });
}
