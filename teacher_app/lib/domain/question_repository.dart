import '../data/daos/question_dao.dart';
import '../data/database/database_provider.dart';
import '../data/database/assets_database.dart' as db;

// ═══════════════════════════════════════════════
// 数据模型
// ═══════════════════════════════════════════════

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
  final int choiceCount;
  final int fillCount;
  final int solutionCount;
  final int targetDifficulty;
  final List<String> years;
  final List<String> regions;
  final List<String> conceptTags;
  final List<String> knowledgeCards;
  final List<String> examTypes;
  final List<String> questionTypes;
  final double diffMin;
  final double diffMax;
  final double calcMin;
  final double calcMax;
  final List<int>? selectedIds;

  const SearchFilters({
    this.name = '',
    this.choiceCount = 0,
    this.fillCount = 0,
    this.solutionCount = 0,
    this.targetDifficulty = 0,
    this.years = const [],
    this.regions = const [],
    this.conceptTags = const [],
    this.knowledgeCards = const [],
    this.examTypes = const [],
    this.questionTypes = const [],
    this.diffMin = 0,
    this.diffMax = 10,
    this.calcMin = 0,
    this.calcMax = 10,
    this.selectedIds,
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
  const SearchQuestion({
    required this.id, required this.title, required this.questionType,
    required this.meta, required this.difficulty, required this.calculation,
  });
}

/// 池统计
class PoolStats {
  final int availableChoice;
  final int availableFill;
  final int availableSolution;
  const PoolStats({
    required this.availableChoice,
    required this.availableFill,
    required this.availableSolution,
  });
}

/// 排序方式
enum SortMode {
  newestFirst,    // 年份倒序（最新优先）
  oldestFirst,    // 年份正序
  difficultyDesc, // 难度从高到低
  difficultyAsc,  // 难度从低到高
  byType,         // 按题型分组
  byNumber,       // 按题号
}

// ═══════════════════════════════════════════════
// Repository
// ═══════════════════════════════════════════════

/// 题库 Repository — 纯查询，不含写入
class QuestionRepository {
  final QuestionDao _questionDao;

  QuestionRepository(this._questionDao);

  factory QuestionRepository.fromProvider() {
    return QuestionRepository(QuestionDao(DatabaseProvider().assetsDb));
  }

  /// 获取筛选面板选项
  Future<FilterOptions> getFilterOptions() async {
    final years = (await _questionDao.getDistinctYears())
        .map((y) => y.toString())
        .toList();
    final regions = await _questionDao.getDistinctRegions();
    final examTypes = await _questionDao.getDistinctExamTypes();

    final allTags = await _questionDao.getAllConceptTags();
    final tagTree = _buildTagTree(allTags);
    final conceptTags = allTags.map((t) => t.name).toList();

    final allKcs = await _questionDao.getAllKnowledgeCards();
    final knowledgeCardGroups = _buildKnowledgeCardGroups(allKcs);
    final knowledgeCardTitles = allKcs.map((k) => k.title).toList();

    return FilterOptions(
      years: years,
      regions: regions,
      conceptTags: conceptTags,
      examTypes: examTypes,
      conceptTagTree: tagTree,
      knowledgeCards: knowledgeCardTitles,
      knowledgeCardGroups: knowledgeCardGroups,
    );
  }

  /// 按筛选条件搜索题目
  Future<List<SearchQuestion>> getFilteredQuestions(
    SearchFilters filters, {
    SortMode sort = SortMode.newestFirst,
  }) async {
    final rows = await _questionDao.search(
      years: filters.years.isNotEmpty
          ? filters.years.map((y) => int.tryParse(y)).whereType<int>().toList()
          : null,
      regions: filters.regions.isNotEmpty ? filters.regions.toList() : null,
      diffMin: filters.diffMin > 0 ? filters.diffMin : null,
      diffMax: filters.diffMax < 10 ? filters.diffMax : null,
      calcMin: filters.calcMin > 0 ? filters.calcMin : null,
      calcMax: filters.calcMax < 10 ? filters.calcMax : null,
      examTypes: filters.examTypes.isNotEmpty
          ? filters.examTypes.toList()
          : null,
      questionTypes: filters.questionTypes.isNotEmpty
          ? filters.questionTypes.toList()
          : null,
      conceptTagNames: filters.conceptTags.isNotEmpty
          ? filters.conceptTags.toList()
          : null,
      knowledgeCardNames: filters.knowledgeCards.isNotEmpty
          ? filters.knowledgeCards.toList()
          : null,
    );

    // 内存排序
    var result = rows.map((r) => SearchQuestion(
      id: r.id,
      title: r.stem,
      questionType: r.questionType,
      meta: _buildMeta(r),
      difficulty: r.difficulty ?? 0,
      calculation: r.calculation ?? 0,
    )).toList();

    switch (sort) {
      case SortMode.newestFirst:
        result.sort((a, b) => b.id.compareTo(a.id));
        break;
      case SortMode.oldestFirst:
        result.sort((a, b) => a.id.compareTo(b.id));
        break;
      case SortMode.difficultyDesc:
        result.sort((a, b) => b.difficulty.compareTo(a.difficulty));
        break;
      case SortMode.difficultyAsc:
        result.sort((a, b) => a.difficulty.compareTo(b.difficulty));
        break;
      case SortMode.byType:
        result.sort((a, b) => a.questionType.compareTo(b.questionType));
        break;
      case SortMode.byNumber:
        // 近似按题号排
        break;
    }
    return result;
  }

  /// 获取题目详情（含子题、选项、解法步骤、标签等）
  Future<QuestionDetail?> getQuestionDetail(int questionId) async {
    final question = await _questionDao.getById(questionId);
    if (question == null) return null;

    final choiceExt = await _questionDao.getChoiceExt(questionId);
    final subQuestions = await _questionDao.getSubQuestions(questionId);
    final tags = await _questionDao.getTagsByQuestion(questionId);

    // 批量查子题解法
    final subIds = subQuestions.map((s) => s.id).toList();
    final methods = await _questionDao.getMethodsBySubQuestionIds(subIds);
    final methodIds = methods.map((m) => m.id).toList();
    final steps = await _questionDao.getStepsByMethodIds(methodIds);

    return QuestionDetail(
      question: question,
      choiceExt: choiceExt,
      subQuestions: subQuestions,
      methods: methods,
      steps: steps,
      tags: tags,
    );
  }

  Future<PoolStats> getPoolStats(SearchFilters filters) async {
    final qs = await _questionDao.search(
      years: filters.years.isNotEmpty
          ? filters.years.map((y) => int.tryParse(y)).whereType<int>().toList()
          : null,
      regions: filters.regions.isNotEmpty ? filters.regions.toList() : null,
      diffMin: filters.diffMin > 0 ? filters.diffMin : null,
      diffMax: filters.diffMax < 10 ? filters.diffMax : null,
      calcMin: filters.calcMin > 0 ? filters.calcMin : null,
      calcMax: filters.calcMax < 10 ? filters.calcMax : null,
      examTypes: filters.examTypes.isNotEmpty
          ? filters.examTypes.toList()
          : null,
      questionTypes: filters.questionTypes.isNotEmpty
          ? filters.questionTypes.toList()
          : null,
      conceptTagNames: filters.conceptTags.isNotEmpty
          ? filters.conceptTags.toList()
          : null,
      knowledgeCardNames: filters.knowledgeCards.isNotEmpty
          ? filters.knowledgeCards.toList()
          : null,
    );
    final choice = qs.where((q) => q.questionType == 'choice').length;
    final fill = qs.where((q) => q.questionType == 'fill').length;
    final solution = qs.where((q) => q.questionType == 'solution').length;
    return PoolStats(availableChoice: choice, availableFill: fill, availableSolution: solution);
  }

  // ── 构建帮助 ──

  String _buildMeta(db.QuestionRow q) {
    final parts = <String>[];
    parts.add('${q.year}');
    if (q.region.isNotEmpty) parts.add(q.region);
    if (q.examType.isNotEmpty) parts.add(q.examType);
    if (q.number.isNotEmpty) parts.add('第${q.number}题');
    return parts.join(' · ');
  }

  List<ConceptTagNode> _buildTagTree(List<db.ConceptTagRow> tags) {
    final map = <int, ConceptTagNode>{};
    final roots = <ConceptTagNode>[];
    for (final t in tags) {
      map[t.id] = ConceptTagNode(id: t.id, name: t.name, parentId: t.parentId);
    }
    for (final t in tags) {
      if (t.parentId != null && map.containsKey(t.parentId)) {
        final parent = map[t.parentId]!;
        parent.children;
      }
    }
    // 找根节点
    for (final t in tags) {
      if (t.parentId == null) {
        roots.add(_buildSubTree(t, map));
      }
    }
    return roots;
  }

  ConceptTagNode _buildSubTree(db.ConceptTagRow tag, Map<int, ConceptTagNode> nodeMap) {
    final node = nodeMap[tag.id]!;
    final children = <ConceptTagNode>[];
    for (final t in nodeMap.values) {
      if (t.parentId == tag.id) {
        children.add(t);
      }
    }
    return ConceptTagNode(
      id: node.id,
      name: node.name,
      parentId: node.parentId,
      children: children,
    );
  }

  List<KnowledgeCardGroup> _buildKnowledgeCardGroups(List<db.KnowledgeCardRow> cards) {
    final groups = <String, List<KnowledgeCardItem>>{};
    for (final c in cards) {
      groups.putIfAbsent(c.category, () => []);
      groups[c.category]!.add(KnowledgeCardItem(id: c.id, title: c.title));
    }
    return groups.entries.map((e) =>
      KnowledgeCardGroup(category: e.key, cards: e.value)
    ).toList();
  }
}

// ═══════════════════════════════════════════════
// 题目详情模型
// ═══════════════════════════════════════════════

class QuestionDetail {
  final db.QuestionRow question;
  final db.ChoiceExtRow? choiceExt;
  final List<db.SubQuestionRow> subQuestions;
  final List<db.SolutionMethodRow> methods;
  final List<db.SolutionStepRow> steps;
  final List<db.ConceptTagRow> tags;

  const QuestionDetail({
    required this.question,
    this.choiceExt,
    required this.subQuestions,
    required this.methods,
    required this.steps,
    required this.tags,
  });
}
