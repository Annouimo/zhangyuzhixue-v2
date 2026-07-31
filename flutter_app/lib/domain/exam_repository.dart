import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared/domain/models.dart';
export 'package:shared/domain/models.dart';
import '../data/daos/question_dao.dart';
import '../data/daos/exam_dao.dart';
import '../data/database/assets_database.dart' as assets_db;
import '../data/database/database_provider.dart';
import 'package:shared/debug/audit_logger.dart';
import '../data/helpers/pdf_helper.dart';
import '../data/sync/sync_manager.dart';
import '../data/sync/sync_types.dart';
import '../data/api/user_api.dart' as api;
import '../data/api/api_client.dart';

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
  const ExamSummary({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.summary,
    this.isPublic = false,
  });
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
    required this.id,
    required this.name,
    required this.authorInfo,
    required this.summary,
    required this.likeCount,
    required this.collectCount,
    required this.createdAt,
    this.isLiked = false,
    this.isCollected = false,
  });
}

/// 收藏组卷摘要
class FavoriteExamSummary {
  final int id;
  final String name;
  final String authorInfo;
  final String summary;
  final bool isLiked;
  const FavoriteExamSummary({
    required this.id,
    required this.name,
    required this.authorInfo,
    required this.summary,
    this.isLiked = false,
  });
}

/// 组卷预览
class ExamPreview {
  final String name;
  final String authorInfo;
  final int choiceCount;
  final int fillCount;
  final int solutionCount;
  final int totalCount;
  final bool isPublic;
  final List<ExamQuestion> questions;
  const ExamPreview({
    required this.name,
    required this.authorInfo,
    required this.choiceCount,
    required this.fillCount,
    required this.solutionCount,
    required this.totalCount,
    required this.isPublic,
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
  final bool isLiked;
  final bool isCollected;
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
    this.isLiked = false,
    this.isCollected = false,
    required this.questions,
  });

  ExamPreviewOther copyWith({
    int? likeCount,
    int? collectCount,
    bool? isLiked,
    bool? isCollected,
  }) {
    return ExamPreviewOther(
      name: name,
      authorInfo: authorInfo,
      choiceCount: choiceCount,
      fillCount: fillCount,
      solutionCount: solutionCount,
      totalCount: totalCount,
      likeCount: likeCount ?? this.likeCount,
      collectCount: collectCount ?? this.collectCount,
      isLiked: isLiked ?? this.isLiked,
      isCollected: isCollected ?? this.isCollected,
      questions: questions,
    );
  }
}

/// 组卷中的题目
class ExamQuestion {
  final int questionId;
  final String title;
  final String questionType;
  final String source;
  final double? difficulty;
  const ExamQuestion({
    required this.questionId,
    required this.title,
    required this.questionType,
    required this.source,
    this.difficulty,
  });
}

/// 答案项
class AnswerItem {
  final String title;
  final String questionType;
  final String answer;
  const AnswerItem({
    required this.title,
    required this.questionType,
    required this.answer,
  });
}

/// 筛选条件
class SearchFilters {
  final String name;
  final String keyword;
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
    this.keyword = '',
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

/// 筛选方案摘要
class FilterPreset {
  final int id;
  final String name;
  const FilterPreset({required this.id, required this.name});
}

/// 安全截断 stem：避免截断点在 $...$ 公式内部导致未闭合 $
/// 搜索到的题目
class SearchQuestion {
  final int id;
  final String title;
  final String questionType;
  final String meta;
  final double difficulty;
  final double calculation;
  const SearchQuestion({
    required this.id,
    required this.title,
    required this.questionType,
    required this.meta,
    required this.difficulty,
    required this.calculation,
  });
}

/// 由题目来源字段动态聚合的套卷摘要。
class VirtualPaper {
  final int year;
  final String examType;
  final String region;
  final int questionCount;

  const VirtualPaper({
    required this.year,
    required this.examType,
    required this.region,
    required this.questionCount,
  });

