/// 章鱼智学 — ExamRepository
/// 对应页面：paper_builder.html, paper_quicklook.html, answer_sheet.html, paper_history.html
/// data-db: exam.build.*, exam.preview.*, exam.quickAnswer.*, exam.getMyExams.*

class ExamBuildState {
  final String name;
  final int selectedCount;
  final int pointsCost;

  const ExamBuildState({
    required this.name,
    required this.selectedCount,
    required this.pointsCost,
  });

  factory ExamBuildState.fromJson(Map<String, dynamic> json) => ExamBuildState(
        name: json['name'] as String,
        selectedCount: json['selected_count'] as int,
        pointsCost: json['points_cost'] as int,
      );
}

class ExamPreview {
  final String name;
  final String summary;
  final int choiceCount;
  final int fillCount;
  final int solutionCount;
  final int totalCount;
  final List<ExamQuestion> questions;

  const ExamPreview({
    required this.name,
    required this.summary,
    required this.choiceCount,
    required this.fillCount,
    required this.solutionCount,
    required this.totalCount,
    required this.questions,
  });

  factory ExamPreview.fromJson(Map<String, dynamic> json) => ExamPreview(
        name: json['name'] as String,
        summary: json['summary'] as String,
        choiceCount: json['choice_count'] as int,
        fillCount: json['fill_count'] as int,
        solutionCount: json['solution_count'] as int,
        totalCount: json['total_count'] as int,
        questions: (json['questions'] as List)
            .map((e) => ExamQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ExamQuestion {
  final String title;
  final String meta;

  const ExamQuestion({required this.title, required this.meta});

  factory ExamQuestion.fromJson(Map<String, dynamic> json) => ExamQuestion(
        title: json['title'] as String,
        meta: json['meta'] as String,
      );
}

class AnswerItem {
  final String title;
  final String questionType;
  final String answer;

  const AnswerItem({
    required this.title,
    required this.questionType,
    required this.answer,
  });

  factory AnswerItem.fromJson(Map<String, dynamic> json) => AnswerItem(
        title: json['title'] as String,
        questionType: json['question_type'] as String,
        answer: json['answer'] as String,
      );
}

class ExamSummary {
  final int id;
  final String name;
  final String createdAt;
  final String summary;

  const ExamSummary({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.summary,
  });

  factory ExamSummary.fromJson(Map<String, dynamic> json) => ExamSummary(
        id: json['id'] as int,
        name: json['name'] as String,
        createdAt: json['created_at'] as String,
        summary: json['summary'] as String,
      );
}

class ExamRepository {
  /// GET /api/exams/build-session/
  static Future<ExamBuildState> buildSession() async {
    throw UnimplementedError('ExamRepository.buildSession');
  }

  /// GET /api/exams/
  static Future<List<ExamSummary>> getMyExams() async {
    throw UnimplementedError('ExamRepository.getMyExams');
  }

  /// GET /api/exams/{id}/preview/
  static Future<ExamPreview> getPreview(int id) async {
    throw UnimplementedError('ExamRepository.getPreview');
  }

  /// GET /api/exams/{id}/quick-answers/
  static Future<List<AnswerItem>> getQuickAnswers(int id) async {
    throw UnimplementedError('ExamRepository.getQuickAnswers');
  }

  /// POST /api/exams/  { name, question_ids }
  static Future<void> createExam({
    required String name,
    required List<int> questionIds,
  }) async {
    throw UnimplementedError('ExamRepository.createExam');
  }

  /// DELETE /api/exams/{id}
  static Future<void> deleteExam(int id) async {
    throw UnimplementedError('ExamRepository.deleteExam');
  }

  /// GET /api/exams/{id}/pdf/
  static Future<void> downloadPdf(int id) async {
    throw UnimplementedError('ExamRepository.downloadPdf');
  }
}
