/// 章鱼智学 — ExamRepository
/// data-db: exam.*
/// 对应页面：paper_auto.html, paper_pick.html, paper_quicklook.html,
///          paper_quicklook_other.html, paper_explore.html, paper_favorites.html,
///          paper_history.html, answer_sheet.html

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

class ExploreExamSummary {
  final int id;
  final String name;
  final String authorInfo;
  final String summary;
  final int likeCount;
  final int collectCount;
  final String createdAt;

  const ExploreExamSummary({
    required this.id,
    required this.name,
    required this.authorInfo,
    required this.summary,
    required this.likeCount,
    required this.collectCount,
    required this.createdAt,
  });

  factory ExploreExamSummary.fromJson(Map<String, dynamic> json) =>
      ExploreExamSummary(
        id: json['id'] as int,
        name: json['name'] as String,
        authorInfo: json['author_info'] as String,
        summary: json['summary'] as String,
        likeCount: json['like_count'] as int,
        collectCount: json['collect_count'] as int,
        createdAt: json['created_at'] as String,
      );
}

class FavoriteExamSummary {
  final int id;
  final String name;
  final String authorInfo;
  final String summary;

  const FavoriteExamSummary({
    required this.id,
    required this.name,
    required this.authorInfo,
    required this.summary,
  });

  factory FavoriteExamSummary.fromJson(Map<String, dynamic> json) =>
      FavoriteExamSummary(
        id: json['id'] as int,
        name: json['name'] as String,
        authorInfo: json['author_info'] as String,
        summary: json['summary'] as String,
      );
}

class ExamPreview {
  final String name;
  final String authorInfo;
  final int choiceCount;
  final int fillCount;
  final int solutionCount;
  final int totalCount;
  final List<ExamQuestion> questions;

  const ExamPreview({
    required this.name,
    required this.authorInfo,
    required this.choiceCount,
    required this.fillCount,
    required this.solutionCount,
    required this.totalCount,
    required this.questions,
  });

