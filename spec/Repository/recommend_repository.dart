/// 章鱼智学 — RecommendRepository
/// data-db: recommend.*
/// 对应页面：recommend.html

class RecommendedQuestion {
  final int id;
  final String title;
  final String questionType;
  final double difficulty;
  final String recommendReason;
  final String status;

  const RecommendedQuestion({
    required this.id,
    required this.title,
    required this.questionType,
    required this.difficulty,
    required this.recommendReason,
    required this.status,
  });

  factory RecommendedQuestion.fromJson(Map<String, dynamic> json) =>
      RecommendedQuestion(
        id: json['id'] as int,
        title: json['title'] as String,
        questionType: json['question_type'] as String,
        difficulty: (json['difficulty'] as num).toDouble(),
        recommendReason: json['recommend_reason'] as String? ?? '',
        status: json['status'] as String,
      );
}

class RecommendPreset {
  final int id;
  final String name;

  const RecommendPreset({required this.id, required this.name});

  factory RecommendPreset.fromJson(Map<String, dynamic> json) =>
      RecommendPreset(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}

class PresetQuestion {
  final int id;
  final String title;
  final String questionType;
  final double difficulty;
  final String status;

  const PresetQuestion({
    required this.id,
    required this.title,
    required this.questionType,
    required this.difficulty,
    required this.status,
  });

  factory PresetQuestion.fromJson(Map<String, dynamic> json) => PresetQuestion(
        id: json['id'] as int,
        title: json['title'] as String,
        questionType: json['question_type'] as String,
        difficulty: (json['difficulty'] as num).toDouble(),
        status: json['status'] as String,
      );
}

class RecommendRepository {
  /// GET /api/recommend/smart/
  static Future<List<RecommendedQuestion>> getSmartList() async {
    throw UnimplementedError('RecommendRepository.getSmartList');
  }

  /// GET /api/recommend/presets/
  static Future<List<RecommendPreset>> getPresets() async {
    throw UnimplementedError('RecommendRepository.getPresets');
  }

  /// GET /api/recommend/presets/{id}/questions/
  static Future<List<PresetQuestion>> getPresetQuestions(int presetId) async {
    throw UnimplementedError('RecommendRepository.getPresetQuestions');
  }
}

// ---- 推荐算法引擎 ----
// 从答题记录分析薄弱项 → 从本地题库推荐题目
// 选填题：按 concept_tag 统计正确率，取最低的作为推荐原因
// 解答题：按知识卡片反向查 Step.cardTitles，取卡住率高的作为推荐原因
class _RecommendationEngine {
  // 1. 读取用户答题记录（最近 N 条）
  // 2. 选填题：按 concept_tag 统计正确率，排序取最低
  // 3. 解答题：按知识卡片卡住率（已揭示步数/总步数），反向查 Step.cardTitles
  // 4. 从本地题库选取覆盖薄弱项的题目
  // 5. 按 difficulty 排序 + 去重已做题
}
