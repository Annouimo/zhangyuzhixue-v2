/// 章鱼智学 — QuestionStatusHelper
///
/// 题目状态推算工具，供 AssignmentRepository、RecommendRepository、
/// ExamRepository、ProgressRepository 等多个 Repository 复用。
///
/// ====== 两种视角 ======
///
/// 全局视角（calculateGlobal）：
///   不考虑存档归属，判断题目是否被做过。用于筛选、统计、列表展示。
///
///   | 状态 | 判断条件 |
///   |------|----------|
///   | 已做 | 任意存档中存在已完成的 submission_detail |
///   | 未做 | 所有存档中均无 submission_detail |
///
/// 存档视角（calculate）：
///   限定到特定 attempt_number，判断该存档内的状态。用于解题页入口路由。
///
///   | 状态 | 判断条件 |
///   |------|----------|
///   | 进行中 | 该存档有 submission_detail 但 is_correct 为 NULL |
///   |       | 或：有 step_feedback 但未完成所有步骤 |
///   | 已完成 | 该存档所有 submission_detail.is_correct 不为 NULL |
///
/// 多存档场景（入口页路由，useCases 见 solving-architecture skill）：
///   - 0 个存档 → mode=first
///   - 最新存档进行中 → mode=resume
///   - ≥1 个已完成存档 → mode=review / 存档选择器

import 'dart:collection';

/// 题目状态枚举
enum QuestionStatus { done, inProgress, undone }

/// 题目状态推算结果
class QuestionStatusResult {
  /// 当前状态
  final QuestionStatus status;

  /// 是否需要弹窗提示（进行中状态首次进入解答题时）
  final bool shouldPrompt;

  /// 存档编号（仅存档视角时有值）
  final int? attemptNumber;

  const QuestionStatusResult({
    required this.status,
    this.shouldPrompt = false,
    this.attemptNumber,
  });
}

/// 状态推算器
///
/// 输入：从 user.db 查询的提交记录数据（纯 List/Map，不依赖 DAO）
/// 输出：QuestionStatusResult
///
/// 使用方示例：
/// ```dart
/// // 全局视角：判断题目是否已被做过
/// final result = QuestionStatusHelper.calculateGlobal(submissions);
/// if (result.status == QuestionStatus.undone) { ... }
///
/// // 存档视角：判断第 2 次作答的状态
/// final result = QuestionStatusHelper.calculate(
///   submissions, stepFeedbacks, 'solution',
///   attemptNumber: 2,
/// );
/// ```
class QuestionStatusHelper {
  /// 存档视角：推算指定存档内的题目状态
  ///
  /// [submissionDetails] 该题的所有 submission_detail 行（来自 user.db）
  ///   - attempt_number = 存档编号
  ///   - is_correct != NULL = 已提交答案
  /// [stepFeedbacks] 该题的最后一步 step_feedback（仅解答题有）
  /// [questionType] 'choice' | 'fill' | 'solution'
  /// [attemptNumber] 指定存档编号，不传时取最大值（最新存档）
  static QuestionStatusResult calculate({
    required List<Map<String, dynamic>> submissionDetails,
    required List<Map<String, dynamic>> stepFeedbacks,
    required String questionType,
    int? attemptNumber,
  }) {
    throw UnimplementedError('QuestionStatusHelper.calculate');
  }

  /// 全局视角：推算题目的整体状态（不考虑存档）
  ///
  /// 用于列表页、统计页等不需要区分存档的场景。
  /// 只要任意存档中存在已完成的 submission_detail 即视为「已做」。
  static QuestionStatusResult calculateGlobal(
    List<Map<String, dynamic>> submissionDetails,
  ) {
    throw UnimplementedError('QuestionStatusHelper.calculateGlobal');
  }

  /// 批量推算全局状态（供列表页使用，合并 SQL 查询减少 IO）
  ///
  /// [questionIds] 需要推算状态的题目 ID 列表
  /// 返回 Map<questionId, QuestionStatusResult>
  static Future<Map<int, QuestionStatusResult>> calculateBatch(
    List<int> questionIds,
  ) async {
    throw UnimplementedError('QuestionStatusHelper.calculateBatch');
  }

  /// 批量推算存档视角状态（供解题页入口路由使用）
  ///
  /// 返回 Map<(questionId, attemptNumber), QuestionStatusResult>
  static Future<Map<String, QuestionStatusResult>> calculateBatchByAttempt(
    List<int> questionIds,
  ) async {
    throw UnimplementedError('QuestionStatusHelper.calculateBatchByAttempt');
  }
}
