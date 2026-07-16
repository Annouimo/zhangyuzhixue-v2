/// 树状概念标签节点
class ConceptTagNode {
  final int id;
  final String name;
  final int? parentId;
  final List<ConceptTagNode> children;
  const ConceptTagNode({
    required this.id,
    required this.name,
    this.parentId,
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
