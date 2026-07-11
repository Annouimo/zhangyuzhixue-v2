import 'package:drift/drift.dart';
import '../database/lectures_database.dart' as db;
import '../debug/audit_logger.dart';

/// 讲义数据访问层（lectures 库）
class LectureDao {
  final db.LecturesDatabase _db;
  const LectureDao(this._db);

  // ── 课程 ──

  Future<List<db.CourseRow>> getAllCourses() async {
    final rows = await _db.select(_db.courses).get();
    AuditLogger.instance.dao('LectureDao.getAllCourses', rows.length, {});
    return rows;
  }

  Future<db.CourseRow?> getCourseById(int id) async {
    final q = _db.select(_db.courses)
      ..where((t) => t.id.equals(id));
    final result = await q.getSingleOrNull();
    AuditLogger.instance.dao('LectureDao.getCourseById', result != null ? 1 : 0, {'id': id});
    return result;
  }

  // ── 章节 ──

  Future<List<db.ChapterRow>> getChapters(int courseId) async {
    final q = _db.select(_db.chapters)
      ..where((t) => t.courseId.equals(courseId));
    q.orderBy([(t) => OrderingTerm(expression: t.index)]);
    final rows = await q.get();
    AuditLogger.instance.dao('LectureDao.getChapters', rows.length, {'courseId': courseId});
    return rows;
  }

  Future<db.ChapterRow?> getChapterById(int id) async {
    final q = _db.select(_db.chapters)
      ..where((t) => t.id.equals(id));
    final result = await q.getSingleOrNull();
    AuditLogger.instance.dao('LectureDao.getChapterById', result != null ? 1 : 0, {'id': id});
    return result;
  }

  // ── 讲义内容 ──

  Future<db.LectureContentRow?> getContent(int chapterId) async {
    final q = _db.select(_db.lectureContents)
      ..where((t) => t.chapterId.equals(chapterId));
    final result = await q.getSingleOrNull();
    AuditLogger.instance.dao('LectureDao.getContent', result != null ? 1 : 0, {'chapterId': chapterId});
    return result;
  }

  // ── 统计 ──

  Future<int> courseCount() async {
    final rows = await _db.select(_db.courses).get();
    AuditLogger.instance.dao('LectureDao.courseCount', rows.length, {});
    return rows.length;
  }

  Future<int> chapterCount(int courseId) async {
    final rows = await getChapters(courseId);
    AuditLogger.instance.dao('LectureDao.chapterCount', rows.length, {'courseId': courseId});
    return rows.length;
  }
}