  String get title => '$year$region$examType';
}

abstract interface class QuestionLibraryRepository {
  Future<FilterOptions> getFilterOptions();

  Future<List<SearchQuestion>> getFilteredQuestions(SearchFilters filters);
}

abstract interface class VirtualPaperRepository {
  Future<List<VirtualPaper>> getVirtualPapers();
}

class LocalVirtualPaperRepository implements VirtualPaperRepository {
  final QuestionDao _questionDao;

  const LocalVirtualPaperRepository(this._questionDao);

  @override
  Future<List<VirtualPaper>> getVirtualPapers() async {
    final papers = await _questionDao.getVirtualPapers();
    return papers
        .map(
          (paper) => VirtualPaper(
            year: paper.year,
            examType: paper.examType,
            region: paper.region,
            questionCount: paper.questionCount,
          ),
        )
        .toList(growable: false);
  }
}

/// 池子不足异常
class InsufficientPoolException implements Exception {
  final String type;
  final int needed;
  final int available;
  const InsufficientPoolException({
    required this.type,
    required this.needed,
    required this.available,
  });
  String get message => '$type 类题目池子不足（需要 $needed 道，池中只有 $available 道）';
  @override
  String toString() => message;
}

/// 组卷 Repository — 本地 + API
class ExamRepository implements QuestionLibraryRepository {
  final QuestionDao _questionDao;
  final ExamDao _examDao;
  late final api.UserApi _userApi;

  ExamRepository(this._questionDao, this._examDao, {api.UserApi? userApi}) {
    _userApi = userApi ?? api.UserApi(ApiClient());
  }

  // ── 发现组卷 ──
  Future<List<ExploreExamSummary>> getExploreList() async {
    // 优先走 API 获取全平台公开组卷
    try {
      final items = await _userApi.getExplorePapers();
      final summaries = items.map((j) {
        final m = j as Map<String, dynamic>;
        return ExploreExamSummary(
          id: m['id'] as int,
          name: m['name'] as String? ?? '',
          authorInfo:
              '作者：${m['author_name'] ?? ''} · Lv.${m['author_level'] ?? ''} · 总积分 ${m['author_points'] ?? 0}',
          summary: m['summary'] as String? ?? '',
          likeCount: m['like_count'] as int? ?? 0,
          collectCount: m['collect_count'] as int? ?? 0,
          createdAt: m['created_at'] as String? ?? '',
          isLiked: m['is_liked'] as bool? ?? false,
          isCollected: m['is_collected'] as bool? ?? false,
        );
      }).toList();
      return summaries
          .map((item) {
            return ExploreExamSummary(
              id: item.id,
              name: item.name,
              authorInfo: item.authorInfo,
              summary: item.summary,
              likeCount: item.likeCount,
              collectCount: item.collectCount,
              createdAt: item.createdAt,
              isLiked: item.isLiked,
              isCollected: item.isCollected,
            );
          })
          .toList(growable: false);
    } catch (e) {
      AuditLogger.instance.error('ExamRepository.getExploreList.api', e);
    }
    // API 失败时回退到本地（仅自己的公开试卷）
    final rows = await _examDao.listPublic();
    final ids = rows.map((r) => r.id).toList();
    final statuses = await _examDao.getExploreStatuses(ids);
    return rows.map((r) {
      final s =
          statuses[r.id] ??
          (liked: false, likeCount: 0, collected: false, collectCount: 0);
      return ExploreExamSummary(
        id: r.id,
        name: r.title,
        authorInfo: '',
        summary: r.description ?? '',
        likeCount: s.likeCount,
        collectCount: s.collectCount,
        createdAt: r.createdAt,
        isLiked: s.liked,
        isCollected: s.collected,
      );
    }).toList();
  }

  Future<void> toggleLike(int paperId) async {
    await _examDao.toggleLikeWithOutbox(paperId);
    try {
      SyncManager().scheduleOutboxPush();
    } catch (e) {
      AuditLogger.instance.sync('enqueue_error', {
        'type': 'toggleLike',
        'error': '$e',
      });
    }
  }

