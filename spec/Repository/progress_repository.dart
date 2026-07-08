/// 章鱼智学 — ProgressRepository
/// data-db: progress.*
/// 对应页面：solve.html(解题步骤)
///
/// SubQuestionBlock.index / label 推导规则（从 sub_question 自关联树 → 平铺序号）：
/// 1. 取 question_id 下所有 parent_id IS NULL 的行，ORDER BY sort_order
/// 2. index = 行号（1, 2, 3...），整题无小题时 index=0
/// 3. label = "(index)"，如 "(1)"、"(2)"；index=0 时 label=""
/// 4. 如果某行有 children（parent_id = 本行 id），递归，label 追加如 "(2)(i)"
/// 5. 最终组装为 List<SubQuestionBlock>

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
  final String? methodName;   // null=唯一解法（不显示切换）；"代数法"/"几何法"等
  final List<Step> steps;

  const SolutionMethodBlock({
    this.methodName,
    required this.steps,
  });
}

/// 一个小题块（index=0 表示整题无小题）
class SubQuestionBlock {
  final int index;                        // 0=整题, 1/2/3=小题序号
  final String label;                     // "" / "(1)" / "(2)" / "(3)"
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

  const SolveProgressState({
    required this.subQuestions,
  });
}

// ===================================================================
//  复访重建（第二次及更多次进入解题页时，从 user.db 重建状态）
//  数据源：submission_detail, step_feedback, card_feedback, question_rating
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

  const MethodSolveRecord({
    required this.methodName,
    required this.steps,
  });
}

/// 一个小问的解题历史
class SubQSolveRecord {
  final int index;
  final String activeMethod; // 上次离开时选中的解法
  final bool completed;      // 该小问已用至少一种方法完成
  final List<MethodSolveRecord> methods;

  const SubQSolveRecord({
    required this.index,
    required this.activeMethod,
    required this.completed,
    required this.methods,
  });
}

/// 完整的解题历史快照，由 ProgressRepository.getPreviousState() 返回
///
/// 根据 submission_detail / step_feedback / question_rating 重建。
/// null = 首次进入（表中无该 question_id 的记录）。
class PreviousSolveState {
  // === 选择题 ===
  final String? choiceSelected;   // 用户选的选项；null=未选即离开
  final bool choiceSubmitted;     // 是否已提交

  // === 填空题 ===
  final bool fillRevealed;        // 是否已展示答案

  // === 解答题 ===
  final List<SubQSolveRecord> subQRecords;

  // === 评分 ===
  final bool isRated;             // 是否已评分

  const PreviousSolveState({
    this.choiceSelected,
    required this.choiceSubmitted,
    required this.fillRevealed,
    required this.subQRecords,
    required this.isRated,
  });
}

class ProgressRepository {
  /// GET /api/questions/{questionId}/solve-state/
  /// 返回分组后的解题状态（含小问分组 + 解法分组）
  static Future<SolveProgressState> getSolveState(int questionId) async {
    throw UnimplementedError('ProgressRepository.getSolveState');
  }

  /// POST /api/progress/step-feedback/
  static Future<void> submitStepFeedback({
    required int questionId,
    required int stepNumber,
    required String status,
  }) async {
    throw UnimplementedError('ProgressRepository.submitStepFeedback');
  }

  /// 查询 user.db 中该 question_id 的所有相关记录，重建解题状态。
  ///
  /// 查询路径：
  ///   submission_detail → choiceSelected / choiceSubmitted / fillRevealed
  ///   step_feedback     → 每步的 feedbackGiven + feedbackType
  ///   question_rating   → isRated
  ///
  /// 返回 null 表示首次进入（无任何记录）。
  ///
  /// Flutter 实现参考：
  ///   1. SELECT * FROM submission_detail WHERE question_id=?
  ///   2. SELECT * FROM step_feedback WHERE question_id=? ORDER BY sub_question_index, method_id, step_number
  ///   3. SELECT 1 FROM question_rating WHERE question_id=? LIMIT 1
  ///   4. 组装为 PreviousSolveState
  static Future<PreviousSolveState?> getPreviousState(int questionId) async {
    throw UnimplementedError('ProgressRepository.getPreviousState');
  }
}
