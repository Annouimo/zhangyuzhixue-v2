
import 'dart:convert';
import 'package:flutter/widgets.dart';
import '../data/daos/question_dao.dart';
import '../data/daos/exam_dao.dart';
import '../data/database/assets_database.dart' as assets_db;
import '../data/debug/audit_logger.dart';
import '../data/helpers/pdf_helper.dart';
import '../data/sync/sync_manager.dart';
import '../data/sync/sync_types.dart';

/// 组卷构建状态

/// 组卷构建状态
class ExamBuildState {
  final String name;
  final int selectedCount;
  final int pointsCost;

  const ExamBuildState({
    required this.name,
    required this.selectedCount,
    required this.pointsCost,
  });
}

/// 组卷摘要
class ExamSummary {
  final int id;
  final String name;
  final String createdAt;
  final String summary;
  final bool isPublic;
  const ExamSummary({required this.id, required this.name, required this.createdAt, required this.summary, this.isPublic = false});
}

/// 发现组卷摘要
class ExploreExamSummary {
  final int id;
  final String name;
  final String authorInfo;
  final String summary;
  final int likeCount;
  final int collectCount;
  final String createdAt;
  final bool isLiked;
  final bool isCollected;
  const ExploreExamSummary({
    required this.id, required this.name, required this.authorInfo,
    required this.summary, required this.likeCount, required this.collectCount,
    required this.createdAt, this.isLiked = false, this.isCollected = false,
  });
}

/// 收藏组卷摘要
class FavoriteExamSummary {
  final int id;
  final String name;
  final String authorInfo;
  final String summary;
  final bool isLiked;
  const FavoriteExamSummary({required this.id, required this.name, required this.authorInfo, required this.summary, this.isLiked = false});
}

/// 组卷预览
class ExamPreview {
  final String name;
  final String authorInfo;
  final int choiceCount;
  final int fillCount;
  final int solutionCount;
  final int totalCount;
  final List<ExamQuestion> questions;
  const ExamPreview({
    required this.name, required this.authorInfo,
    required this.choiceCount, required this.fillCount,
    required this.solutionCount, required this.totalCount,
    required this.questions,
  });
}

/// 他人组卷预览
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
    required this.name, required this.authorInfo,
    required this.choiceCount, required this.fillCount,
    required this.solutionCount, required this.totalCount,
    required this.likeCount, required this.collectCount,
    required this.questions,
  });
}

/// 组卷中的题目
class ExamQuestion {
  final int questionId;
  final String title;
  final String meta;
  const ExamQuestion({required this.questionId, required this.title, required this.meta});
}

/// 答案项
class AnswerItem {
  final String title;
  final String questionType;
  final String answer;
  const AnswerItem({required this.title, required this.questionType, required this.answer});
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
  final List<String>? examTypes;
  final List<String>? questionTypes;

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
    this.diffMin, this.diffMax, this.calcMin, this.calcMax,
    this.selectedIds = const [],
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

/// 筛选预设摘要
class FilterPreset {
  final int id;
  final String name;
  const FilterPreset({required this.id, required this.name});
}

/// 搜索到的题目
class SearchQuestion {
  final int id;
  final String title;
  final String meta;
  final double difficulty;
  final double calculation;
  const SearchQuestion({required this.id, required this.title, required this.meta, required this.difficulty, required this.calculation});
}

/// 池子不足异常
class InsufficientPoolException implements Exception {
  final String type;
  final int needed;
  final int available;
  const InsufficientPoolException({required this.type, required this.needed, required this.available});
  String get message => '$type 类题目池子不足（需要 $needed 道，池中只有 $available 道）';
  @override
  String toString() => message;
}

/// 组卷 Repository — 本地 + API
class ExamRepository {
  final QuestionDao _questionDao;
  final ExamDao _examDao;

  const ExamRepository(this._questionDao, this._examDao);

  // ── 发现组卷 ──
  Future<List<ExploreExamSummary>> getExploreList() async {
    final rows = await _examDao.listPublic();
    final futures = rows.map((r) async {
      final like = await _examDao.getLike(r.id);
      final collect = await _examDao.getCollect(r.id);
      final likeCount = await _examDao.getLikeCount(r.id);
      final collectCount = await _examDao.getCollectCount(r.id);
      return ExploreExamSummary(
        id: r.id, name: r.title, authorInfo: '',
        summary: r.description ?? '',
        likeCount: likeCount,
        collectCount: collectCount,
        createdAt: r.createdAt,
        isLiked: like != null, isCollected: collect != null,
      );
    });
    return Future.wait(futures);
  }