  Future<void> setLike(int paperId, bool active) async {
    await _examDao.setLikeWithOutbox(paperId, active);
    try {
      await SyncManager().pushNow();
    } catch (e) {
      AuditLogger.instance.sync('schedule_error', {
        'type': 'setLike',
        'error': '$e',
      });
    }
  }

  Future<void> toggleCollect(int paperId) async {
    await _examDao.toggleCollectWithOutbox(paperId);
    try {
      SyncManager().scheduleOutboxPush();
    } catch (e) {
      AuditLogger.instance.sync('enqueue_error', {
        'type': 'toggleCollect',
        'error': '$e',
      });
    }
  }

  Future<void> setCollect(int paperId, bool active) async {
    await _examDao.setCollectWithOutbox(paperId, active);
    try {
      await SyncManager().pushNow();
    } catch (e) {
      AuditLogger.instance.sync('schedule_error', {
        'type': 'setCollect',
        'error': '$e',
      });
    }
  }

  // ── 收藏 ──
  Future<List<FavoriteExamSummary>> getFavorites() async {
    final collectedIds = await _examDao.getCollectedPaperIds();
    if (collectedIds.isEmpty) return [];
    // 优先走 API 获取完整的他人组卷详情
    try {
      final items = await _userApi.getFavoritePapers(collectedIds);
      return items.map((j) {
        final m = j as Map<String, dynamic>;
        return FavoriteExamSummary(
          id: m['id'] as int,
          name: m['name'] as String? ?? '',
          authorInfo:
              '作者：${m['author_name'] ?? ''} · Lv.${m['author_level'] ?? ''}',
          summary: m['summary'] as String? ?? '',
          isLiked: m['is_liked'] as bool? ?? false,
        );
      }).toList();
    } catch (e) {
      AuditLogger.instance.error('ExamRepository.getFavorites.api', e);
    }
    // API 失败时回退到本地
    final papers = await _examDao.getByIds(collectedIds);
    return papers
        .map(
          (p) => FavoriteExamSummary(
            id: p.id,
            name: p.title,
            summary: p.description ?? '',
            authorInfo: '',
          ),
        )
        .toList();
  }

  Future<void> removeFavorite(int examId) async {
    await toggleCollect(examId);
  }

  // ── 我的组卷 ──
  Future<List<ExamSummary>> getMyExams() async {
    final rows = await _examDao.listCreated();
    return rows
        .map(
          (r) => ExamSummary(
            id: r.id,
            name: r.title,
            createdAt: r.createdAt,
            summary: r.filterSnapshot ?? '',
            isPublic: r.isPublic == 1,
          ),
        )
        .toList();
  }

  Future<void> togglePublic(int paperId) async {
    final paper = await _examDao.getById(paperId);
    if (paper == null) return;
    final nextPublic = paper.isPublic == 0;
    await DatabaseProvider().appDb.transaction(() async {
      await _examDao.togglePublic(paperId);
      await SyncManager().addToOutbox(
        entityType: SyncEntityType.exam,
        operation: SyncOperationType.upsert,
        localId: paperId,
        payload: jsonEncode({
          'action': 'set_visibility',
          'server_id': paper.serverId,
          'client_id': 'paper-${paper.id}-${paper.createdAt}',
          'is_public': nextPublic,
        }),
      );
    });
    SyncManager().scheduleOutboxPush();
  }

  Future<void> deleteExam(int paperId) async {
    final paper = await _examDao.getById(paperId);
    if (paper == null) return;
    await DatabaseProvider().appDb.transaction(() async {
      await _examDao.deletePaper(paperId);
      await SyncManager().addToOutbox(
        entityType: SyncEntityType.exam,
        operation: SyncOperationType.delete,
        localId: paperId,
        payload: jsonEncode({
          'action': 'delete',
          'server_id': paper.serverId,
          'client_id': 'paper-${paper.id}-${paper.createdAt}',
        }),
      );
    });
    SyncManager().scheduleOutboxPush();
  }

