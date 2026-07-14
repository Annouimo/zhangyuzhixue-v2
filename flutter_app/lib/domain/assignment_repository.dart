import '../data/daos/assignment_dao.dart';
import '../data/daos/progress_dao.dart';
import '../data/daos/question_dao.dart';
import '../data/api/user_api.dart';
import '../data/api/api_client.dart';
import '../data/prefs/app_prefs.dart';

/// 作业摘要
class AssignmentSummary {
  final int id;
  final String title;
  final String courseName;
  final int doneCount;
  final int totalCount;
  final int? deadlineDays;  // null = 无截止日期
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
  final int? deadlineDays;  // null = 无截止日期
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

/// 作业 Repository — 跨 3 库查询 + API
///
/// 依赖：
/// - AssignmentDao (lectures 库) — 作业定义
/// - ProgressDao (user 库) — 答题进度
/// - QuestionDao (assets 库) — 题号/题型
/// - UserApi — 待办作业 API（含班级过滤 + deadline）
class AssignmentRepository {
  final AssignmentDao _assignmentDao;
  final ProgressDao _progressDao;
  final QuestionDao _questionDao;
  final UserApi _userApi;

  AssignmentRepository(this._assignmentDao, this._progressDao, this._questionDao,
      {UserApi? userApi})
      : _userApi = userApi ?? UserApi(ApiClient());

  Future<List<AssignmentSummary>> getPending() async {
    // 优先走 API（含班级过滤 + deadline）
    try {
      return await _getPendingFromApi();
    } catch (_) {
      // API 失败 → 回退本地查询
      return getPendingLocal();
    }
  }

  /// 纯本地查询（不依赖 API），用于离线回退和首页快速展示
  Future<List<AssignmentSummary>> getPendingLocal() async {
    return _getPendingLocal();
  }

  /// 仅走 API，不含本地回退
  Future<List<AssignmentSummary>> _getPendingFromApi() async {
    final data = await _userApi.pendingAssignments();
    final accessibleIds = (data['accessible_course_ids'] as List).cast<int>();
    if (accessibleIds.isNotEmpty) {
      try {
        await AppPrefs().setAccessibleCourseIds(accessibleIds);
      } catch (_) {
        // AppPrefs 未初始化，静默跳过
      }
    }

    final rawList = data['assignments'] as List;
    final completed = await _progressDao.getCompletedQuestionIds();

    // 预加载所有 question IDs（避免 N+1）
    final allQids = <int, List<int>>{};
    for (final r in rawList) {
      final id = r['id'] as int;
      allQids[id] = await _assignmentDao.getQuestionIds(id);
    }

    final result = <AssignmentSummary>[];
    for (final r in rawList) {
      final id = r['id'] as int;
      final totalCount = r['total_count'] as int;
      final deadlineRemaining = r['deadline_remaining'] as int?;
      final qIds = allQids[id] ?? [];

      var doneCount = 0;
      for (final qid in qIds) {
        if (completed.contains(qid)) doneCount++;
      }

      result.add(AssignmentSummary(
        id: id,
        title: r['title'] as String,
        courseName: r['course_name'] as String? ?? '',
        doneCount: doneCount,
        totalCount: totalCount,
        deadlineDays: deadlineRemaining,
        status: doneCount > 0
            ? (doneCount == totalCount ? 'completed' : 'in_progress')
            : 'pending',
      ));
    }
    return result;
  }

  /// 本地回退方案（无 deadline 信息，accessibleCourseIds 过滤）
  Future<List<AssignmentSummary>> _getPendingLocal() async {
    final rows = await _assignmentDao.listAll();
    final accessibleIds = _safeAccessibleIds();
    final attempted = await _progressDao.getAttemptedQuestionIds();
    final result = <AssignmentSummary>[];
    for (final r in rows) {
      // 用 accessibleCourseIds 过滤
      if (accessibleIds.isNotEmpty && r.courseId != null &&
          !accessibleIds.contains(r.courseId)) {
        continue;
      }

      final qLinks = await _assignmentDao.getQuestions(r.id);
      final courseName = r.courseId != null
          ? (await _assignmentDao.getCourseName(r.courseId!)) ?? ''
          : '';

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
        deadlineDays: null,  // 本地回退无 deadline 信息
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
      String number = '', questionType = '';
      try {
        final q = await _questionDao.getById(ql.questionId);
        if (q != null) {
          number = q.number;
          questionType = q.questionType;
        }
      } catch (_) {}

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
      deadlineDays: null,  // 详情页从本地查，无 deadline 信息
      questions: questions,
    );
  }

  /// 推算单题状态（用于详情页，跳过 hasAttempt 检查）
  /// 设计文档 §10.2: is_correct 有值(true/false) = 已完成
  Future<String> _questionStatusDetail(int questionId) async {
    final latest = await _progressDao.getLatestAttempt(questionId);
    if (latest == null) return 'in_progress';
    return latest.isCorrect != null ? 'completed' : 'in_progress';
  }

  Future<int> pendingCount() async => AppPrefs().pendingHomeworkCount;

  /// AppPrefs 未初始化时安全返回空列表
  List<int> _safeAccessibleIds() {
    try {
      return AppPrefs().accessibleCourseIds;
    } catch (_) {
      return [];
    }
  }
}
