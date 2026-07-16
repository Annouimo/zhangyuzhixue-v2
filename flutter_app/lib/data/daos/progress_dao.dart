import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;
import '../database/database_provider.dart';
import 'package:shared/debug/audit_logger.dart';

/// 答题进度数据访问层（user 库）
class ProgressDao {
  final DatabaseProvider _provider;
  ProgressDao(this._provider);
  db.AppDatabase get _db => _provider.appDb;

  Future<int> createSubmission({
    required int studentId,
    int? assignmentId,
  }) async {
    final now = DateTime.now().toIso8601String();
    return _db.into(_db.submissions).insert(db.SubmissionsCompanion(
      studentId: Value(studentId),
      assignmentId: Value(assignmentId),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  Future<List<db.SubmissionDetailRow>> getAttempts(int questionId) async {
    final q = _db.select(_db.submissionDetails)
      ..where((t) => t.questionId.equals(questionId));
    q.orderBy([(t) => OrderingTerm(expression: t.attemptNumber)]);
    final rows = await q.get();
    AuditLogger.instance.dao('ProgressDao.getAttempts', rows.length, {'questionId': questionId});
    return rows;
  }

  Future<db.SubmissionDetailRow?> getLatestAttempt(int questionId) async {
    final q = _db.select(_db.submissionDetails)
      ..where((t) => t.questionId.equals(questionId));
    q.orderBy([(t) => OrderingTerm(expression: t.attemptNumber, mode: OrderingMode.desc)]);
    q.limit(1);
    final rows = await q.get();
    AuditLogger.instance.dao('ProgressDao.getLatestAttempt', rows.isNotEmpty ? 1 : 0, {'questionId': questionId});
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> createAttempt({
    required int questionId,
    int? submissionId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final existing = await (_db.select(_db.submissionDetails)
      ..where((t) => t.questionId.equals(questionId))).get();
    final attemptNumber = existing.isEmpty
        ? 1
        : existing.map((e) => e.attemptNumber).reduce((a, b) => a > b ? a : b) + 1;
    return _db.into(_db.submissionDetails).insert(db.SubmissionDetailsCompanion(
      submissionId: Value(submissionId),
      questionId: Value(questionId),
      attemptNumber: Value(attemptNumber),
      status: Value('in_progress'),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  Future<void> updateAttemptStatus(int id, String status) async {
    final now = DateTime.now().toIso8601String();
    final q = _db.update(_db.submissionDetails)..where((t) => t.id.equals(id));
    await q.write(db.SubmissionDetailsCompanion(
      status: Value(status),
      updatedAt: Value(now),
    ));
  }

  Future<void> updateAttemptAnswer(int id, String answerText, int isCorrect) async {
    final now = DateTime.now().toIso8601String();
    final q = _db.update(_db.submissionDetails)..where((t) => t.id.equals(id));
    await q.write(db.SubmissionDetailsCompanion(
      answerText: Value(answerText),
      isCorrect: Value(isCorrect),
      status: Value('completed'),
      updatedAt: Value(now),
    ));
  }

  Future<int> insertStepFeedback({
    required int submissionDetailId,
    required int questionId,
    int? subQuestionIndex,
    int? methodId,
    required int stepNumber,
    required String status,
  }) async {
    final now = DateTime.now().toIso8601String();
    return _db.into(_db.stepFeedbacks).insert(db.StepFeedbacksCompanion(
      submissionDetailId: Value(submissionDetailId),
      questionId: Value(questionId),
      subQuestionIndex: Value(subQuestionIndex),
      methodId: Value(methodId),
      stepNumber: Value(stepNumber),
      status: Value(status),
      createdAt: Value(now),
    ));
  }

  Future<List<db.StepFeedbackRow>> getStepFeedbacks(int submissionDetailId) async {
    final q = _db.select(_db.stepFeedbacks)
      ..where((t) => t.submissionDetailId.equals(submissionDetailId));
    q.orderBy([(t) => OrderingTerm(expression: t.stepNumber)]);
    final rows = await q.get();
    AuditLogger.instance.dao('ProgressDao.getStepFeedbacks', rows.length, {'submissionDetailId': submissionDetailId});
    return rows;
  }

  Future<int> insertCardFeedback({
    required int submissionDetailId,
    required int questionId,
    required String cardTitle,
    required String cardStatus,
  }) async {
    final now = DateTime.now().toIso8601String();
    return _db.into(_db.cardFeedbacks).insert(db.CardFeedbacksCompanion(
      submissionDetailId: Value(submissionDetailId),
      questionId: Value(questionId),
      cardTitle: Value(cardTitle),
      cardStatus: Value(cardStatus),
      createdAt: Value(now),
    ));
  }

  Future<List<db.CardFeedbackRow>> getCardFeedbacks(int submissionDetailId) async {
    final q = _db.select(_db.cardFeedbacks)
      ..where((t) => t.submissionDetailId.equals(submissionDetailId));
    final rows = await q.get();
    AuditLogger.instance.dao('ProgressDao.getCardFeedbacks', rows.length, {'submissionDetailId': submissionDetailId});
    return rows;
  }

  Future<bool> hasAttempt(int questionId) async {
    final result = await (_db.select(_db.submissionDetails)
      ..where((t) => t.questionId.equals(questionId))).get();
    AuditLogger.instance.dao('ProgressDao.hasAttempt', result.length, {'questionId': questionId});
    return result.isNotEmpty;
  }

  /// 一次读取全部 submission_details，按 questionId 分组
  Future<List<db.SubmissionDetailRow>> getAllAttempts() async {
    final rows = await _db.select(_db.submissionDetails).get();
    AuditLogger.instance.dao('ProgressDao.getAllAttempts', rows.length, {});
    return rows;
  }

  /// 批量查询哪些题目有做题记录 — 替代 N+1 的逐条 hasAttempt
  Future<Set<int>> getAttemptedQuestionIds() async {
    final rows = await _db.select(_db.submissionDetails).get();
    final ids = rows.map((r) => r.questionId).toSet();
    AuditLogger.instance.dao('ProgressDao.getAttemptedQuestionIds', ids.length, {});
    return ids;
  }

  /// 批量查询已完成的题目 ID（is_correct IS NOT NULL，含答对和答错）
  Future<Set<int>> getCompletedQuestionIds() async {
    final q = _db.select(_db.submissionDetails)
      ..where((t) => t.isCorrect.isNotNull());
    final rows = await q.get();
    final ids = rows.map((r) => r.questionId).toSet();
    AuditLogger.instance.dao('ProgressDao.getCompletedQuestionIds', ids.length, {});
    return ids;
  }

  /// 是否有任何提交记录（判断是否有学习历史）
  Future<bool> hasAnySubmission() async {
    final rows = await _db.select(_db.submissions).get();
    AuditLogger.instance.dao('ProgressDao.hasAnySubmission', rows.length, {});
    return rows.isNotEmpty;
  }

  /// 获取最近 N 天内做错的题目 ID
  Future<Set<int>> getRecentWrongQuestionIds(int days) async {
    final threshold = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final q = _db.select(_db.submissionDetails)
      ..where((t) => t.isCorrect.equals(0))
      ..where((t) => t.createdAt.isBiggerThanValue(threshold));
    final rows = await q.get();
    final wrong = rows.map((r) => r.questionId).toSet();
    AuditLogger.instance.dao('ProgressDao.getRecentWrongQuestionIds', wrong.length, {'days': days});
    return wrong;
  }

  /// 获取某道题的 step_feedback 中被卡住的步数
  Future<int> getStuckStepCount(int questionId) async {
    final attempts = await getAttempts(questionId);
    var stuck = 0;
    for (final a in attempts) {
      final steps = await getStepFeedbacks(a.id);
      for (final s in steps) {
        if (s.status == 'stuck' || s.status == 'wrong') stuck++;
      }
    }
    AuditLogger.instance.dao('ProgressDao.getStuckStepCount', stuck, {'questionId': questionId});
    return stuck;
  }

  /// 查询某题是否有评分记录
  Future<bool> hasRating(int questionId) async {
    final q = _db.select(_db.questionRatings)
      ..where((t) => t.questionId.equals(questionId));
    final row = await q.getSingleOrNull();
    AuditLogger.instance.dao('ProgressDao.hasRating', row != null ? 1 : 0, {'questionId': questionId});
    return row != null;
  }
}
