import '../data/daos/question_dao.dart';
import '../data/database/assets_database.dart' as assets_db;

/// 排序模式
enum SortMode {
  /// 最新优先
  newestFirst,

  /// 最早优先
  oldestFirst,

  /// 按题型分组
  byType,

  /// 难度升序
  difficultyAsc,

  /// 难度降序
  difficultyDesc,

  /// 年份降序（最新在前）
  yearDesc,

  /// 年份升序
  yearAsc,
}

/// 树状概念标签节点
class ConceptTagNode {
  final int id;
  final String name;
  final int? parentId;
  final List<ConceptTagNode> children;
  const ConceptTagNode({
    required this.id, required this.name, this.parentId,
    this.children = const [],
  });
}

/// 知识卡片项
class KnowledgeCardItem {
  final int id;
  final String title;
  const KnowledgeCardItem({required this.id, required this.title});
}

/// 分类知识卡片组
class KnowledgeCardGroup {
  final String category;
  final List<KnowledgeCardItem> cards;
  const KnowledgeCardGroup({required this.category, required this.cards});
}

/// 筛选选项
class FilterOptions {
  final List<String> years;
  final List<String> regions;
  final List<String> conceptTags;
  final List<String> knowledgeCards;
  final List<String> examTypes;
  final List<String> questionTypes;
  final List<ConceptTagNode> conceptTagTree;
  final List<KnowledgeCardGroup> knowledgeCardGroups;

  const FilterOptions({
    required this.years,
    required this.regions,
    required this.conceptTags,
    this.knowledgeCards = const [],
    this.examTypes = const [],
    this.questionTypes = const ['choice', 'fill', 'solution'],
    this.conceptTagTree = const [],
    this.knowledgeCardGroups = const [],
  });
}

/// 筛选条件
class SearchFilters {
  final String name;
  final List<String> years;
  final List<String> regions;
  final List<String> conceptTags;
  final List<String> knowledgeCards;
  final double? diffMin;
  final double? diffMax;
  final double? calcMin;
  final double? calcMax;
  final List<String>? examTypes;
  final List<String>? questionTypes;

  const SearchFilters({
    required this.name,
    this.years = const [],
    this.regions = const [],
    this.conceptTags = const [],
    this.knowledgeCards = const [],
    this.diffMin, this.diffMax, this.calcMin, this.calcMax,
    this.examTypes,
    this.questionTypes,
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
    required this.availableChoice, required this.availableFill, required this.availableSolution,
    required this.poolDiffMin, required this.poolDiffMax,
    required this.gaokaoDiffMin, required this.gaokaoDiffAvg, required this.gaokaoDiffMax,
  });
}

/// 搜索到的题目
class SearchQuestion {
  final int id;
  final String title;
  final String questionType;
  final String meta;
  final double difficulty;
  final double calculation;
  const SearchQuestion({required this.id, required this.title, required this.questionType, required this.meta, required this.difficulty, required this.calculation});
}

/// 安全截断 stem：避免截断点在 $...$ 公式内部导致未闭合 $
String _safeStemCut(String stem, int maxLen) {
  assert(maxLen > 0);
  if (stem.length <= maxLen) return stem;
  int cut = maxLen;
  int dollarCount = RegExp(r'\$').allMatches(stem.substring(0, cut)).length;
  if (dollarCount.isOdd) {
    int lastDollar = stem.lastIndexOf(r'$', cut - 1);
    if (lastDollar > 0) cut = lastDollar;
  }
  return '${stem.substring(0, cut)}...';
}

/// 题目详情（含子题/选项/步骤/标签）
class QuestionDetail {
  final assets_db.QuestionRow question;
  final assets_db.ChoiceExtRow? choiceExt;
  final List<assets_db.SubQuestionRow> subQuestions;
  final List<assets_db.SolutionMethodRow> methods;
  final List<assets_db.SolutionStepRow> steps;
  final List<assets_db.ConceptTagRow> tags;
  final List<assets_db.KnowledgeCardRow> knowledgeCards;

  const QuestionDetail({
    required this.question,
    this.choiceExt,
    this.subQuestions = const [],
    this.methods = const [],
    this.steps = const [],
    this.tags = const [],
    this.knowledgeCards = const [],
  });
}

