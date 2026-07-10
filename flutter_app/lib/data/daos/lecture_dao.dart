import 'package:drift/drift.dart';
import '../database/lectures_database.dart' as db;

/// 讲义数据访问层（lectures 库）
class LectureDao {
  final db.LecturesDatabase _db;
  const LectureDao(this._db);

  Future<List<db.CourseRow>> getAllCourses() async {
    final rows = await _db.customSelect(
      'SELECT * FROM courses',
      readsFrom: {_db.courses},
    ).get();
    return rows.map((r) => _db.courses.map(r.data)).toList();
  }

  Future<db.CourseRow?> getCourseById(int id) async {
    final rows = await _db.customSelect(
      'SELECT * FROM courses WHERE id = ?',
      variables: [Variable(id)],
      readsFrom: {_db.courses},
    ).get();
    if (rows.isEmpty) return null;
    return _db.courses.map(rows.first.data);
  }

  Future<List<db.ChapterRow>> getChapters(int courseId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM chapters WHERE course_id = ? ORDER BY "index"',
      variables: [Variable(courseId)],
      readsFrom: {_db.chapters},
    ).get();
    return rows.map((r) => _db.chapters.map(r.data)).toList();
  }

  Future<db.ChapterRow?> getChapterById(int id) async {
    final rows = await _db.customSelect(
      'SELECT * FROM chapters WHERE id = ?',
      variables: [Variable(id)],
      readsFrom: {_db.chapters},
    ).get();
    if (rows.isEmpty) return null;
    return _db.chapters.map(rows.first.data);
  }

  Future<db.LectureContentRow?> getContent(int chapterId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM lecture_contents WHERE chapter_id = ?',
      variables: [Variable(chapterId)],
      readsFrom: {_db.lectureContents},
    ).get();
    if (rows.isEmpty) return null;
    return _db.lectureContents.map(rows.first.data);
  }

  Future<int> courseCount() async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM courses',
      readsFrom: {_db.courses},
    ).getSingle();
    return row.read<int>('c')!;
  }

  Future<int> chapterCount(int courseId) async {
    final rows = await getChapters(courseId);
    return rows.length;
  }
}