  // ── 预览 ──
  Future<ExamPreview> getPreview(int examId) async {
    final paper = await _examDao.getById(examId);
    if (paper == null) throw Exception('Paper not found: $examId');
    final questions = await _examDao.getQuestions(examId);
    final qIds = questions.map((q) => q.questionId).toList();
    final unorderedRows = await _questionDao.getByIds(qIds);
    final rowsById = {for (final row in unorderedRows) row.id: row};
    final qRows = qIds
        .map((id) => rowsById[id])
        .whereType<assets_db.QuestionRow>()
        .toList();
    return ExamPreview(
      name: paper.title,
      authorInfo: '创建于 ${paper.createdAt.substring(0, 10)}',
      choiceCount: qRows.where((q) => q.questionType == 'choice').length,
      fillCount: qRows.where((q) => q.questionType == 'fill').length,
      solutionCount: qRows.where((q) => q.questionType == 'solution').length,
      totalCount: qRows.length,
      isPublic: paper.isPublic == 1,
      questions: qRows
          .map(
            (q) => ExamQuestion(
              questionId: q.id,
              title: q.stem,
              questionType: q.questionType,
              source: '${q.year} ${q.examType} ${q.region}',
              difficulty: q.difficulty,
            ),
          )
          .toList(),
    );
  }

  Future<ExamPreviewOther> getPreviewOther(int examId) async {
    // 优先走 API 获取全局数据
    try {
      final data = await _userApi.getPreviewOther(examId);
      final serverLiked = data['is_liked'] as bool? ?? false;
      final serverCollected = data['is_collected'] as bool? ?? false;
      final qList =
          (data['questions'] as List<dynamic>?)?.map((j) {
            final m = j as Map<String, dynamic>;
            return ExamQuestion(
              questionId: m['question_id'] as int,
              title: m['title'] as String? ?? '',
              questionType: m['question_type'] as String? ?? '',
              source: m['source'] as String? ?? '',
              difficulty: (m['difficulty'] as num?)?.toDouble(),
            );
          }).toList() ??
          [];
      return ExamPreviewOther(
        name: data['name'] as String? ?? '',
        authorInfo:
            '作者：${data['author_name'] ?? ''} · Lv.${data['author_level'] ?? ''} · ${data['created_at']?.toString().substring(0, 10) ?? ''}',
        choiceCount: data['choice_count'] as int? ?? 0,
        fillCount: data['fill_count'] as int? ?? 0,
        solutionCount: data['solution_count'] as int? ?? 0,
        totalCount: data['total_count'] as int? ?? 0,
        likeCount: data['like_count'] as int? ?? 0,
        collectCount: data['collect_count'] as int? ?? 0,
        isLiked: serverLiked,
        isCollected: serverCollected,
        questions: qList,
      );
    } catch (e) {
      AuditLogger.instance.error('ExamRepository.getPreviewOther.api', e);
    }
    // API 失败时回退到本地
    final paper = await _examDao.getById(examId);
    if (paper == null) throw Exception('Paper not found: $examId');
    final questions = await _examDao.getQuestions(examId);
    final qIds = questions.map((q) => q.questionId).toList();
    final qRows = await _questionDao.getByIds(qIds);
    final localStatus = (await _examDao.getExploreStatuses([examId]))[examId];
    return ExamPreviewOther(
      name: paper.title,
      authorInfo: '',
      choiceCount: qRows.where((q) => q.questionType == 'choice').length,
      fillCount: qRows.where((q) => q.questionType == 'fill').length,
      solutionCount: qRows.where((q) => q.questionType == 'solution').length,
      totalCount: qRows.length,
      likeCount: 0,
      collectCount: 0,
      isLiked: localStatus?.liked ?? false,
      isCollected: localStatus?.collected ?? false,
      questions: qRows
          .map(
            (q) => ExamQuestion(
              questionId: q.id,
              title: q.stem,
              questionType: q.questionType,
              source: '${q.year} ${q.examType} ${q.region}',
              difficulty: q.difficulty,
            ),
          )
          .toList(),
    );
  }

