import '../data/daos/assignment_dao.dart';
import '../data/daos/progress_dao.dart';
import '../data/daos/question_dao.dart';

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

/// 作业 Repository — 跨 3 库查询
///
/// 依赖：
/// - AssignmentDao (lectures 库) — 作业定义
/// - ProgressDao (user 库) — 答题进度
/// - QuestionDao (assets 库) — 题号/题型
class AssignmentRepository {
  final AssignmentDao _assignmentDao;
  final ProgressDao _progressDao;
  final QuestionDao _questionDao;

  AssignmentRepository(this._assignmentDao, this._progressDao, this._questionDao);

  /// 推算单题状态
  Future<String> _questionStatus(int questionId) async {
    final has = await _progressDao.hasAttempt(questionId);
    if (!has) return 'pending';
    final latest = await _progressDao.getLatestAttempt(questionId);
    if (latest == null) return 'in_progress';
    return latest.isCorrect == 1 ? 'completed' : 'in_progress';
  }

  Future<List<AssignmentSummary>> getPending() async {
    final rows = await _assignmentDao.listAll();
    final result = <AssignmentSummary>[];
    for (final r in rows) {
      final qLinks = await _assignmentDao.getQuestions(r.id);
      final courseName = r.courseId != null
          ? (await _assignmentDao.getCourseName(r.courseId!)) ?? ''
          : '';

      // 统计已做题数
      var doneCount = 0;
      for (final ql in qLinks) {
        if (await _progressDao.hasAttempt(ql.questionId)) doneCount++;
      }

      result.add(AssignmentSummary(
        id: r.id,
        title: r.title,
        courseName: courseName,
        doneCount: doneCount,
        totalCount: qLinks.length,
        deadlineDays: 0,  // 见下方说明
        status: doneCount > 0 ? (doneCount == qLinks.length ? 'completed' : 'in_progress') : 'pending',
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

    var doneCount = 0;
    final questions = <QuestionSummary>[];
    for (final ql in qLinks) {
      // 题号/题型
      String number = '', questionType = '';
      try {
        final q = await _questionDao.getById(ql.questionId);
        if (q != null) {
          number = q.number;
          questionType = q.questionType;
        }
      } catch (_) {}

      // 进度
      final status = await _questionStatus(ql.questionId);
      if (status == 'completed') doneCount++;

      questions.add(QuestionSummary(
        id: ql.questionId,
        number: number,
        questionType: questionType,
        status: status,
      ));
    }

    return AssignmentDetail(
      title: assignment.title,
      courseName: courseName,
      doneCount: doneCount,
      totalCount: questions.length,
      deadlineDays: 0,
      questions: questions,
    );
  }

  Future<int> pendingCount() => _assignmentDao.count();
}
