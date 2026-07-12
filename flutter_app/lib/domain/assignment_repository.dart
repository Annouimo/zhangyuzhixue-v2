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

  Future<List<AssignmentSummary>> getPending() async {
    final rows = await _assignmentDao.listAll();
    // 批量查询已做题 ID，避免 N+1
    final attempted = await _progressDao.getAttemptedQuestionIds();
    final result = <AssignmentSummary>[];
    for (final r in rows) {
      final qLinks = await _assignmentDao.getQuestions(r.id);
      final courseName = r.courseId != null
          ? (await _assignmentDao.getCourseName(r.courseId!)) ?? ''
          : '';

      // 统计已做题数（内存判断，无 DB 调用）
      var doneCount = 0;
      for (final ql in qLinks) {
        if (attempted.contains(ql.questionId)) doneCount++;
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

    // 批量查询已做题 ID
    final attempted = await _progressDao.getAttemptedQuestionIds();
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

      // 进度（内存判断 + 仅对已做题查最新记录）
      final status = attempted.contains(ql.questionId)
          ? await _questionStatusDetail(ql.questionId)
          : 'pending';
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

  /// 推算单题状态（用于详情页，跳过 hasAttempt 检查）
  Future<String> _questionStatusDetail(int questionId) async {
    final latest = await _progressDao.getLatestAttempt(questionId);
    if (latest == null) return 'in_progress';
    return latest.isCorrect == 1 ? 'completed' : 'in_progress';
  }

  Future<int> pendingCount() => _assignmentDao.count();
}
