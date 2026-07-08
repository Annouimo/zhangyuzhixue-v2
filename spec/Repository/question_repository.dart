/// 章鱼智学 — QuestionRepository
/// data-db: question.*
/// 对应页面：solve.html(题干), paper_quicklook.html(做题), paper_quicklook_other.html(做题)

class QuestionDetail {
  final int id;
  final String title;
  final String number;
  final String assignName;
  final String stem;
  final List<String> images;  // ← 新增：相对路径列表，如 ['一模/2024/海淀/q17.webp']
  final double difficulty;
  final double pointsEarned;
  final List<String> conceptTags;
  final String congratsText;

  const QuestionDetail({
    required this.id,
    required this.title,
    required this.number,
    required this.assignName,
    required this.stem,
    this.images = const [],  // ← 新增，默认空
    required this.difficulty,
    required this.pointsEarned,
    required this.conceptTags,
    required this.congratsText,
  });

  factory QuestionDetail.fromJson(Map<String, dynamic> json) => QuestionDetail(
        id: json['id'] as int,
        title: json['title'] as String,
        number: json['number'] as String,
        assignName: json['assign_name'] as String,
        stem: json['stem'] as String,
        images: (json['images'] as List?)?.cast<String>() ?? [],  // ← 新增
        difficulty: (json['difficulty'] as num).toDouble(),
        pointsEarned: (json['points_earned'] as num).toDouble(),
        conceptTags: (json['concept_tags'] as List).cast<String>(),
        congratsText: json['congrats_text'] as String,
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
