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
// 智能推荐算法，getSmartList() 委托给此类。
// 所有计算在本地 drift 完成，不依赖服务器。
//
// ┌─ 冷启动 ─────────────────────────────────────────────────────┐
// │ answer_records 总数 < 5 时 → getSmartList() 返回 []         │
// │ 推荐页仅展示 "预设/偏好推荐" 区域                             │
// └──────────────────────────────────────────────────────────────┘
//
// ┌─ 路线A：选/填空题 — 概念掌握度 ───────────────────────────────┐
// │ 数据源：answer_records (questionId, isCorrect, answeredAt)   │
// │                                                              │
// │ 时间衰减：7 天半衰期                                         │
// │   λ = ln(2) / 7 ≈ 0.099                                      │
// │   权重 = e^(-0.099 × 距离今天天数)                            │
// │   今天做=1.0 / 7天前=0.5 / 14天前=0.25 / 30天前=0.05        │
// │                                                              │
// │ 原始掌握度 = Σ(权重 × 是否正确) / Σ(权重)                    │
// │   做对=1 / 做错=0 (选填只有对/错)                             │
// │                                                              │
// │ 小样本收缩 (minConfidence = 5)：                             │
// │   收缩系数 = max(0, 1 - 做题量 / 5)                          │
// │   有效掌握度 = 原始× (1-收缩系数) + 0.5 × 收缩系数           │
// │   → 做题量 < 5 时向 50% 收缩，避免小样本噪音                  │
// │                                                              │
// │ 选材：                                                       │
// │   取有效掌握度最低的 1 个 concept_tag                         │
// │   目标难度 = 该概念历史做对题目的平均难度 + 0.5                │
// │   choice: 选薄弱程度降序, 最多 2 道                           │
// │   fill:   同上, 最多 2 道                                     │
// │   exclude: 已做对 + 3 天内刚做错的                            │
// └──────────────────────────────────────────────────────────────┘
//
// ┌─ 路线B：解答题 — 知识卡片卡住率 ───────────────────────────────┐
// │ 数据链路：step_feedback(questionId, stepNumber, status)       │
// │   → 反查 questions_steps → Step.cardTitles                    │
// │                                                              │
// │ 卡住权重：correct=0 / partial=0.5 / wrong=1                  │
// │                                                              │
// │ 卡住率 = 权重总和 / 该卡片在整个题库中出现的总步数            │
// │   范围 0.0~1.0，越高越弱                                      │
// │                                                              │
// │ 小样本收缩 (同路线A)：出现 < 5 次时向 50% 收缩               │
// │                                                              │
// │ 选材：                                                       │
// │   取有效卡住率最高的 1 个知识卡片                              │
// │   solution: 选薄弱程度降序, 最多 2 道                         │
// │   exclude: 同上 (已做对 + 3 天内刚做错的)                     │
// └──────────────────────────────────────────────────────────────┘
//
// ┌─ 合并与排序 ─────────────────────────────────────────────────┐
// │ 最终列表顺序：                                               │
// │   [0] choice 最薄弱道 — [1] choice 次薄弱道                  │
// │   [2] fill   最薄弱道 — [3] fill   次薄弱道                  │
// │   [4] solution 最薄弱道 — [5] solution 次薄弱道              │
// │                                                              │
// │ 不足时不补其他题型，不强凑 6 道                               │
// │ 内部排序 = 薄弱程度降序                                       │
// └──────────────────────────────────────────────────────────────┘
//
// ┌─ 推荐理由 (RecommendedQuestion.recommendReason) ────────────┐
// │ 选/填空题 → concept_tag 名称 (如 "三角函数")                  │
// │ 解答题    → 知识卡片标题 (如 "正弦定理在三角形面积中的应用")   │
// └──────────────────────────────────────────────────────────────┘
class _RecommendationEngine {
  // 配置常量
  static const int coldStartThreshold = 5;
  static const double decayLambda = 0.099; // ln(2)/7，7天半衰期
  static const int minConfidence = 5;
  static const int wrongRetryDays = 3;
  static const double challengeOffset = 0.5; // 目标难度 = 做对平均难度 + 0.5
  static const int maxChoice = 2;
  static const int maxFill = 2;
  static const int maxSolution = 2;

  // 入口：执行完整推荐流程
  // 1. 冷启动检查 (answer_records.count < 5 → return [])
  // 2. 路线A：计算概念掌握度 → 最弱 concept_tag → 匹配 choice/fill
  // 3. 路线B：计算卡片卡住率 → 最弱知识卡片 → 匹配 solution
  // 4. 合并排序 → [choice×2, fill×2, solution×2]
  //
  // 实现时需要的 DAO 接口：
  //   getAnswerRecords() → List<{questionId, isCorrect, answeredAt, conceptTag, questionType}>
  //   getStepFeedback() → List<{questionId, stepNumber, status}>
  //   getStepCards(questionId, stepNumber) → List<String> cardTitles
  //   searchQuestions(filter) → List<Question>
  //   getDoneQuestionIds() → Set<int>
  //   getRecentWrongIds(days) → Set<int>
}