  Future<void> downloadPdf(int paperId, {BuildContext? context}) async {
    await PdfHelper.downloadPdf(
      sourceId: paperId,
      sourceType: 'paper',
      context: context,
    );
  }

  // ── 快对答案 ──
  Future<List<AnswerItem>> getQuickAnswers(int examId) async {
    final questions = await _examDao.getQuestions(examId);
    if (questions.isEmpty) return [];
    final qIds = questions.map((q) => q.questionId).toList();
    final qRows = await _questionDao.getByIds(qIds);
    final qMap = <int, assets_db.QuestionRow>{};
    for (final r in qRows) {
      qMap[r.id] = r;
    }
    final result = <AnswerItem>[];
    String typeLabel(String type) {
      const labels = {'choice': '选择题', 'fill': '填空题', 'solution': '解答题'};
      return labels[type] ?? type;
    }

    for (final q in questions) {
      final baseQ = qMap[q.questionId];
      if (baseQ == null) continue;
      final subs = await _questionDao.getSubQuestions(q.questionId);
      final baseTitle = '${baseQ.number} ${baseQ.examType} ${baseQ.region}';
      final label = typeLabel(baseQ.questionType);
      if (baseQ.questionType == 'solution' && subs.length > 1) {
        for (var i = 0; i < subs.length; i++) {
          result.add(
            AnswerItem(
              title: '$baseTitle (${i + 1})',
              questionType: label,
              answer: subs[i].answer ?? '',
            ),
          );
        }
      } else {
        result.add(
          AnswerItem(
            title: baseTitle,
            questionType: label,
            answer: subs.isNotEmpty ? (subs.first.answer ?? '') : '',
          ),
        );
      }
    }
    return result;
  }

  // ── 筛选方案（委托给 PreferenceRepository） ──
  Future<List<FilterPreset>> getFilterPresets() async {
    // 外部通过 PreferenceRepository.getList() 获取
    return [];
  }

  static List<ConceptTagNode> buildTagTree(
    List<assets_db.ConceptTagRow> tags, {
    List<assets_db.QuestionConceptTagRow> links = const [],
  }) {
    final byParent = <int?, List<assets_db.ConceptTagRow>>{};
    final questionsByTag = <int, Set<int>>{};
    final hasUsageData = links.isNotEmpty;
    for (final t in tags) {
      byParent.putIfAbsent(t.parentId, () => []).add(t);
    }
    for (final link in links) {
      questionsByTag
          .putIfAbsent(link.conceptTagId, () => <int>{})
          .add(link.questionId);
    }
    ConceptTagNode buildNode(assets_db.ConceptTagRow row) {
      final children = (byParent[row.id] ?? []).map(buildNode).toList();
      final questionIds = <int>{...?questionsByTag[row.id]};
      for (final child in children) {
        questionIds.addAll(_conceptQuestionIds(child, questionsByTag));
      }
      return ConceptTagNode(
        id: row.id,
        name: row.name,
        parentId: row.parentId,
        questionCount: questionIds.length,
        children: hasUsageData
            ? children.where((child) => child.questionCount > 0).toList()
            : children,
      );
    }

    return (byParent[null] ?? [])
        .map(buildNode)
        .where((node) => !hasUsageData || node.questionCount > 0)
        .toList();
  }

  static Set<int> _conceptQuestionIds(
    ConceptTagNode node,
    Map<int, Set<int>> direct,
  ) {
    final result = <int>{...?direct[node.id]};
    for (final child in node.children) {
      result.addAll(_conceptQuestionIds(child, direct));
    }
    return result;
  }

  static List<KnowledgeCardGroup> buildKnowledgeCardGroups(
    List<assets_db.KnowledgeCardRow> cards, [
    Map<int, int> questionCounts = const {},
  ]) {
    final byCategory = <String, List<KnowledgeCardItem>>{};
    for (final c in cards) {
      byCategory
          .putIfAbsent(c.category, () => [])
          .add(
            KnowledgeCardItem(
              id: c.id,
              title: c.title,
              questionCount: questionCounts[c.id] ?? 0,
            ),
          );
    }
    return byCategory.entries.map((e) {
      e.value.sort(
        (left, right) => right.questionCount.compareTo(left.questionCount),
      );
      return KnowledgeCardGroup(category: e.key, cards: e.value);
    }).toList();
  }

