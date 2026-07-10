import 'package:drift/drift.dart';
import '../database/lectures_database.dart' as db;

/// 作业数据访问层（lectures 库）
class AssignmentDao {
  final db.LecturesDatabase _db;
  const AssignmentDao(this._db);

  Future<List<db.AssignmentRow>> listAll() async {
    final rows = await _db.customSelect(
      'SELECT * FROM assignments',
      readsFrom: {_db.assignments},
    ).get();
    return rows.map((r) => _db.assignments.map(r.data)).toList();
  }

  Future<db.AssignmentRow?> getById(int id) async {
    final rows = await _db.customSelect(
      'SELECT * FROM assignments WHERE id = ?',
      variables: [Variable(id)],
      readsFrom: {_db.assignments},
    ).get();
    if (rows.isEmpty) return null;
    return _db.assignments.map(rows.first.data);
  }

  Future<List<db.AssignmentRow>> getByCourse(int courseId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM assignments WHERE course_id = ?',
      variables: [Variable(courseId)],
      readsFrom: {_db.assignments},
    ).get();
    return rows.map((r) => _db.assignments.map(r.data)).toList();
  }

  Future<List<db.AssignmentQuestionRow>> getQuestions(int assignmentId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM assignment_questions WHERE assignment_id = ? ORDER BY sort_order',
      variables: [Variable(assignmentId)],
      readsFrom: {_db.assignmentQuestions},
    ).get();
    return rows.map((r) => _db.assignmentQuestions.map(r.data)).toList();
  }

  Future<List<int>> getQuestionIds(int assignmentId) async {
    final rows = await getQuestions(assignmentId);
    return rows.map((r) => r.questionId).toList();
  }

  Future<int> count() async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM assignments',
      readsFrom: {_db.assignments},
    ).getSingle();
    return row.read<int>('c')!;
  }
}
