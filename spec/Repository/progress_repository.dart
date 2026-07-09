/// 章鱼智学 — ProgressRepository
/// data-db: progress.*
/// 对应页面：solve.html(解题步骤)
///
/// 存档机制：
///   submission_detail 表新增 attempt_number + status 字段，
///   同一 question_id 下可有多个存档（attempt_number 从 1 递增）。
///   入口页通过 ?mode=first|resume|review&attempt_id=X 路由。

/// 单步数据
class Step {
  final int stepNumber;
  final String title;
  final String analysis;
  final List<String> cardTitles;

  const Step({
    required this.stepNumber,
    required this.title,
    required this.analysis,
    required this.cardTitles,
  });

  factory Step.fromJson(Map<String, dynamic> json) => Step(
        stepNumber: json['step_number'] as int,
        title: json['title'] as String,
        analysis: json['analysis'] as String,
        cardTitles: (json['card_titles'] as List).cast<String>(),
      );
}

/// 一个解法下的步骤组
class SolutionMethodBlock {
  final String? methodName;   // null=唯一解法
  final List<Step> steps;

  const SolutionMethodBlock({this.methodName, required this.steps});
}

/// 一个小题块
class SubQuestionBlock {
  final int index;
  final String label;
  final List<SolutionMethodBlock> solutions;

  const SubQuestionBlock({
    required this.index,
    required this.label,
    required this.solutions,
  });
}

/// 解题模式的完整状态
class SolveProgressState {
  final List<SubQuestionBlock> subQuestions;

  const SolveProgressState({required this.subQuestions});
}

// ===================================================================
//  存档（Attempt）模型
// ===================================================================

/// 存档摘要 — 对应 submission_detail 表中同一 question_id 的多条记录
class AttemptSummary {
  final int? id;               // submission_detail.id（本地自增）
  final int attemptNumber;     // 1, 2, 3...
  final String status;         // 'in_progress' | 'completed'
  final DateTime createdAt;

  const AttemptSummary({
    this.id,
    required this.attemptNumber,
    required this.status,
    required this.createdAt,
  });
}

// ===================================================================
//  复访重建
// ===================================================================

/// 步骤的历史记录
class StepSolveRecord {
  final int stepOrder;
  final bool feedbackGiven;
  final String? feedbackType; // 'correct' / 'partial' / 'wrong'

  const StepSolveRecord({
    required this.stepOrder,
    required this.feedbackGiven,
    this.feedbackType,
  });
}

/// 一种解法下的步骤历史
class MethodSolveRecord {
  final String methodName; // '' = 唯一解法
  final List<StepSolveRecord> steps;

  const MethodSolveRecord({required this.methodName, required this.steps});
}

/// 一个小问的解题历史
class SubQSolveRecord {
  final int index;
  final String activeMethod;
  final bool completed;
  final List<MethodSolveRecord> methods;

  const SubQSolveRecord({
    required this.index,
    required this.activeMethod,
    required this.completed,
    required this.methods,
  });
}

/// 完整的解题历史快照，由 ProgressRepository.getAttemptState() 返回
///
/// 数据源：submission_detail + step_feedback + card_feedback + question_rating
/// attemptNumber 决定查询哪条 submission_detail。
class PreviousSolveState {
  final int attemptNumber;        // 该状态所属的存档编号

  // === 选择题 ===
  final String? choiceSelected;
  final bool choiceSubmitted;

  // === 填空题 ===
  final bool fillRevealed;

  // === 解答题 ===
  final List<SubQSolveRecord> subQRecords;

  // === 评分 ===
  final bool isRated;

  const PreviousSolveState({
    required this.attemptNumber,
    this.choiceSelected,
    required this.choiceSubmitted,
    required this.fillRevealed,
    required this.subQRecords,
    required this.isRated,
  });
}

class ProgressRepository {
  /// GET /api/questions/{questionId}/solve-state/
  static Future<SolveProgressState> getSolveState(int questionId) async {
    throw UnimplementedError('ProgressRepository.getSolveState');
  }

  /// 获取某一题的所有存档列表
  /// 查询 user.db: SELECT * FROM submission_detail WHERE question_id=? ORDER BY attempt_number
  static Future<List<AttemptSummary>> getAttempts(int questionId) async {
    throw UnimplementedError('ProgressRepository.getAttempts');
  }

  /// 创建新存档，返回 attempt_number
  /// 插入 user.db: INSERT INTO submission_detail (question_id, attempt_number, status) VALUES (?, ?, 'in_progress')
  static Future<int> createAttempt(int questionId) async {
    throw UnimplementedError('ProgressRepository.createAttempt');
  }

  /// 查询指定存档的解题状态
  /// 返回 null 表示该存档不存在。
  static Future<PreviousSolveState?> getAttemptState(
    int questionId,
    int attemptNumber,
  ) async {
    throw UnimplementedError('ProgressRepository.getAttemptState');
  }

static Future<void> submitStepFeedback({
    required int questionId,
    required int attemptNumber,
    required int stepNumber,
    required String status,
  }) async {
    throw UnimplementedError('ProgressRepository.submitStepFeedback');
  }
}
