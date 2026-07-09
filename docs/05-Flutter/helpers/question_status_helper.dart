/// 章鱼智学 — QuestionStatusHelper
///
/// 题目状态推算工具，供 AssignmentRepository、RecommendRepository、
/// ExamRepository 等多个 Repository 复用。
///
/// 题目有三种状态，全部通过查询 user.db 的提交记录动态推算：
///
/// | 状态 | 判断条件 |
/// |------|----------|
/// | 已做 | 选填：submission_detail.is_correct 有值 |
/// |     | 解答：最后一步的 step_feedback 已存在 |
/// | 进行中 | 有 submission_detail 但 is_correct 为 NULL |
/// |       | 或：有 step_feedback 但未完成所有步骤 |
/// | 未做 | submission_detail 中无该 question_id |
///
/// 所有方法为同步纯计算，不涉及 IO。

/// 题目状态枚举
enum QuestionStatus { done, inProgress, undone }

/// 题目状态推算结果
class QuestionStatusResult {
  /// 当前状态
  final QuestionStatus status;

  /// 是否需要弹窗提示（进行中状态首次进入解答题时）
  final bool shouldPrompt;

  const QuestionStatusResult({
    required this.status,
    this.shouldPrompt = false,
  });
}

/// 状态推算器
///
/// 输入：从 user.db 查询的提交记录数据（纯 List/Map，不依赖 DAO）
/// 输出：QuestionStatusResult
///
/// 使用方示例：
/// ```dart
/// final submissions = await SubmissionDao.getByQuestionId(qid);
/// final result = QuestionStatusHelper.calculate(submissions, questionType);
/// ```
class QuestionStatusHelper {
  /// 推算单题状态
  ///
  /// [submissionDetails] 该题的所有 submission_detail 行（来自 user.db）
  /// [stepFeedbacks] 该题的最后一步 step_feedback（仅解答题有）
  /// [questionType] 'choice' | 'fill' | 'solution'
  static QuestionStatusResult calculate({
    required List<Map<String, dynamic>> submissionDetails,
    required List<Map<String, dynamic>> stepFeedbacks,
    required String questionType,
  }) {
    throw UnimplementedError('QuestionStatusHelper.calculate');
  }

  /// 批量推算（供列表页使用，合并 SQL 查询减少 IO）
  ///
  /// [questionIds] 需要推算状态的题目 ID 列表
  /// 返回 Map<questionId, QuestionStatusResult>
  static Future<Map<int, QuestionStatusResult>> calculateBatch(
    List<int> questionIds, {
    String? questionType,
  }) async {
    throw UnimplementedError('QuestionStatusHelper.calculateBatch');
  }
}
