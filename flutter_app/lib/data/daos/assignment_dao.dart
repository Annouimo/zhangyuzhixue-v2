import 'package:drift/drift.dart';
import '../database/courses_database.dart' as db;
import '../database/database_provider.dart';
import '../debug/audit_logger.dart';

/// 作业数据访问层（lectures 库）
class AssignmentDao {
  final DatabaseProvider _provider;
  AssignmentDao(this._provider);
  db.CoursesDatabase get _db => _provider.coursesDb;

  Future<List<db.AssignmentRow>> listAll() async {
    final rows = await _db.select(_db.assignments).get();
    AuditLogger.instance.dao('AssignmentDao.listAll', rows.length, {});
    return rows;
  }

  Future<db.AssignmentRow?> getById(int id) async {
    final q = _db.select(_db.assignments)
      ..where((t) => t.id.equals(id));
    final result = await q.getSingleOrNull();
    AuditLogger.instance.dao('AssignmentDao.getById', result != null ? 1 : 0, {'id': id});
    return result;
  }

  Future<List<db.AssignmentRow>> getByCourse(int courseId) async {
    final q = _db.select(_db.assignments)
      ..where((t) => t.courseId.equals(courseId));
    final rows = await q.get();
    AuditLogger.instance.dao('AssignmentDao.getByCourse', rows.length, {'courseId': courseId});
    return rows;
  }

  Future<List<db.AssignmentQuestionRow>> getQuestions(int assignmentId) async {
    final q = _db.select(_db.assignmentQuestions)
      ..where((t) => t.assignmentId.equals(assignmentId));
    q.orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    final rows = await q.get();
    AuditLogger.instance.dao('AssignmentDao.getQuestions', rows.length, {'assignmentId': assignmentId});
    return rows;
  }

  Future<List<int>> getQuestionIds(int assignmentId) async {
    final ids = await getQuestions(assignmentId);
    final result = ids.map((r) => r.questionId).toList();
    AuditLogger.instance.dao('AssignmentDao.getQuestionIds', result.length, {'assignmentId': assignmentId});
    return result;
  }

  Future<int> count() async {
    final rows = await _db.select(_db.assignments).get();
    AuditLogger.instance.dao('AssignmentDao.count', rows.length, {});
    return rows.length;
  }

  Future<String?> getCourseName(int courseId) async {
    final q = _db.select(_db.courses)..where((t) => t.id.equals(courseId));
    final row = await q.getSingleOrNull();
    AuditLogger.instance.dao('AssignmentDao.getCourseName', row != null ? 1 : 0, {'courseId': courseId});
    return row?.name;
  }
}