  static Map<int, int> buildKnowledgeCardCounts(
    List<assets_db.QuestionKnowledgeCardRow> links,
  ) {
    final counts = <int, int>{};
    for (final link in links) {
      counts.update(
        link.knowledgeCardId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    return counts;
  }

  // ── 筛选 ──
  @override
  Future<FilterOptions> getFilterOptions() async {
    final years = (await _questionDao.getDistinctYears())
        .map((y) => y.toString())
        .toList();
    final regions = await _questionDao.getDistinctRegions();
    final tags = await _questionDao.getAllConceptTags();
    final tagLinks = await _questionDao.getAllQuestionTagLinks();
    final kcs = await _questionDao.getAllKnowledgeCards();
    final knowledgeLinks = await _questionDao
        .getAllQuestionKnowledgeCardLinks();
    final knowledgeCounts = buildKnowledgeCardCounts(knowledgeLinks);
    final examTypes = await _questionDao.getDistinctExamTypes();
    return FilterOptions(
      years: years,
      regions: regions,
      conceptTags: tags.map((t) => t.name).toList(),
      conceptTagTree: buildTagTree(tags, links: tagLinks),
      knowledgeCards: kcs.map((k) => k.title).toList(),
      knowledgeCardGroups: buildKnowledgeCardGroups(kcs, knowledgeCounts),
      examTypes: examTypes,
      questionTypes: const ['choice', 'fill', 'solution'],
    );
  }

  @override
  Future<List<SearchQuestion>> getFilteredQuestions(
    SearchFilters filters,
  ) async {
    final q = _questionDao.search(
      keyword: filters.keyword,
      years: filters.years
          .map((y) => int.tryParse(y))
          .whereType<int>()
          .toList(),
      regions: filters.regions.isNotEmpty ? filters.regions : null,
      diffMin: filters.diffMin,
      diffMax: filters.diffMax,
      calcMin: filters.calcMin,
      calcMax: filters.calcMax,
      conceptTagNames: filters.conceptTags.isNotEmpty
          ? filters.conceptTags
          : null,
      knowledgeCardNames: filters.knowledgeCards.isNotEmpty
          ? filters.knowledgeCards
          : null,
      examTypes: filters.examTypes != null && filters.examTypes!.isNotEmpty
          ? filters.examTypes
          : null,
      questionTypes:
          filters.questionTypes != null && filters.questionTypes!.isNotEmpty
          ? filters.questionTypes
          : null,
    );
    return (await q)
        .map(
          (r) => SearchQuestion(
            id: r.id,
            title: r.stem,
            questionType: r.questionType,
            meta: '${r.year} ${r.examType} ${r.region}',
            difficulty: r.difficulty ?? 0,
            calculation: r.calculation ?? 0,
          ),
        )
        .toList();
  }

  Future<PoolStats> getPoolStats(SearchFilters filters) async {
    final engine = _ExamFilterEngine(_questionDao);
    return engine.compute(filters);
  }

  Future<int> getTotalCount(SearchFilters filters) async {
    final questions = await getFilteredQuestions(filters);
    return questions.length;
  }

  Future<int> confirm(
    SearchFilters filters, {
    bool allowShortfall = false,
  }) async {
    final engine = _ExamGenerator(_questionDao, _examDao);
    final paperId = await engine.confirm(
      filters,
      allowShortfall: allowShortfall,
    );
    final paperQuestions = await _examDao.getQuestions(paperId);
    // 入同步队列
    try {
      await SyncManager().enqueue(
        entityType: SyncEntityType.exam,
        operation: SyncOperationType.upsert,
        localId: paperId,
        payload: jsonEncode({
          'title': filters.name.isNotEmpty ? filters.name : '智能选题',
          'questions': paperQuestions.map((item) => item.questionId).toList(),
        }),
      );
    } catch (e) {
      AuditLogger.instance.sync('enqueue_error', {
        'type': 'confirm',
        'error': '$e',
      });
    }
    return paperId;
  }
}

// ── 智能选题算法 ──
// Phase 1: 贪心初始化（按难度差排序取 top N）
// Phase 2: 3 轮交换优化（遍历各题型找最优单题交换，改善整卷均值逼近 targetDifficulty）

/// 筛选池统计引擎
class _ExamFilterEngine {
  final QuestionDao _dao;
  const _ExamFilterEngine(this._dao);

  Future<PoolStats> compute(SearchFilters filters) async {
    final s = await _dao.searchStats(
      keyword: filters.keyword,
      years: filters.years
          .map((y) => int.tryParse(y))
          .whereType<int>()
          .toList(),
      regions: filters.regions.isNotEmpty ? filters.regions : null,
      diffMin: filters.diffMin,
      diffMax: filters.diffMax,
      calcMin: filters.calcMin,
      calcMax: filters.calcMax,
      conceptTagNames: filters.conceptTags.isNotEmpty
          ? filters.conceptTags
          : null,
      knowledgeCardNames: filters.knowledgeCards.isNotEmpty
          ? filters.knowledgeCards
          : null,
      examTypes: filters.examTypes != null && filters.examTypes!.isNotEmpty
          ? filters.examTypes
          : null,
      questionTypes:
          filters.questionTypes != null && filters.questionTypes!.isNotEmpty
          ? filters.questionTypes
          : null,
    );
    return PoolStats(
      availableChoice: s.choice,
      availableFill: s.fill,
      availableSolution: s.solution,
      poolDiffMin: s.diffMin,
      poolDiffMax: s.diffMax,
      gaokaoDiffMin: s.gaokaoDiffMin,
      gaokaoDiffAvg: s.gaokaoDiffAvg,
      gaokaoDiffMax: s.gaokaoDiffMax,
    );
  }
}

class _ExamGenerator {
  final QuestionDao _questionDao;
  final ExamDao _examDao;
  const _ExamGenerator(this._questionDao, this._examDao);

  Future<int> confirm(
    SearchFilters filters, {
    bool allowShortfall = false,
  }) async {
    // 1. 获取筛选池
    final pool = await _questionDao.search(
      keyword: filters.keyword,
      years: filters.years
          .map((y) => int.tryParse(y))
          .whereType<int>()
          .toList(),
      regions: filters.regions.isNotEmpty ? filters.regions : null,
      diffMin: filters.diffMin,
      diffMax: filters.diffMax,
      calcMin: filters.calcMin,
      calcMax: filters.calcMax,
      conceptTagNames: filters.conceptTags.isNotEmpty
          ? filters.conceptTags
          : null,
      knowledgeCardNames: filters.knowledgeCards.isNotEmpty
          ? filters.knowledgeCards
          : null,
      examTypes: filters.examTypes != null && filters.examTypes!.isNotEmpty
          ? filters.examTypes
          : null,
      questionTypes:
          filters.questionTypes != null && filters.questionTypes!.isNotEmpty
          ? filters.questionTypes
          : null,
    );

    // 2. 按题型分类
    var choicePool = pool.where((q) => q.questionType == 'choice').toList();
    var fillPool = pool.where((q) => q.questionType == 'fill').toList();
    var solutionPool = pool.where((q) => q.questionType == 'solution').toList();

    // 2b. 锁定手动选题（selectedIds 固定不动）
    final lockedChoice = <dynamic>[],
        lockedFill = <dynamic>[],
        lockedSolution = <dynamic>[];
    if (filters.selectedIds.isNotEmpty) {
      final lockedRows = await _questionDao.getByIds(filters.selectedIds);
      final lockedIds = lockedRows.map((r) => r.id).toSet();
      for (final r in lockedRows) {
        if (r.questionType == 'choice') {
          lockedChoice.add(r);
        } else if (r.questionType == 'fill') {
          lockedFill.add(r);
        } else if (r.questionType == 'solution') {
          lockedSolution.add(r);
        }
      }
      choicePool.removeWhere((q) => lockedIds.contains(q.id));
      fillPool.removeWhere((q) => lockedIds.contains(q.id));
      solutionPool.removeWhere((q) => lockedIds.contains(q.id));
    }
    final actualChoiceNeeded = (filters.choiceCount - lockedChoice.length)
        .clamp(0, filters.choiceCount);
    final actualFillNeeded = (filters.fillCount - lockedFill.length).clamp(
      0,
      filters.fillCount,
    );
    final actualSolutionNeeded = (filters.solutionCount - lockedSolution.length)
        .clamp(0, filters.solutionCount);

    // 3. 检查池子（扣除已锁定题后的余量）
    void checkPool(List list, int needed, String type) {
      if (!allowShortfall && needed > list.length) {
        throw InsufficientPoolException(
          type: type,
          needed: needed,
          available: list.length,
        );
      }
    }

    checkPool(choicePool, actualChoiceNeeded, 'choice');
    checkPool(fillPool, actualFillNeeded, 'fill');
    checkPool(solutionPool, actualSolutionNeeded, 'solution');

    // 4. 贪心选择（按难度差排序，排除 selectedIds）
    List pick(List pool, int needed) {
      pool.sort(
        (a, b) =>
            (((a as dynamic).difficulty ?? 0.0) - filters.targetDifficulty)
                .abs()
                .compareTo(
                  (((b as dynamic).difficulty ?? 0.0) -
                          filters.targetDifficulty)
                      .abs(),
                ),
      );
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
    final lockedChoiceIds = lockedChoice
        .map((q) => (q as dynamic).id as int)
        .toSet();
    final lockedFillIds = lockedFill
        .map((q) => (q as dynamic).id as int)
        .toSet();
    final lockedSolutionIds = lockedSolution
        .map((q) => (q as dynamic).id as int)
        .toSet();

    for (var round = 0; round < maxSwapRounds; round++) {
      for (final entry in [
        {
          'type': 'choice',
          'pool': choicePool,
          'selected': selectedChoice,
          'lockedIds': lockedChoiceIds,
        },
        {
          'type': 'fill',
          'pool': fillPool,
          'selected': selectedFill,
          'lockedIds': lockedFillIds,
        },
        {
          'type': 'solution',
          'pool': solutionPool,
          'selected': selectedSolution,
          'lockedIds': lockedSolutionIds,
        },
      ]) {
        final sel = entry['selected'] as List;
        final lockedIds = entry['lockedIds'] as Set<int>;
        final cand = (entry['pool'] as List)
            .where((c) => !sel.contains(c))
            .toList();
        if (sel.isEmpty || cand.isEmpty) continue;

        final curMean =
            selected.fold<double>(
              0,
              (s, q) => s + ((q as dynamic).difficulty ?? 0.0),
            ) /
            selected.length;

        double bestImprovement = 0;
        int bestSelIdx = -1;
        dynamic bestCand;

        for (var si = 0; si < sel.length; si++) {
          if (lockedIds.contains((sel[si] as dynamic).id)) {
            continue; // 跳过 locked 题
          }
          final s = sel[si];
          for (final c in cand) {
            final delta =
                (((c as dynamic).difficulty ?? 0.0) -
                    ((s as dynamic).difficulty ?? 0.0)) /
                selected.length;
            final newMean = curMean + delta;
            final improvement =
                (curMean - target).abs() - (newMean - target).abs();
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
    final paperId = await _examDao.savePaper(
      title: filters.name.isNotEmpty ? filters.name : '智能选题',
    );
    await _examDao.savePaperQuestions(
      paperId,
      selected.map((q) => (q as dynamic).id as int).toList(),
    );
    return paperId;
  }
}

// ── 智能选题算法（极简 v1）
