import '../database/app_database.dart' as db;

/// 题目状态枚举
enum QuestionStatus { done, inProgress, undone }

/// 题目状态推算结果
class QuestionStatusResult {
  final QuestionStatus status;
  final bool shouldPrompt;
  final int? attemptNumber;

  const QuestionStatusResult({
    required this.status,
    this.shouldPrompt = false,
    this.attemptNumber,
  });
}

/// 题目状态推算工具 — 纯内存推算，不依赖 DAO/IO
///
/// 输入：从 ProgressDao 查询的提交记录行
/// 输出：QuestionStatusResult
///
/// 两种视角：
///   - calculateGlobal: 任意存档有完成记录 → 已做
///   - calculate: 限定到特定存档号，判断该存档内的状态
class QuestionStatusHelper {
  /// 存档视角：推算指定存档内的题目状态
  ///
  /// [submissionDetails] 该题的所有 submission_detail 行
  /// [questionType] 'choice' | 'fill' | 'solution'
  /// [attemptNumber] 指定存档编号，不传时取最大值（最新存档）
  static QuestionStatusResult calculate({
    required List<db.SubmissionDetailRow> submissionDetails,
    required String questionType,
    int? attemptNumber,
  }) {
    final target = attemptNumber ??
        submissionDetails.fold<int>(0, (max, s) => s.attemptNumber > max ? s.attemptNumber : max);

    final match = submissionDetails.where((s) => s.attemptNumber == target).toList();
    if (match.isEmpty) {
      return const QuestionStatusResult(status: QuestionStatus.undone);
    }

    final detail = match.first;
    if (detail.isCorrect != null) {
      return QuestionStatusResult(
        status: QuestionStatus.done,
        attemptNumber: target,
      );
    }

    if (detail.status == 'completed') {
      return QuestionStatusResult(
        status: QuestionStatus.done,
        attemptNumber: target,
      );
    }

    // 进行中：有记录但未完成
    return QuestionStatusResult(
      status: QuestionStatus.inProgress,
      shouldPrompt: questionType == 'solution',
      attemptNumber: target,
    );
  }

  /// 全局视角：推算题目的整体状态
  ///
  /// 只要任意存档中有已完成的记录即视为「已做」。
  static QuestionStatusResult calculateGlobal(
    List<db.SubmissionDetailRow> submissionDetails,
  ) {
    if (submissionDetails.isEmpty) {
      return const QuestionStatusResult(status: QuestionStatus.undone);
    }

    final hasCompleted = submissionDetails.any(
      (s) => s.isCorrect != null || s.status == 'completed',
    );
    if (hasCompleted) {
      return const QuestionStatusResult(status: QuestionStatus.done);
    }

    return const QuestionStatusResult(
      status: QuestionStatus.inProgress,
      shouldPrompt: false,
    );
  }

  /// 批量推算全局状态（供列表页使用）
  ///
  /// [groupedByQuestionId] questionId → 该题的所有 submission_detail 行
  static Map<int, QuestionStatusResult> calculateBatch(
    Map<int, List<db.SubmissionDetailRow>> groupedByQuestionId,
  ) {
    return groupedByQuestionId.map((qid, details) =>
        MapEntry(qid, calculateGlobal(details)));
  }

  /// 批量推算存档视角状态
  ///
  /// 返回 Map<"${questionId}_${attemptNumber}", status>
  static Map<String, QuestionStatusResult> calculateBatchByAttempt(
    Map<int, List<db.SubmissionDetailRow>> groupedByQuestionId,
  ) {
    final result = <String, QuestionStatusResult>{};
    for (final entry in groupedByQuestionId.entries) {
      final qid = entry.key;
      final details = entry.value;
      for (final detail in details) {
        final key = '${qid}_${detail.attemptNumber}';
        result[key] = calculate(
          submissionDetails: details,
          questionType: 'choice',
          attemptNumber: detail.attemptNumber,
        );
      }
    }
    return result;
  }
}
