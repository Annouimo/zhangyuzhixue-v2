import 'dart:math';
import '../data/daos/question_dao.dart';
import '../data/daos/progress_dao.dart';
import '../data/daos/preference_dao.dart';
import '../data/database/database_provider.dart';
import '../data/database/assets_database.dart' as assets_db;
import '../data/database/app_database.dart' as user_db;
import 'preference_repository.dart';
import '../debug/performance_trace.dart';

/// 推荐题目
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
}

/// 推荐预设
class RecommendPreset {
  final int id;
  final String name;
  const RecommendPreset({required this.id, required this.name});
}

/// 预设题目
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
}

/// 推荐 Repository
class RecommendRepository {
  final QuestionDao _questionDao;
  final ProgressDao _progressDao;
  final PreferenceRepository _prefRepo;

  RecommendRepository(this._questionDao, this._progressDao)
    : _prefRepo = PreferenceRepository(PreferenceDao(DatabaseProvider()));

  RecommendRepository.withPrefRepo(
    this._questionDao,
    this._progressDao,
    this._prefRepo,
  );

  Future<List<RecommendedQuestion>> getSmartList() async {
    final engine = _RecommendationEngine(_questionDao, _progressDao);
    return PerformanceTrace.instance.measureAsync(
      'repository',
      'RecommendRepository.getSmartList',
      engine.compute,
      resultMetadata: (questions) => {'resultCount': questions.length},
    );
  }

  Future<List<RecommendPreset>> getPresets() async {
    final list = await _prefRepo.getList();
    return list.map((p) => RecommendPreset(id: p.id, name: p.name)).toList();
  }