/// 题库 Repository — 只读接口，无写方法
class QuestionRepository {
  final QuestionDao _questionDao;

  const QuestionRepository(this._questionDao);

  /// 获取筛选选项
  Future<FilterOptions> getFilterOptions() async {
    final years = (await _questionDao.getDistinctYears()).map((y) => y.toString()).toList();
    final regions = await _questionDao.getDistinctRegions();
    final tags = await _questionDao.getAllConceptTags();
    final kcs = await _questionDao.getAllKnowledgeCards();
    final examTypes = await _questionDao.getDistinctExamTypes();
    return FilterOptions(
      years: years,
      regions: regions,
      conceptTags: tags.map((t) => t.name).toList(),
      conceptTagTree: buildTagTree(tags),
      knowledgeCards: kcs.map((k) => k.title).toList(),
      knowledgeCardGroups: buildKnowledgeCardGroups(kcs),
      examTypes: examTypes,
      questionTypes: const ['choice', 'fill', 'solution'],
    );
  }

  /// 获取筛选后的题目列表，支持排序
  Future<List<SearchQuestion>> getFilteredQuestions(
    SearchFilters filters, {
    SortMode sort = SortMode.newestFirst,
  }) async {
    final rows = await _questionDao.search(
      years: filters.years.map((y) => int.tryParse(y)).whereType<int>().toList(),
      regions: filters.regions.isNotEmpty ? filters.regions : null,
      diffMin: filters.diffMin,
      diffMax: filters.diffMax,
      calcMin: filters.calcMin,
      calcMax: filters.calcMax,
      conceptTagNames: filters.conceptTags.isNotEmpty ? filters.conceptTags : null,
      knowledgeCardNames: filters.knowledgeCards.isNotEmpty ? filters.knowledgeCards : null,
      examTypes: filters.examTypes != null && filters.examTypes!.isNotEmpty ? filters.examTypes : null,
      questionTypes: filters.questionTypes != null && filters.questionTypes!.isNotEmpty ? filters.questionTypes : null,
    );

    // 排序
    List<assets_db.QuestionRow> sorted;
    switch (sort) {
      case SortMode.newestFirst:
        sorted = List.of(rows)..sort((a, b) => b.year.compareTo(a.year));
      case SortMode.oldestFirst:
        sorted = List.of(rows)..sort((a, b) => a.year.compareTo(b.year));
      case SortMode.byType:
        sorted = List.of(rows)..sort((a, b) => a.questionType.compareTo(b.questionType));
      case SortMode.difficultyAsc:
        sorted = List.of(rows)..sort((a, b) => (a.difficulty ?? 0).compareTo(b.difficulty ?? 0));
      case SortMode.difficultyDesc:
        sorted = List.of(rows)..sort((a, b) => (b.difficulty ?? 0).compareTo(a.difficulty ?? 0));
      case SortMode.yearDesc:
        sorted = List.of(rows)..sort((a, b) => b.year.compareTo(a.year));
      case SortMode.yearAsc:
        sorted = List.of(rows)..sort((a, b) => a.year.compareTo(b.year));
    }

    return sorted.map((r) => SearchQuestion(
      id: r.id,
      title: r.stem.length > 80 ? _safeStemCut(r.stem, 80) : r.stem,
      questionType: r.questionType,
      meta: '${r.year} ${r.examType} ${r.region}',
      difficulty: r.difficulty ?? 0,
      calculation: r.calculation ?? 0,
    )).toList();
  }

  /// 获取筛选池统计
  Future<PoolStats> getPoolStats(SearchFilters filters) async {
    final engine = _ExamFilterEngine(_questionDao);
    return engine.compute(filters);
  }

