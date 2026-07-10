import 'package:drift/drift.dart';
import '../database/lectures_database.dart' as db;

/// 讲义数据访问层（lectures 库）
class LectureDao {
  final db.LecturesDatabase _db;
  const LectureDao(this._db);

  // ── 课程 ──

  Future<List<db.CourseRow>> getAllCourses() =>
      _db.select(_db.courses).get();

  Future<db.CourseRow?> getCourseById(int id) async {
    final q = _db.select(_db.courses)
      ..where((t) => t.id.equals(id));
    return q.getSingleOrNull();
  }

  // ── 章节 ──

  Future<List<db.ChapterRow>> getChapters(int courseId) async {
    final q = _db.select(_db.chapters)
      ..where((t) => t.courseId.equals(courseId));
    q.orderBy([(t) => OrderingTerm(expression: t.index)]);
    return q.get();
  }

  Future<db.ChapterRow?> getChapterById(int id) async {
    final q = _db.select(_db.chapters)
      ..where((t) => t.id.equals(id));
    return q.getSingleOrNull();
  }

  // ── 讲义内容 ──

  Future<db.LectureContentRow?> getContent(int chapterId) async {
    final q = _db.select(_db.lectureContents)
      ..where((t) => t.chapterId.equals(chapterId));
    return q.getSingleOrNull();
  }

  // ── 统计 ──

  Future<int> courseCount() =>
      _db.select(_db.courses).get().then((r) => r.length);

  Future<int> chapterCount(int courseId) async {
    final rows = await getChapters(courseId);
    return rows.length;
  }
}