  Future<List<PresetQuestion>> getPresetQuestions(int presetId) async {
    try {
      final editData = await _prefRepo.getEdit(presetId);
      final f = editData.filter;
      final candidates = await _questionDao.search(
        years: f.years.map((y) => int.tryParse(y)).whereType<int>().toList(),
        regions: f.regions.isNotEmpty ? f.regions : null,
        diffMin: f.diffMin,
        diffMax: f.diffMax,
        calcMin: f.calcMin,
        calcMax: f.calcMax,
        conceptTagNames: f.conceptTags.isNotEmpty ? f.conceptTags : null,
        knowledgeCardNames: f.knowledgeCards.isNotEmpty
            ? f.knowledgeCards
            : null,
        examTypes: f.types.isNotEmpty ? f.types : null,
        questionTypes: f.questionTypes.isNotEmpty ? f.questionTypes : null,
        limit: 50,
      );
      return candidates
          .take(20)
          .map(
            (q) => PresetQuestion(
              id: q.id,
              title: '${q.year} ${q.region} ${q.examType}',
              questionType: q.questionType,
              difficulty: q.difficulty ?? 0,
              status: 'pending',
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}

// ── 推荐算法引擎 ──
class _RecommendationEngine {
  final QuestionDao _questionDao;
  final ProgressDao _progressDao;
  const _RecommendationEngine(this._questionDao, this._progressDao);

  static const double decayLambda = 0.099;
  static const int minConfidence = 5;

  /// 智能推荐计算 — 7 次 DB 查询（预加载 + 纯内存计算）
  Future<List<RecommendedQuestion>> compute() async {
    // ── 一次性预加载全部数据（共 7 次查询）──
    final trace = PerformanceTrace.instance;
    final allQuestions = await trace.measureAsync(
      'dao',
      'recommend.questions.getAll',
      _questionDao.getAll,
      resultMetadata: (rows) => {'rows': rows.length},
    );
    if (allQuestions.isEmpty) return [];

    final allAttemptRows = await trace.measureAsync(
      'dao',
      'recommend.attempts.getAll',
      _progressDao.getAllAttempts,
      resultMetadata: (rows) => {'rows': rows.length},
    );
    final tagLinks = await trace.measureAsync(
      'dao',
      'recommend.tagLinks.getAll',
      _questionDao.getAllQuestionTagLinks,
      resultMetadata: (rows) => {'rows': rows.length},
    );
    final allTags = await trace.measureAsync(
      'dao',
      'recommend.tags.getAll',
      _questionDao.getAllConceptTags,
      resultMetadata: (rows) => {'rows': rows.length},
    );

    final computeSpan = trace.start('compute', 'recommend.rankCandidates');

    // tagId → Set<questionId>
    final tagQuestionMap = <int, Set<int>>{};
    // questionId → Set<tagId>
    final questionTagMap = <int, Set<int>>{};
    for (final link in tagLinks) {
      tagQuestionMap
          .putIfAbsent(link.conceptTagId, () => {})
          .add(link.questionId);
      questionTagMap
          .putIfAbsent(link.questionId, () => {})
          .add(link.conceptTagId);
    }

    // questionId → List<SubmissionDetailRow>
    final attemptsMap = <int, List<user_db.SubmissionDetailRow>>{};
    for (final a in allAttemptRows) {
      attemptsMap.putIfAbsent(a.questionId, () => []).add(a);
    }

    final attemptedIds = allAttemptRows.map((r) => r.questionId).toSet();
    final doneIds = attemptedIds;

    // 路线 R：最近答错的原题。复习由系统混入，不单独暴露队列。
    final recentWrongIds = await trace.measureAsync(
      'dao',
      'recommend.recentWrongIds',
      () => _progressDao.getRecentWrongQuestionIds(14),
      resultMetadata: (rows) => {'rows': rows.length},
    );
    final review = allQuestions
        .where((q) => recentWrongIds.contains(q.id))
        .map(
          (q) => RecommendedQuestion(
            id: q.id,
            title: q.stem,
            questionType: q.questionType,
            difficulty: q.difficulty ?? 0.0,
            recommendReason: '巩固近期错题',
            status: _computeStatus(q.id, attemptsMap),
          ),
        )
        .take(4)
        .toList();

    // 路线A：选填题 — 概念掌握度（纯内存）
    final weakTag = _findWeakestConcept(allTags, tagQuestionMap, attemptsMap);
    final choiceFill = <RecommendedQuestion>[];
    if (weakTag != null) {
      final taggedQIds = tagQuestionMap[weakTag.id] ?? {};
      final candidates = allQuestions
          .where(
            (q) =>
                !doneIds.contains(q.id) &&
                q.questionType != 'solution' &&
                taggedQIds.contains(q.id),
          )
          .toList();

      for (final q in candidates) {
        if (choiceFill.length >= 4) break;
        choiceFill.add(
          RecommendedQuestion(
            id: q.id,
            title: q.stem,
            questionType: q.questionType,
            difficulty: q.difficulty ?? 0.0,
            recommendReason: '薄弱概念：${weakTag.name}',
            status: _computeStatus(q.id, attemptsMap),
          ),
        );
      }
    }

    // 路线B：解答题 — 按概念标签排序
    final solution = <RecommendedQuestion>[];
    final solutionCandidates = allQuestions
        .where((q) => q.questionType == 'solution' && !doneIds.contains(q.id))
        .toList();
    if (solutionCandidates.isNotEmpty) {
      // 按 weakTag 匹配度排序：有 weakTag 标签的解答题优先
      final wrongIds = recentWrongIds;
      solutionCandidates.sort((a, b) {
        final aHasWeak =
            weakTag != null &&
            (questionTagMap[a.id]?.contains(weakTag.id) == true);
        final bHasWeak =
            weakTag != null &&
            (questionTagMap[b.id]?.contains(weakTag.id) == true);
        if (aHasWeak != bHasWeak) return aHasWeak ? -1 : 1;
        // 其次按错误上下文排序
        final aWrongContext = wrongIds.any(
          (wid) => (questionTagMap[wid] ?? {})
              .intersection(questionTagMap[a.id] ?? {})
              .isNotEmpty,
        );
        final bWrongContext = wrongIds.any(
          (wid) => (questionTagMap[wid] ?? {})
              .intersection(questionTagMap[b.id] ?? {})
              .isNotEmpty,
        );
        if (aWrongContext != bWrongContext) return aWrongContext ? -1 : 1;
        return 0;
      });
      for (final q in solutionCandidates) {
        if (solution.length >= 2) break;
        final reason =
            weakTag != null &&
                (questionTagMap[q.id]?.contains(weakTag.id) == true)
            ? '薄弱概念：${weakTag.name}'
            : '解答题推荐练习';
        solution.add(
          RecommendedQuestion(
            id: q.id,
            title: q.stem,
            questionType: q.questionType,
            difficulty: q.difficulty ?? 0.0,
            recommendReason: reason,
            status: _computeStatus(q.id, attemptsMap),
          ),
        );
      }
    }

    // 冷启动或没有可用薄弱标签时，以未做题建立探索池。
    final exploration = allQuestions
        .where((q) => !doneIds.contains(q.id))
        .map(
          (q) => RecommendedQuestion(
            id: q.id,
            title: q.stem,
            questionType: q.questionType,
            difficulty: q.difficulty ?? 0.0,
            recommendReason: attemptedIds.isEmpty ? '了解你的当前水平' : '拓展新的题目',
            status: 'pending',
          ),
        )
        .take(10)
        .toList();

    // 旧题和新题交错，随后用探索题补足一个小批次。
    final result = <RecommendedQuestion>[];
    final fresh = <RecommendedQuestion>[
      ...choiceFill,
      ...solution,
      ...exploration,
    ];
    var reviewIndex = 0;
    var freshIndex = 0;
    while (result.length < 10 &&
        (reviewIndex < review.length || freshIndex < fresh.length)) {
      if (result.length % 3 == 1 && reviewIndex < review.length) {
        result.add(review[reviewIndex++]);
      } else if (freshIndex < fresh.length) {
        final candidate = fresh[freshIndex++];
        if (!result.any((item) => item.id == candidate.id)) {
          result.add(candidate);
        }
      } else {
        result.add(review[reviewIndex++]);
      }
    }
    computeSpan.finish({
      'questions': allQuestions.length,
      'attempts': allAttemptRows.length,
      'tagLinks': tagLinks.length,
      'resultCount': result.length,
    });
    return result;
  }

  /// 根据 attemptsMap 判断题目真实状态
  String _computeStatus(
    int questionId,
    Map<int, List<user_db.SubmissionDetailRow>> attemptsMap,
  ) {
    final attempts = attemptsMap[questionId];
    if (attempts == null || attempts.isEmpty) return 'pending';
    if (attempts.any((a) => a.isCorrect == null)) return 'in_progress';
    return 'completed';
  }

  /// 纯内存查找最薄弱概念 — 零 DB 查询
  assets_db.ConceptTagRow? _findWeakestConcept(
    List<assets_db.ConceptTagRow> allTags,
    Map<int, Set<int>> tagQuestionMap,
    Map<int, List<user_db.SubmissionDetailRow>> attemptsMap,
  ) {
    if (allTags.isEmpty) return null;
    final mastery = <int, double>{};
    final now = DateTime.now();

    for (final tag in allTags) {
      final tagQIds = tagQuestionMap[tag.id] ?? {};
      if (tagQIds.isEmpty) continue;

      var weightedCorrect = 0.0;
      var weightedTotal = 0.0;
      for (final qId in tagQIds) {
        for (final a in attemptsMap[qId] ?? []) {
          if (a.isCorrect == null) continue;
          final daysAgo = now.difference(DateTime.parse(a.createdAt)).inDays;
          final weight = exp(-decayLambda * daysAgo);
          weightedTotal += weight;
          if (a.isCorrect == 1) weightedCorrect += weight;
        }
      }
      if (weightedTotal <= 0) continue;
      final rawMastery = weightedCorrect / weightedTotal;
      final shrinkage = weightedTotal / (weightedTotal + minConfidence);
      mastery[tag.id] = 1.0 - (shrinkage * rawMastery + (1 - shrinkage) * 0.5);
    }

    assets_db.ConceptTagRow? best;
    double? bestScore;
    for (final tag in allTags) {
      final score = mastery[tag.id];
      if (score == null) continue;
      if (best == null || score > bestScore!) {
        best = tag;
        bestScore = score;
      }
    }
    return best;
  }
}
