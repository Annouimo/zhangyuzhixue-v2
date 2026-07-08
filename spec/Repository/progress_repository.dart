/// 章鱼智学 — ProgressRepository
/// data-db: progress.*
/// 对应页面：solve.html(解题步骤)

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
}
