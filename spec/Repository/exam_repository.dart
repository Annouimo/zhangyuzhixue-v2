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

  const FilterOptions({
    required this.years,
    required this.regions,
    required this.conceptTags,
    required this.knowledgeCards,
  });

  factory FilterOptions.fromJson(Map<String, dynamic> json) => FilterOptions(
        years: (json['years'] as List).cast<String>(),
        regions: (json['regions'] as List).cast<String>(),
        conceptTags: (json['concept_tags'] as List).cast<String>(),
        knowledgeCards: (json['knowledge_cards'] as List).cast<String>(),
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
  static Future<List<ExploreExamSummary>> getExploreList() async {
    throw UnimplementedError('ExamRepository.getExploreList');
  }

  static Future<void> toggleLike(int examId) async {
    throw UnimplementedError('ExamRepository.toggleLike');
  }

  static Future<void> toggleCollect(int examId) async {
    throw UnimplementedError('ExamRepository.toggleCollect');
  }

  // ---- 我的收藏 ----
  static Future<List<FavoriteExamSummary>> getFavorites() async {
    throw UnimplementedError('ExamRepository.getFavorites');
  }

  static Future<void> removeFavorite(int examId) async {
    throw UnimplementedError('ExamRepository.removeFavorite');
  }

  // ---- 我的组卷历史 ----
  static Future<List<ExamSummary>> getMyExams() async {
    throw UnimplementedError('ExamRepository.getMyExams');
  }

  static Future<void> togglePublic(int examId) async {
    throw UnimplementedError('ExamRepository.togglePublic');
  }

  static Future<void> deleteExam(int examId) async {
    throw UnimplementedError('ExamRepository.deleteExam');
  }

  // ---- 预览 ----
  static Future<ExamPreview> getPreview(int examId) async {
    throw UnimplementedError('ExamRepository.getPreview');
  }

  static Future<ExamPreviewOther> getPreviewOther(int examId) async {
    throw UnimplementedError('ExamRepository.getPreviewOther');
  }

  static Future<void> downloadPdf(int examId) async {
    throw UnimplementedError('ExamRepository.downloadPdf');
  }

  // ---- 快对答案 ----
  static Future<List<AnswerItem>> getQuickAnswers(int examId) async {
    throw UnimplementedError('ExamRepository.getQuickAnswers');
  }

  // ---- 筛选预设（委托给 preference_repository） ----
  static Future<List<FilterPreset>> getFilterPresets() async {
    throw UnimplementedError('ExamRepository.getFilterPresets');
  }

  static Future<void> saveFilterPreset(String name) async {
    throw UnimplementedError('ExamRepository.saveFilterPreset');
  }

  static Future<SearchFilters> loadFilterPreset(int presetId) async {
    throw UnimplementedError('ExamRepository.loadFilterPreset');
  }

  // ---- 筛选选项（从本地题库/assets 读取） ----
  static Future<FilterOptions> getFilterOptions() async {
    throw UnimplementedError('ExamRepository.getFilterOptions');
  }

  // ---- 数据绑定/状态（手动选题模式） ----
  static Future<ExamBuildState> getBuildSession() async {
    throw UnimplementedError('ExamRepository.getBuildSession');
  }

  /// 筛选后的题目列表（通过 ExamDao 从本地资产库查询）
  static Future<List<SearchQuestion>> getFilteredQuestions(
      SearchFilters filters) async {
    throw UnimplementedError('ExamRepository.getFilteredQuestions');
  }

  /// 筛选池统计（委托给 _ExamFilterEngine）
  static Future<PoolStats> getPoolStats(SearchFilters filters) async {
    throw UnimplementedError('ExamRepository.getPoolStats');
  }

  static Future<int> getTotalCount(SearchFilters filters) async {
    throw UnimplementedError('ExamRepository.getTotalCount');
  }

  /// 确认组卷（委托给 _ExamGenerator）
  static Future<int> confirm(SearchFilters filters) async {
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
/// ⚠️ 极简 v1 方案，与同事讨论后替换为正式方案。
/// 替换时只需重写 _ExamGenerator 类，外部模块不受影响。
///
/// v1 方案（极简，能用就行）：
///   1. 获取筛选池：dao.getFilteredQuestions(filters)（已排除已做题）
///   2. 按题型分三组：选择 / 填空 / 解答
///   3. 每组内按 |difficulty - targetDifficulty| 升序排列
///   4. 从每组最接近目标难度的开始取，取满 filters.choiceCount / fillCount / solutionCount
///   5. 如果某题型数量不够筛选池大小，有多少取多少（不补、不报错）
///   6. 按题型分组排序输出：选择 → 填空 → 解答
///
/// 已知缺点（正式方案需解决）：
///   - 只保证单题难度接近目标，不保证整体均值匹配
///   - 无多样性约束（可能同一年/同一场考试出多道）
///   - 无题量不足时的降级策略
class _ExamGenerator {
}

/// PDF 生成
///
/// 🚧 设计未完成。有 Python 原型（D:\Hermes\pdf_test\exam_pdf.py），
/// 但融入项目的架构决策未定，Flutter 端能否跑通未验证。
///
/// Python 原型说明：
///   - exam_pdf.py：HTML+KaTeX → headless Chrome → PDF
///   - API：generate_pdf(title, sections, output_path)
///   - 数据类：Choice, Section, Question 已定义
///
/// 待决架构问题（决定了才能编码）：
///   1. PDF 生成放在客户端（Flutter）还是服务端（Django）？
///      - 客户端：用 `pdf` 或 `flutter_html` 等 Dart 包。需验证 LaTeX 渲染支持
///      - 服务端：调 Python 脚本 / 集成到 Django views，Flutter 端下载文件
///   2. Flutter 端下载 PDF 后如何打开预览？用 url_launcher 跳外部 PDF 阅读器？
///   3. 如果走服务端：同步队列要不要支持二进制下载（当前设计队列只推 JSON）？
///   4. 如果走客户端：Flutter 生态中有什么包能渲染带 KaTeX 的 HTML 并导出 PDF？
class _ExamPdfService {
}
