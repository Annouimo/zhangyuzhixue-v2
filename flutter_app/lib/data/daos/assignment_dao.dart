import 'package:drift/drift.dart';
import '../database/lectures_database.dart' as db;

/// 作业数据访问层（lectures 库）
class AssignmentDao {
  final db.LecturesDatabase _db;
  const AssignmentDao(this._db);

  Future<List<db.AssignmentRow>> listAll() =>
      _db.select(_db.assignments).get();

  Future<db.AssignmentRow?> getById(int id) async {
    final q = _db.select(_db.assignments)
      ..where((t) => t.id.equals(id));
    return q.getSingleOrNull();
  }

  Future<List<db.AssignmentRow>> getByCourse(int courseId) async {
    final q = _db.select(_db.assignments)
      ..where((t) => t.courseId.equals(courseId));
    return q.get();
  }

  Future<List<db.AssignmentQuestionRow>> getQuestions(int assignmentId) async {
    final q = _db.select(_db.assignmentQuestions)
      ..where((t) => t.assignmentId.equals(assignmentId));
    q.orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    return q.get();
  }

  Future<List<int>> getQuestionIds(int assignmentId) async {
    final rows = await getQuestions(assignmentId);
    return rows.map((r) => r.questionId).toList();
  }

  Future<int> count() =>
      _db.select(_db.assignments).get().then((r) => r.length);

  Future<String?> getCourseName(int courseId) async {
    final q = _db.select(_db.courses)..where((t) => t.id.equals(courseId));
    final row = await q.getSingleOrNull();
    return row?.name;
  }
}
