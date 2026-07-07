/// 章鱼智学 — ProgressRepository
/// data-db: progress.*
/// 对应页面：solve.html(解题步骤)

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

class ProgressRepository {
  /// GET /api/questions/{questionId}/steps/
  static Future<List<Step>> getSteps(int questionId) async {
    throw UnimplementedError('ProgressRepository.getSteps');
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
