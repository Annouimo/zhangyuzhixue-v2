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
    final rows = await _db.customSelect(
      'SELECT * FROM submission_details WHERE question_id = ? ORDER BY attempt_number',
      variables: [Variable(questionId)],
      readsFrom: {_db.submissionDetails},
    ).get();
    return rows.map((r) => _db.submissionDetails.map(r.data)).toList();
  }

  Future<db.SubmissionDetailRow?> getLatestAttempt(int questionId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM submission_details WHERE question_id = ? ORDER BY attempt_number DESC LIMIT 1',
      variables: [Variable(questionId)],
      readsFrom: {_db.submissionDetails},
    ).get();
    if (rows.isEmpty) return null;
    return _db.submissionDetails.map(rows.first.data);
  }

  Future<int> createAttempt({
    required int questionId,
    int? submissionId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final row = await _db.customSelect(
      'SELECT COALESCE(MAX(attempt_number), 0) AS max_n FROM submission_details WHERE question_id = ?',
      variables: [Variable(questionId)],
      readsFrom: {_db.submissionDetails},
    ).getSingle();
    final attemptNumber = row.read<int>('max_n')! + 1;
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
    final q = _db.update(_db.submissionDetails);
    q.where((t) => t.id.equals(id));
    await q.write(db.SubmissionDetailsCompanion(
      status: Value(status),
      updatedAt: Value(now),
    ));
  }

  Future<void> updateAttemptAnswer(int id, String answerText, int isCorrect) async {
    final now = DateTime.now().toIso8601String();
    final q = _db.update(_db.submissionDetails);
    q.where((t) => t.id.equals(id));
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
    final rows = await _db.customSelect(
      'SELECT * FROM step_feedbacks WHERE submission_detail_id = ? ORDER BY step_number',
      variables: [Variable(submissionDetailId)],
      readsFrom: {_db.stepFeedbacks},
    ).get();
    return rows.map((r) => _db.stepFeedbacks.map(r.data)).toList();
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
    final rows = await _db.customSelect(
      'SELECT * FROM card_feedbacks WHERE submission_detail_id = ?',
      variables: [Variable(submissionDetailId)],
      readsFrom: {_db.cardFeedbacks},
    ).get();
    return rows.map((r) => _db.cardFeedbacks.map(r.data)).toList();
  }

  Future<bool> hasAttempt(int questionId) async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM submission_details WHERE question_id = ?',
      variables: [Variable(questionId)],
      readsFrom: {_db.submissionDetails},
    ).getSingle();
    return row.read<int>('c')! > 0;
  }
}
