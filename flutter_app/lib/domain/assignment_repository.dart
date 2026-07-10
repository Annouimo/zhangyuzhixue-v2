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
  // unused: QuestionDao (预留)
  const AssignmentRepository(this._assignmentDao);

  Future<List<AssignmentSummary>> getPending() async {
    final rows = await _assignmentDao.listAll();
    return rows.map((r) => AssignmentSummary(
      id: r.id,
      title: r.title,
      courseName: '',
      doneCount: 0,
      totalCount: _assignmentDao.getQuestions(r.id).then((q) => q.length).toString() as int,
      deadlineDays: 0,
      status: 'pending',
    )).toList();
  }

  Future<AssignmentDetail> getQuestions(int id) async {
    final assignment = await _assignmentDao.getById(id);
    if (assignment == null) throw Exception('Assignment not found: $id');
    final qLinks = await _assignmentDao.getQuestions(id);
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
      courseName: '',
      doneCount: 0,
      totalCount: questions.length,
      deadlineDays: 0,
      questions: questions,
    );
  }

  Future<int> pendingCount() => _assignmentDao.count();
}
