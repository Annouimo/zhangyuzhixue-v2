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

    test('parseContent handles empty content', () {
      final content = LectureContent(chapterId: 2, title: 'empty', mdContent: '');
      final parsed = repo.parseContent(content);
      expect(parsed.totalPages, 0);
    });

    test('parseContent handles content with no separators (plain text)', () {
      final content = LectureContent(
        chapterId: 3,
        title: 'plain',
        mdContent: '这是一段纯文本内容，不包含任何分隔符。\n第二行内容。',
      );
      final parsed = repo.parseContent(content);
      expect(parsed.totalPages, 1);
      expect(parsed.pages[0].blocks.length, 1);
      expect(parsed.pages[0].blocks[0], contains('纯文本'));
    });

    test('parseContent handles content with LaTeX', () {
      final content = LectureContent(
        chapterId: 4,
        title: 'latex',
        mdContent: r'公式 $f(x) = ax^2 + bx + c$ 是二次函数的一般形式。'
            '\n<!-- pagebreak -->\n'
            r'行间公式 $$\int_{0}^{1} x^2 dx$$',
      );
      final parsed = repo.parseContent(content);
      expect(parsed.totalPages, 2);
      expect(parsed.pages[0].blocks[0], contains(r'$f(x)'));
      expect(parsed.pages[1].blocks[0], contains(r'\int'));
    });

    test('parseContent filters empty pages from consecutive pagebreaks', () {
      final content = LectureContent(
        chapterId: 5,
        title: 'spacing',
        mdContent: '第一页\n<!-- pagebreak -->\n<!-- pagebreak -->\n<!-- pagebreak -->\n第三页',
      );
      final parsed = repo.parseContent(content);
      // Empty pages from consecutive pagebreaks are filtered out
      expect(parsed.totalPages, 2);
      expect(parsed.pages[0].blocks[0], '第一页');
      expect(parsed.pages[1].blocks[0], '第三页');
    });
  });
}
