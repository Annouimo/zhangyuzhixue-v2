import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/lectures_database.dart' as ldb;
import 'package:flutter_app/data/daos/lecture_dao.dart';
import 'package:flutter_app/domain/lecture_repository.dart';

void main() {
  late ldb.LecturesDatabase db;
  late LectureDao dao;
  late LectureRepository repo;

  setUp(() {
    db = ldb.LecturesDatabase(NativeDatabase.memory());
    dao = LectureDao(db);
    repo = LectureRepository(dao);
  });

  tearDown(() => db.close());

  group('LectureRepository', () {
    test('getCourses returns empty initially', () async {
      final courses = await repo.getCourses();
      expect(courses, isEmpty);
    });

    test('getContent throws for nonexistent', () async {
      expect(() => repo.getContent(999), throwsA(isA<Exception>()));
    });

    test('getChapters returns empty for nonexistent course', () async {
      final cl = await repo.getChapters(999);
      expect(cl.items, isEmpty);
    });

    test('parseContent splits pagebreak and reveal', () {
      final content = LectureContent(
        chapterId: 1,
        title: 'test',
        mdContent: 'block0\n<!-- pagebreak -->\nblock1a\n<!-- reveal -->\nblock1b',
      );
      final parsed = repo.parseContent(content);
      expect(parsed.totalPages, 2);
      expect(parsed.pages[0].blocks.length, 1);
      expect(parsed.pages[1].blocks.length, 2);
    });

    test('parseContent cache returns same instance', () {
      final content = LectureContent(chapterId: 1, title: 't', mdContent: 'a\n<!-- pagebreak -->\nb');
      final p1 = repo.parseContent(content);
      final p2 = repo.parseContent(content);
      expect(p1, same(p2));
    });
  });
}
