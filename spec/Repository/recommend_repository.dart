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
// ⚠️ 极简 v1 方案，与同事讨论后替换为正式方案。
// 替换时只需重写 _RecommendationEngine 类，外部模块不受影响。
//
// v1 方案（极简，能用就行）：
//   1. 读取用户最近 50 条答题记录
//   2. 选填题：按 concept_tag 统计正确率，取正确率最低的 3 个 tag
//   3. 解答题：按知识卡片卡住率（已揭示步数/总步数）降序，取卡住率最高的 3 个卡片
//   4. 从 assets.db 随机选取 10 道覆盖上述薄弱 tag/卡片的题目
//   5. 排除已做题（question_id NOT IN 已做列表）
//   6. 按 difficulty 升序排列
//   7. recommendReason = "在『{tag}』上正确率偏低" 或 "『{card}』还需多练"
//
// 已知缺点（正式方案需解决）：
//   - 不区分最近权重（所有记录等权重）
//   - 不做难度匹配（不一定推荐与用户水平匹配的难度）
//   - Cold Start 直接降级为偏好推荐（<5 条记录时不走此引擎）
//   - 推荐原因只取第一个薄弱项，不组合多个
class _RecommendationEngine {
}
