/// 章鱼智学 — QuestionRepository
/// data-db: question.*
/// 对应页面：solve.html(题干), paper_quicklook.html(做题), paper_quicklook_other.html(做题)

class QuestionDetail {
  final int id;
  final String title;
  final String number;
  final String assignName;
  final String stem;
  final List<String> images;
  final double difficulty;
  final double pointsEarned;
  final List<String> conceptTags;
  final String congratsText;
  final String questionType;               // "选择" / "填空" / "解答"
  final Map<String, String>? options;      // 仅选择题: {"A":"x>1", "B":"x<1", ...}
  final String? answer;                    // 标准答案（选填题展示用）

  const QuestionDetail({
    required this.id,
    required this.title,
    required this.number,
    required this.assignName,
    required this.stem,
    this.images = const [],
    required this.difficulty,
    required this.pointsEarned,
    required this.conceptTags,
    required this.congratsText,
    required this.questionType,
    this.options,
    this.answer,
  });

  factory QuestionDetail.fromJson(Map<String, dynamic> json) => QuestionDetail(
        id: json['id'] as int,
        title: json['title'] as String,
        number: json['number'] as String,
        assignName: json['assign_name'] as String,
        stem: json['stem'] as String,
        images: (json['images'] as List?)?.cast<String>() ?? [],
        difficulty: (json['difficulty'] as num).toDouble(),
        pointsEarned: (json['points_earned'] as num).toDouble(),
        conceptTags: (json['concept_tags'] as List).cast<String>(),
        congratsText: json['congrats_text'] as String,
        questionType: json['question_type'] as String,
        options: json['options'] != null
            ? Map<String, String>.from(json['options'] as Map)
            : null,
        answer: json['answer'] as String?,
      );
}

class QuestionRepository {
  /// GET /api/questions/{id}/
  static Future<QuestionDetail> getDetail(int id) async {
    throw UnimplementedError('QuestionRepository.getDetail');
  }

  /// POST /api/questions/{id}/start-solve/
  static Future<void> startSolve(int questionId) async {
    throw UnimplementedError('QuestionRepository.startSolve');
  }

  /// GET /api/questions/{id}/next/
  static Future<int?> nextQuestion(int currentId) async {
    throw UnimplementedError('QuestionRepository.nextQuestion');
  }
}