  factory ExamPreview.fromJson(Map<String, dynamic> json) => ExamPreview(
        name: json['name'] as String,
        authorInfo: json['author_info'] as String,
        choiceCount: json['choice_count'] as int,
        fillCount: json['fill_count'] as int,
        solutionCount: json['solution_count'] as int,
        totalCount: json['total_count'] as int,
        questions: (json['questions'] as List)
            .map((e) => ExamQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ExamPreviewOther {
  final String name;
  final String authorInfo;
  final int choiceCount;
  final int fillCount;
  final int solutionCount;
  final int totalCount;
  final int likeCount;
  final int collectCount;
  final List<ExamQuestion> questions;

  const ExamPreviewOther({
    required this.name,
    required this.authorInfo,
    required this.choiceCount,
    required this.fillCount,
    required this.solutionCount,
    required this.totalCount,
    required this.likeCount,
    required this.collectCount,
    required this.questions,
  });

  factory ExamPreviewOther.fromJson(Map<String, dynamic> json) =>
      ExamPreviewOther(
        name: json['name'] as String,
        authorInfo: json['author_info'] as String,
        choiceCount: json['choice_count'] as int,
        fillCount: json['fill_count'] as int,
        solutionCount: json['solution_count'] as int,
        totalCount: json['total_count'] as int,
        likeCount: json['like_count'] as int,
        collectCount: json['collect_count'] as int,
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

class FilterOptions {
  final List<String> years;
  final List<String> regions;
  final List<String> conceptTags;
  final List<String> knowledgeCards;
  final List<String> examTypes;

  const FilterOptions({
    required this.years,
    required this.regions,
    required this.conceptTags,
    required this.knowledgeCards,
    this.examTypes = const [],
  });

  factory FilterOptions.fromJson(Map<String, dynamic> json) => FilterOptions(
        years: (json['years'] as List).cast<String>(),
        regions: (json['regions'] as List).cast<String>(),
        conceptTags: (json['concept_tags'] as List).cast<String>(),
        knowledgeCards: (json['knowledge_cards'] as List).cast<String>(),
        examTypes: (json['exam_types'] as List?)?.cast<String>() ?? [],
      );
}

class SearchFilters {
  final String name;
  final int choiceCount;
  final int fillCount;
  final int solutionCount;
  final double targetDifficulty;
  final List<String> years;
  final List<String> regions;
  final List<String> conceptTags;
  final List<String> knowledgeCards;
  final double? diffMin;
  final double? diffMax;
  final double? calcMin;
  final double? calcMax;
  final List<int> selectedIds;

  const SearchFilters({
    required this.name,
    required this.choiceCount,
    required this.fillCount,
    required this.solutionCount,
    required this.targetDifficulty,
    required this.years,
    required this.regions,
    required this.conceptTags,
    required this.knowledgeCards,
    this.diffMin,
    this.diffMax,
    this.calcMin,
    this.calcMax,
    this.selectedIds = const [],
  });
}

/// 筛选池统计
class PoolStats {
  final int availableChoice;
  final int availableFill;
  final int availableSolution;
  final double poolDiffMin;
  final double poolDiffMax;
  final double gaokaoDiffMin;
  final double gaokaoDiffAvg;
  final double gaokaoDiffMax;

  const PoolStats({
    required this.availableChoice,
    required this.availableFill,
    required this.availableSolution,
    required this.poolDiffMin,
    required this.poolDiffMax,
    required this.gaokaoDiffMin,
    required this.gaokaoDiffAvg,
    required this.gaokaoDiffMax,
  });
}

class FilterPreset {
  final int id;
  final String name;

  const FilterPreset({required this.id, required this.name});
}

class SearchQuestion {
  final int id;
  final String title;
  final String meta;
  final double difficulty;
  final double calculation;

  const SearchQuestion({
    required this.id,
    required this.title,
    required this.meta,
    required this.difficulty,
    required this.calculation,
  });

  factory SearchQuestion.fromJson(Map<String, dynamic> json) => SearchQuestion(
        id: json['id'] as int,
        title: json['title'] as String,
        meta: json['meta'] as String,
        difficulty: (json['difficulty'] as num).toDouble(),
        calculation: (json['calculation'] as num).toDouble(),
      );
}

class ExamRepository {
  // ---- 发现组卷 ----
  Future<List<ExploreExamSummary>> getExploreList() async {
    throw UnimplementedError('ExamRepository.getExploreList');
  }

  Future<void> toggleLike(int examId) async {
    throw UnimplementedError('ExamRepository.toggleLike');
  }

  Future<void> toggleCollect(int examId) async {
    throw UnimplementedError('ExamRepository.toggleCollect');
  }

  // ---- 我的收藏 ----
  Future<List<FavoriteExamSummary>> getFavorites() async {
    throw UnimplementedError('ExamRepository.getFavorites');
  }

  Future<void> removeFavorite(int examId) async {
    throw UnimplementedError('ExamRepository.removeFavorite');
  }

  // ---- 我的组卷历史 ----
  Future<List<ExamSummary>> getMyExams() async {
    throw UnimplementedError('ExamRepository.getMyExams');
  }

  Future<void> togglePublic(int examId) async {
    throw UnimplementedError('ExamRepository.togglePublic');
  }

  Future<void> deleteExam(int examId) async {
    throw UnimplementedError('ExamRepository.deleteExam');
  }

  // ---- 预览 ----
  Future<ExamPreview> getPreview(int examId) async {
    throw UnimplementedError('ExamRepository.getPreview');
  }

  Future<ExamPreviewOther> getPreviewOther(int examId) async {
    throw UnimplementedError('ExamRepository.getPreviewOther');
  }

  /// 下载/打印试卷（委托给 PdfHelper）
  Future<void> downloadPdf(int paperId) async {
    throw UnimplementedError('ExamRepository.downloadPdf');
  }

  // ---- 快对答案 ----
  Future<List<AnswerItem>> getQuickAnswers(int examId) async {
    throw UnimplementedError('ExamRepository.getQuickAnswers');
  }

  // ---- 筛选预设（委托给 preference_repository） ----
  Future<List<FilterPreset>> getFilterPresets() async {
    throw UnimplementedError('ExamRepository.getFilterPresets');
  }

  Future<void> saveFilterPreset(String name) async {
    throw UnimplementedError('ExamRepository.saveFilterPreset');
  }

  Future<SearchFilters> loadFilterPreset(int presetId) async {
    throw UnimplementedError('ExamRepository.loadFilterPreset');
  }

  // ---- 筛选选项（从本地题库/assets 读取） ----
  Future<FilterOptions> getFilterOptions() async {
    throw UnimplementedError('ExamRepository.getFilterOptions');
  }

  // ---- 数据绑定/状态（手动选题模式） ----
  Future<ExamBuildState> getBuildSession() async {
    throw UnimplementedError('ExamRepository.getBuildSession');
  }

  /// 筛选后的题目列表（通过 ExamDao 从本地资产库查询）
  Future<List<SearchQuestion>> getFilteredQuestions(
      SearchFilters filters) async {
    throw UnimplementedError('ExamRepository.getFilteredQuestions');
  }

  /// 筛选池统计（委托给 _ExamFilterEngine）
  Future<PoolStats> getPoolStats(SearchFilters filters) async {
    throw UnimplementedError('ExamRepository.getPoolStats');
  }

  Future<int> getTotalCount(SearchFilters filters) async {
    throw UnimplementedError('ExamRepository.getTotalCount');
  }

  /// 确认组卷（委托给 _ExamGenerator）
  /// [allowShortfall] 为 true 时，池子不足不抛异常，有多少取多少
  Future<int> confirm(SearchFilters filters, {bool allowShortfall = false}) async {
    throw UnimplementedError('ExamRepository.confirm');
  }
}

// ---- 私有算法引擎 ----

/// 实时过滤+计数+难度统计（通过 ExamDao 从本地资产库查询）
class _ExamFilterEngine {
  // availableChoice/Fill/Solution: dao.countByType(type, filters)
  // poolDiffMin/Max: dao.getDifficultyRange(filters)
  // gaokaoDiffMin/Avg/Max: dao.getGaokaoStats(filters)
}

/// 智能组卷算法
///
/// confirm() 委托给此类。
/// 所有计算在本地 drift 完成，不依赖服务器。
///
/// ┌─ 流程总览 ──────────────────────────────────────────────────┐
/// │                                                              │
/// │  confirm(filters, allowShortfall)                             │
/// │    1. 获取筛选池 → dao.getFilteredPool(filters)              │
/// │    2. 锁定手动选题（selectedIds 固定不动）                   │
/// │    3. 检查各题型池子是否够用                                  │
/// │       → allowShortfall==false 且不足 → 抛异常                 │
/// │       → allowShortfall==true  → 跳过检查，有多少取多少       │
/// │    4. Phase 1 — 贪心初始集                                  │
/// │       每种题型按 |difficulty - target| 排序取 top N         │
/// │    5. Phase 2 — 交换优化 (3 轮)                             │
/// │       每轮遍历各题型，找能改善整卷均值的单题交换             │
/// │    6. 持久化 → 写入 exam 表 + paper_question 表            │
/// │    7. 返回 exam_id                                          │
/// │                                                              │
/// └──────────────────────────────────────────────────────────────┘
///
/// ┌─ Phase 1：贪心初始化 ──────────────────────────────────────┐
/// │  对每种题型：                                                 │
/// │    pool.sort(by |difficulty - targetDifficulty|)             │
/// │    取前 needed 道（排除 locked 的 selectedIds）              │
/// │    与 locked 题合并 → 当前选定集                             │
/// └──────────────────────────────────────────────────────────────┘
///
/// ┌─ Phase 2：交换优化 (3 轮固定) ────────────────────────────┐
/// │  每轮：                                                      │
/// │    for type in [choice, fill, solution]:                     │
/// │      selected = 当前选定的该题型题目列表                     │
/// │      candidates = 池子中未选中的同题型题目                   │
/// │                                                              │
/// │      // 找最佳交换                                           │
/// │      bestSwap = null, bestImprovement = 0                    │
/// │      for each s in selected:                                 │
/// │        for each c in candidates:                             │
/// │          delta = (c.difficulty - s.difficulty) / totalCount  │
/// │          newMean = currentMean + delta                        │
/// │          improvement = |currentMean - target| - |newMean - target|
/// │          if improvement > bestImprovement:                   │
/// │            bestImprovement = improvement                     │
/// │            bestSwap = (s, c)                                 │
/// │                                                              │
/// │      if bestSwap exists → 执行交换并更新 currentMean        │
/// │                                                              │
/// │  效果预估：                                                   │
/// │    初始偏差 ±0.20 → 3 轮后 ±0.04                             │
/// │    初始偏差 ±0.50 → 3 轮后 ±0.08                             │
/// │    初始偏差 ±0.80 → 3 轮后 ±0.12                             │
/// └──────────────────────────────────────────────────────────────┘
///
/// ┌─ 池子不足处理 ─────────────────────────────────────────────┐
/// │  检查：                                                      │
/// │    needed = filters.choiceCount - 已选选择题数              │
/// │    available = 池子中 choice 类型题目数                      │
/// │    任一 needed > available → 抛出 InsufficientPoolException  │
/// │                                                              │
/// │  InsufficientPoolException 包含字段：                         │
/// │   - type: 不足的题型 ("choice" / "fill" / "solution")       │
/// │   - needed: 还需要几道                                       │
/// │   - available: 池子里有几道                                   │
/// │                                                              │
/// │  confirm() 的调用者捕获后弹窗：                               │
/// │    "选择题池子不足（需要8道，只有5道）"                       │
/// │    两个按钮：直接组卷 / 调整筛选条件                          │
/// │    直接组卷 → 用 allowShortfall=true 再次调 confirm()        │
/// └──────────────────────────────────────────────────────────────┘
class _ExamGenerator {
  static const int maxSwapRounds = 3;

  /// 入口：执行智能组卷
  /// 返回 exam id（持久化后的主键）
  /// 池子不足时抛出 InsufficientPoolException
  ///
  /// 实现时需要的 DAO 接口：
  ///   getFilteredPool(SearchFilters)
  ///     -> List<SearchQuestion>  (已排除已做题)
  ///   countByType(type, filters) -> int
  ///   saveExam(name, questionIds) -> int (exam id)
  ///   savePaperQuestions(examId, questionIds)
}

/// 池子不足异常
/// confirm() 的调用者捕获后展示弹窗，让用户选择直接组卷或调整筛选条件
class InsufficientPoolException implements Exception {
  final String type;
  final int needed;
  final int available;

  const InsufficientPoolException({
    required this.type,
    required this.needed,
    required this.available,
  });

  String get message =>
      '$type 类题目池子不足（需要 $needed 道，池中只有 $available 道）';
}