  Future<void> toggleLike(int paperId) async {
    await _examDao.toggleLike(paperId);
    // 入同步队列
    try {
      await SyncManager().enqueue(
        entityType: SyncEntityType.paperLike,
        operation: SyncOperationType.upsert,
        localId: paperId,
        payload: jsonEncode({'paper_id': paperId}),
      );
    } catch (e) {
      AuditLogger.instance.sync('enqueue_error', {'type': 'toggleLike', 'error': '$e'});
    }
  }

  Future<void> toggleCollect(int paperId) async {
    await _examDao.toggleCollect(paperId);
    // 入同步队列
    try {
      await SyncManager().enqueue(
        entityType: SyncEntityType.paperCollect,
        operation: SyncOperationType.upsert,
        localId: paperId,
        payload: jsonEncode({'paper_id': paperId}),
      );
    } catch (e) {
      AuditLogger.instance.sync('enqueue_error', {'type': 'toggleCollect', 'error': '$e'});
    }
  }

  // ── 收藏 ──
  Future<List<FavoriteExamSummary>> getFavorites() async {
    final collectedIds = await _examDao.getCollectedPaperIds();
    if (collectedIds.isEmpty) return [];
    final result = <FavoriteExamSummary>[];
    for (final pid in collectedIds) {
      final paper = await _examDao.getById(pid);
      if (paper == null) continue;
      result.add(FavoriteExamSummary(
        id: paper.id,
        name: paper.title,
        summary: paper.description ?? '',
        authorInfo: '',
      ));
    }
    return result;
  }

  Future<void> removeFavorite(int examId) async {
    await _examDao.toggleCollect(examId);
  }

  // ── 我的组卷 ──
  Future<List<ExamSummary>> getMyExams() async {
    final rows = await _examDao.listCreated();
    return rows.map((r) => ExamSummary(
      id: r.id, name: r.title, createdAt: r.createdAt, summary: r.filterSnapshot ?? '',
      isPublic: r.isPublic == 1,
    )).toList();
  }

  Future<void> togglePublic(int paperId) async {
    await _examDao.togglePublic(paperId);
  }

  Future<void> deleteExam(int paperId) async {
    await _examDao.deletePaper(paperId);
  }

  // ── 预览 ──
  Future<ExamPreview> getPreview(int examId) async {
    final paper = await _examDao.getById(examId);
    if (paper == null) throw Exception('Paper not found: $examId');
    final questions = await _examDao.getQuestions(examId);
    final qIds = questions.map((q) => q.questionId).toList();
    final qRows = await _questionDao.getByIds(qIds);
    return ExamPreview(
      name: paper.title,
      authorInfo: '',
      choiceCount: qRows.where((q) => q.questionType == 'choice').length,
      fillCount: qRows.where((q) => q.questionType == 'fill').length,
      solutionCount: qRows.where((q) => q.questionType == 'solution').length,
      totalCount: qRows.length,
      questions: qRows.map((q) => ExamQuestion(
        questionId: q.id,
        title: '${q.number} ${q.examType} ${q.region}',
        meta: q.questionType,
      )).toList(),
    );
  }

  Future<ExamPreviewOther> getPreviewOther(int examId) async {
    final paper = await _examDao.getById(examId);
    if (paper == null) throw Exception('Paper not found: $examId');
    final questions = await _examDao.getQuestions(examId);
    final qIds = questions.map((q) => q.questionId).toList();
    final qRows = await _questionDao.getByIds(qIds);
    final like = await _examDao.getLike(examId);
    final collect = await _examDao.getCollect(examId);
    return ExamPreviewOther(
      name: paper.title,
      authorInfo: '',
      choiceCount: qRows.where((q) => q.questionType == 'choice').length,
      fillCount: qRows.where((q) => q.questionType == 'fill').length,
      solutionCount: qRows.where((q) => q.questionType == 'solution').length,
      totalCount: qRows.length,
      likeCount: like != null ? 1 : 0,
      collectCount: collect != null ? 1 : 0,
      questions: qRows.map((q) => ExamQuestion(
        questionId: q.id,
        title: '${q.number} ${q.examType} ${q.region}',
        meta: q.questionType,
      )).toList(),
    );
  }

