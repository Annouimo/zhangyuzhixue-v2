import '../data/daos/assignment_dao.dart';
/// 作业摘要

/// 作业摘要
class AssignmentSummary {
  final int id;
  final String title;
  final String courseName;
  final int doneCount;
  final int totalCount;
  final int deadlineDays;
  final String status;

  const AssignmentSummary({
    required this.id,
    required this.title,
    required this.courseName,
    required this.doneCount,
    required this.totalCount,
    required this.deadlineDays,
    required this.status,
  });
}

/// 作业中的题目摘要
class QuestionSummary {
  final int id;
  final String number;
  final String questionType;
  final String status;

  const QuestionSummary({
    required this.id,
    required this.number,
    required this.questionType,
    required this.status,
  });
}

/// 作业详情
class AssignmentDetail {
  final String title;
  final String courseName;
  final int doneCount;
  final int totalCount;
  final int deadlineDays;
  final List<QuestionSummary> questions;

  const AssignmentDetail({
    required this.title,
    required this.courseName,
    required this.doneCount,
    required this.totalCount,
    required this.deadlineDays,
    required this.questions,
  });
}

/// 作业 Repository — 从 lectures 库读取作业定义
class AssignmentRepository {
  final AssignmentDao _assignmentDao;
  const AssignmentRepository(this._assignmentDao);

  Future<List<AssignmentSummary>> getPending() async {
    final rows = await _assignmentDao.listAll();
    final result = <AssignmentSummary>[];
    for (final r in rows) {
      final questions = await _assignmentDao.getQuestions(r.id);
      final courseName = r.courseId != null
          ? (await _assignmentDao.getCourseName(r.courseId!)) ?? ''
          : '';
      result.add(AssignmentSummary(
        id: r.id,
        title: r.title,
        courseName: courseName,
        doneCount: 0,
        totalCount: questions.length,
        deadlineDays: 0,
        status: 'pending',
      ));
    }
    return result;
  }

  Future<AssignmentDetail> getQuestions(int id) async {
    final assignment = await _assignmentDao.getById(id);
    if (assignment == null) throw Exception('Assignment not found: $id');
    final qLinks = await _assignmentDao.getQuestions(id);
    final courseName = assignment.courseId != null
        ? (await _assignmentDao.getCourseName(assignment.courseId!)) ?? ''
        : '';
    final questions = qLinks.map((ql) {
      return QuestionSummary(
        id: ql.questionId,
        number: '',
        questionType: '',
        status: 'pending',
      );
    }).toList();
    return AssignmentDetail(
      title: assignment.title,
      courseName: courseName,
      doneCount: 0,
      totalCount: questions.length,
      deadlineDays: 0,
      questions: questions,
    );
  }

  Future<int> pendingCount() => _assignmentDao.count();
}