  /// 获取题目详情（含子题/选项/步骤/标签）
  Future<QuestionDetail> getQuestionDetail(int questionId) async {
    final question = await _questionDao.getById(questionId);
    if (question == null) throw Exception('Question not found: $questionId');

    final choiceExt = await _questionDao.getChoiceExt(questionId);
    final subQuestions = await _questionDao.getSubQuestions(questionId);

    // 批量查询所有子题的解法
    final subIds = subQuestions.map((sq) => sq.id).toList();
    final methods = await _questionDao.getMethodsBySubQuestionIds(subIds);

    // 批量查询所有方法的步骤
    final methodIds = methods.map((m) => m.id).toList();
    final steps = await _questionDao.getStepsByMethodIds(methodIds);

    final tags = await _questionDao.getTagsByQuestion(questionId);
    final knowledgeCards = await _questionDao.getKnowledgeCardsByQuestion(questionId);

    return QuestionDetail(
      question: question,
      choiceExt: choiceExt,
      subQuestions: subQuestions,
      methods: methods,
      steps: steps,
      tags: tags,
      knowledgeCards: knowledgeCards,
    );
  }

  /// 获取筛选总数
  Future<int> getTotalCount(SearchFilters filters) async {
    final questions = await getFilteredQuestions(filters);
    return questions.length;
  }

  static List<ConceptTagNode> buildTagTree(List<assets_db.ConceptTagRow> tags) {
    final byParent = <int?, List<assets_db.ConceptTagRow>>{};
    for (final t in tags) {
      byParent.putIfAbsent(t.parentId, () => []).add(t);
    }
    ConceptTagNode buildNode(assets_db.ConceptTagRow row) {
      return ConceptTagNode(
        id: row.id, name: row.name, parentId: row.parentId,
        children: (byParent[row.id] ?? []).map(buildNode).toList(),
      );
    }
    return (byParent[null] ?? []).map(buildNode).toList();
  }

  static List<KnowledgeCardGroup> buildKnowledgeCardGroups(List<assets_db.KnowledgeCardRow> cards) {
    final byCategory = <String, List<KnowledgeCardItem>>{};
    for (final c in cards) {
      byCategory.putIfAbsent(c.category, () => []).add(KnowledgeCardItem(id: c.id, title: c.title));
    }
    return byCategory.entries.map((e) => KnowledgeCardGroup(
      category: e.key, cards: e.value,
    )).toList();
  }
}

// ── 筛选池统计引擎 ──

class _ExamFilterEngine {
  final QuestionDao _dao;
  const _ExamFilterEngine(this._dao);

  Future<PoolStats> compute(SearchFilters filters) async {
    final pool = await _dao.search(
      years: filters.years.map((y) => int.tryParse(y)).whereType<int>().toList(),
      regions: filters.regions.isNotEmpty ? filters.regions : null,
      diffMin: filters.diffMin,
      diffMax: filters.diffMax,
      calcMin: filters.calcMin,
      calcMax: filters.calcMax,
      conceptTagNames: filters.conceptTags.isNotEmpty ? filters.conceptTags : null,
      knowledgeCardNames: filters.knowledgeCards.isNotEmpty ? filters.knowledgeCards : null,
      examTypes: filters.examTypes != null && filters.examTypes!.isNotEmpty ? filters.examTypes : null,
      questionTypes: filters.questionTypes != null && filters.questionTypes!.isNotEmpty ? filters.questionTypes : null,
    );

    final choicePool = pool.where((q) => q.questionType == 'choice').toList();
    final fillPool = pool.where((q) => q.questionType == 'fill').toList();
    final solutionPool = pool.where((q) => q.questionType == 'solution').toList();

    final allDiff = pool.map((q) => q.difficulty ?? 0).toList();
    final gaokaoAll = pool.where((q) => q.examType == '高考').map((q) => q.difficulty ?? 0).toList();

    return PoolStats(
      availableChoice: choicePool.length,
      availableFill: fillPool.length,
      availableSolution: solutionPool.length,
      poolDiffMin: allDiff.isEmpty ? 0 : allDiff.reduce((a, b) => a < b ? a : b),
      poolDiffMax: allDiff.isEmpty ? 0 : allDiff.reduce((a, b) => a > b ? a : b),
      gaokaoDiffMin: gaokaoAll.isEmpty ? 0 : gaokaoAll.reduce((a, b) => a < b ? a : b),
      gaokaoDiffAvg: gaokaoAll.isEmpty ? 0 : gaokaoAll.reduce((a, b) => a + b) / gaokaoAll.length,
      gaokaoDiffMax: gaokaoAll.isEmpty ? 0 : gaokaoAll.reduce((a, b) => a > b ? a : b),
    );
  }
}
