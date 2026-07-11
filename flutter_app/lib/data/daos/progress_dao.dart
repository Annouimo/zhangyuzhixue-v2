import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;

/// 答题进度数据访问层（user 库）
class ProgressDao {
  final db.AppDatabase _db;
  const ProgressDao(this._db);

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
    return q.get();
  }

  Future<db.SubmissionDetailRow?> getLatestAttempt(int questionId) async {
    final q = _db.select(_db.submissionDetails)
      ..where((t) => t.questionId.equals(questionId));
    q.orderBy([(t) => OrderingTerm(expression: t.attemptNumber, mode: OrderingMode.desc)]);
    q.limit(1);
    final rows = await q.get();
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
    return q.get();
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
    return q.get();
  }

  Future<bool> hasAttempt(int questionId) async {
    final rows = await (_db.select(_db.submissionDetails)
      ..where((t) => t.questionId.equals(questionId))).get();
    return rows.isNotEmpty;
  }

  /// 是否有任何提交记录（判断是否有学习历史）
  Future<bool> hasAnySubmission() async {
    final rows = await _db.select(_db.submissions).get();
    return rows.isNotEmpty;
  }

  /// 获取最近 N 天内做错的题目 ID
  Future<Set<int>> getRecentWrongQuestionIds(int days) async {
    final all = await _db.select(_db.submissionDetails).get();
    final threshold = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final wrong = <int>{};
    for (final row in all) {
      if (row.isCorrect == 0 && row.createdAt.compareTo(threshold) >= 0) {
        wrong.add(row.questionId);
      }
    }
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
    return stuck;
  }

  /// 查询某题是否有评分记录
  Future<bool> hasRating(int questionId) async {
    final q = _db.select(_db.questionRatings)
      ..where((t) => t.questionId.equals(questionId));
    final row = await q.getSingleOrNull();
    return row != null;
  }
}