  Future<void> downloadPdf(int paperId, {BuildContext? context}) async {
    await PdfHelper.downloadPdf(
      sourceId: paperId, sourceType: 'paper', context: context,
    );
  }

  // ── 快对答案 ──
  Future<List<AnswerItem>> getQuickAnswers(int examId) async {
    final questions = await _examDao.getQuestions(examId);
    final result = <AnswerItem>[];
    for (final q in questions) {
      final subs = await _questionDao.getSubQuestions(q.questionId);
      final answer = subs.isNotEmpty ? subs.first.answer : null;
      result.add(AnswerItem(
        title: '#${q.sortOrder}',
        questionType: '',
        answer: answer ?? '',
      ));
    }
    return result;
  }

  // ── 筛选预设（委托给 PreferenceRepository） ──
  Future<List<FilterPreset>> getFilterPresets() async {
    // 外部通过 PreferenceRepository.getList() 获取
    return [];
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

  // ── 筛选 ──
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

  Future<List<SearchQuestion>> getFilteredQuestions(SearchFilters filters) async {
    final q = _questionDao.search(
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
    return (await q).map((r) => SearchQuestion(
      id: r.id,
      title: r.stem.length > 80 ? '${r.stem.substring(0, 80)}...' : r.stem,
      meta: '${r.year} ${r.examType} ${r.region}',
      difficulty: r.difficulty ?? 0,
      calculation: r.calculation ?? 0,
    )).toList();
  }

  Future<PoolStats> getPoolStats(SearchFilters filters) async {
    final engine = _ExamFilterEngine(_questionDao);
    return engine.compute(filters);
  }

  Future<int> getTotalCount(SearchFilters filters) async {
    final questions = await getFilteredQuestions(filters);
    return questions.length;
  }

  Future<int> confirm(SearchFilters filters, {bool allowShortfall = false}) async {
    final engine = _ExamGenerator(_questionDao, _examDao);
    final paperId = await engine.confirm(filters, allowShortfall: allowShortfall);
    // 入同步队列
    try {
      await SyncManager().enqueue(
        entityType: SyncEntityType.exam,
        operation: SyncOperationType.upsert,
        localId: paperId,
        payload: jsonEncode({
          'title': filters.name.isNotEmpty ? filters.name : '智能组卷',
          'questions': filters.selectedIds.isNotEmpty
              ? filters.selectedIds
              : [],
        }),
      );
    } catch (e) {
      AuditLogger.instance.sync('enqueue_error', {'type': 'confirm', 'error': '$e'});
    }
    return paperId;
  }
}

// ── 智能组卷算法 ──
// Phase 1: 贪心初始化（按难度差排序取 top N）
// Phase 2: 3 轮交换优化（遍历各题型找最优单题交换，改善整卷均值逼近 targetDifficulty）

/// 筛选池统计引擎
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

    var choicePool = pool.where((q) => q.questionType == 'choice').toList();
    var fillPool = pool.where((q) => q.questionType == 'fill').toList();
    var solutionPool = pool.where((q) => q.questionType == 'solution').toList();

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

class _ExamGenerator {
  final QuestionDao _questionDao;
  final ExamDao _examDao;
  const _ExamGenerator(this._questionDao, this._examDao);

  Future<int> confirm(SearchFilters filters, {bool allowShortfall = false}) async {
    // 1. 获取筛选池
    final pool = await _questionDao.search(
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

    // 2. 按题型分类
    var choicePool = pool.where((q) => q.questionType == 'choice').toList();
    var fillPool = pool.where((q) => q.questionType == 'fill').toList();
    var solutionPool = pool.where((q) => q.questionType == 'solution').toList();

    // 2b. 锁定手动选题（selectedIds 固定不动）
    final lockedChoice = <dynamic>[], lockedFill = <dynamic>[], lockedSolution = <dynamic>[];
    if (filters.selectedIds.isNotEmpty) {
      final lockedRows = await _questionDao.getByIds(filters.selectedIds);
      final lockedIds = lockedRows.map((r) => r.id).toSet();
      for (final r in lockedRows) {
        if (r.questionType == 'choice') { lockedChoice.add(r); }
        else if (r.questionType == 'fill') { lockedFill.add(r); }
        else if (r.questionType == 'solution') { lockedSolution.add(r); }
      }
      choicePool.removeWhere((q) => lockedIds.contains(q.id));
      fillPool.removeWhere((q) => lockedIds.contains(q.id));
      solutionPool.removeWhere((q) => lockedIds.contains(q.id));
    }
    final actualChoiceNeeded = (filters.choiceCount - lockedChoice.length).clamp(0, filters.choiceCount);
    final actualFillNeeded = (filters.fillCount - lockedFill.length).clamp(0, filters.fillCount);
    final actualSolutionNeeded = (filters.solutionCount - lockedSolution.length).clamp(0, filters.solutionCount);

    // 3. 检查池子（扣除已锁定题后的余量）
    void checkPool(List list, int needed, String type) {
      if (!allowShortfall && needed > list.length) {
        throw InsufficientPoolException(type: type, needed: needed, available: list.length);
      }
    }
    checkPool(choicePool, actualChoiceNeeded, 'choice');
    checkPool(fillPool, actualFillNeeded, 'fill');
    checkPool(solutionPool, actualSolutionNeeded, 'solution');

    // 4. 贪心选择（按难度差排序，排除 selectedIds）
    List pick(List pool, int needed) {
      pool.sort((a, b) => (((a as dynamic).difficulty ?? 0.0) - filters.targetDifficulty).abs()
          .compareTo((((b as dynamic).difficulty ?? 0.0) - filters.targetDifficulty).abs()));
      return pool.take(needed).toList();
    }

    final pickedChoice = pick(choicePool, actualChoiceNeeded);
    final pickedFill = pick(fillPool, actualFillNeeded);
    final pickedSolution = pick(solutionPool, actualSolutionNeeded);
    final selectedChoice = [...lockedChoice, ...pickedChoice];
    final selectedFill = [...lockedFill, ...pickedFill];
    final selectedSolution = [...lockedSolution, ...pickedSolution];
    var selected = [...selectedChoice, ...selectedFill, ...selectedSolution];

    // 5. 3 轮交换优化：遍历各题型，找能改善整体均值的最优交换（跳过 locked 题）
    final target = filters.targetDifficulty;
    const maxSwapRounds = 3;
    final lockedChoiceIds = lockedChoice.map((q) => (q as dynamic).id as int).toSet();
    final lockedFillIds = lockedFill.map((q) => (q as dynamic).id as int).toSet();
    final lockedSolutionIds = lockedSolution.map((q) => (q as dynamic).id as int).toSet();

    for (var round = 0; round < maxSwapRounds; round++) {
      for (final entry in [
        {'type': 'choice', 'pool': choicePool, 'selected': selectedChoice, 'lockedIds': lockedChoiceIds},
        {'type': 'fill', 'pool': fillPool, 'selected': selectedFill, 'lockedIds': lockedFillIds},
        {'type': 'solution', 'pool': solutionPool, 'selected': selectedSolution, 'lockedIds': lockedSolutionIds},
      ]) {
        final sel = entry['selected'] as List;
        final lockedIds = entry['lockedIds'] as Set<int>;
        final cand = (entry['pool'] as List).where((c) => !sel.contains(c)).toList();
        if (sel.isEmpty || cand.isEmpty) continue;

        final curMean = selected.fold<double>(0, (s, q) => s + ((q as dynamic).difficulty ?? 0.0)) / selected.length;

        double bestImprovement = 0;
        int bestSelIdx = -1;
        dynamic bestCand;

        for (var si = 0; si < sel.length; si++) {
          if (lockedIds.contains((sel[si] as dynamic).id)) continue; // 跳过 locked 题
          final s = sel[si];
          for (final c in cand) {
            final delta = (((c as dynamic).difficulty ?? 0.0) - ((s as dynamic).difficulty ?? 0.0)) / selected.length;
            final newMean = curMean + delta;
            final improvement = (curMean - target).abs() - (newMean - target).abs();
            if (improvement > bestImprovement) {
              bestImprovement = improvement;
              bestSelIdx = si;
              bestCand = c;
            }
          }
        }

        if (bestSelIdx >= 0 && bestCand != null) {
          sel[bestSelIdx] = bestCand;
          selected = [...selectedChoice, ...selectedFill, ...selectedSolution];
        }
      }
    }

    // 6. 持久化
    final paperId = await _examDao.savePaper(title: filters.name.isNotEmpty ? filters.name : '智能组卷');
    await _examDao.savePaperQuestions(paperId, selected.map((q) => (q as dynamic).id as int).toList());
    return paperId;
  }
}

// ── 智能组卷算法（极简 v1）