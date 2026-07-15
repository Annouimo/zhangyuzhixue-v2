import 'dart:math';
import '../data/daos/question_dao.dart';
import '../data/daos/progress_dao.dart';
import '../data/daos/preference_dao.dart';
import '../data/database/database_provider.dart';
import '../data/database/assets_database.dart' as assets_db;
import '../data/database/app_database.dart' as user_db;
import 'preference_repository.dart';

/// 推荐题目
class RecommendedQuestion {
  final int id;
  final String title;
  final String questionType;
  final double difficulty;
  final String recommendReason;
  final String status;

  const RecommendedQuestion({required this.id, required this.title, required this.questionType, required this.difficulty, required this.recommendReason, required this.status});
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
  const PresetQuestion({required this.id, required this.title, required this.questionType, required this.difficulty, required this.status});
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
    return engine.compute();
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
      knowledgeCardNames: f.knowledgeCards.isNotEmpty ? f.knowledgeCards : null,
      examTypes: f.types.isNotEmpty ? f.types : null,
      questionTypes: f.questionTypes.isNotEmpty ? f.questionTypes : null,
      limit: 50,
    );
    return candidates.take(20).map((q) => PresetQuestion(
      id: q.id,
      title: '${q.year} ${q.region} ${q.examType}',
      questionType: q.questionType,
      difficulty: q.difficulty ?? 0,
      status: 'pending',
    )).toList();
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

  static const int coldStartThreshold = 5;
  static const double decayLambda = 0.099;
  static const int minConfidence = 5;

  /// 智能推荐计算 — 7 次 DB 查询（预加载 + 纯内存计算）
  Future<List<RecommendedQuestion>> compute() async {
    // ── 一次性预加载全部数据（共 7 次查询）──
    final allQuestions = await _questionDao.getAll();
    if (allQuestions.isEmpty) return [];

    final allAttemptRows = await _progressDao.getAllAttempts();
    final tagLinks = await _questionDao.getAllQuestionTagLinks();
    final allTags = await _questionDao.getAllConceptTags();

    // tagId → Set<questionId>
    final tagQuestionMap = <int, Set<int>>{};
    // questionId → Set<tagId>
    final questionTagMap = <int, Set<int>>{};
    for (final link in tagLinks) {
      tagQuestionMap.putIfAbsent(link.conceptTagId, () => {}).add(link.questionId);
      questionTagMap.putIfAbsent(link.questionId, () => {}).add(link.conceptTagId);
    }

    // questionId → List<SubmissionDetailRow>
    final attemptsMap = <int, List<user_db.SubmissionDetailRow>>{};
    for (final a in allAttemptRows) {
      attemptsMap.putIfAbsent(a.questionId, () => []).add(a);
    }

    // 冷启动：做题数 < 5 时返回空
    final attemptedIds = allAttemptRows.map((r) => r.questionId).toSet();
    int totalAttempts = 0;
    for (final q in allQuestions) {
      if (attemptedIds.contains(q.id)) totalAttempts++;
      if (totalAttempts >= coldStartThreshold) break;
    }
    if (totalAttempts < coldStartThreshold) return [];

    // 全部 completed 的 attempt 都是 correct → "已掌握"空状态
    final judgedAttempts = allAttemptRows.where((a) => a.isCorrect != null).toList();
    if (judgedAttempts.isNotEmpty && judgedAttempts.every((a) => a.isCorrect == 1)) {
      return [];
    }

    final doneIds = attemptedIds;

    // 路线A：选填题 — 概念掌握度（纯内存）
    final weakTag = _findWeakestConcept(
      allTags, tagQuestionMap, attemptsMap,
    );
    final choiceFill = <RecommendedQuestion>[];
    if (weakTag != null) {
      final taggedQIds = tagQuestionMap[weakTag.id] ?? {};
      final candidates = allQuestions.where((q) =>
        !doneIds.contains(q.id) &&
        q.questionType != 'solution' &&
        taggedQIds.contains(q.id)
      ).toList();

      final wrongIds = await _getRecentWrongIds();
      for (final q in candidates) {
        if (choiceFill.length >= 4) break;
        if (wrongIds.contains(q.id)) continue;
        choiceFill.add(RecommendedQuestion(
          id: q.id,
          title: q.stem,
          questionType: q.questionType,
          difficulty: q.difficulty ?? 0.0,
          recommendReason: '薄弱概念：${weakTag.name}',
          status: _computeStatus(q.id, attemptsMap),
        ));
      }
    }

    // 路线B：解答题 — 按概念标签排序
    final solution = <RecommendedQuestion>[];
    final solutionCandidates = allQuestions.where((q) =>
      q.questionType == 'solution' && !doneIds.contains(q.id)
    ).toList();
    if (solutionCandidates.isNotEmpty) {
      // 按 weakTag 匹配度排序：有 weakTag 标签的解答题优先
      final wrongIds = await _getRecentWrongIds();
      solutionCandidates.sort((a, b) {
        final aHasWeak = weakTag != null && (questionTagMap[a.id]?.contains(weakTag.id) == true);
        final bHasWeak = weakTag != null && (questionTagMap[b.id]?.contains(weakTag.id) == true);
        if (aHasWeak != bHasWeak) return aHasWeak ? -1 : 1;
        // 其次按错误上下文排序
        final aWrongContext = wrongIds.any((wid) =>
          (questionTagMap[wid] ?? {}).intersection(questionTagMap[a.id] ?? {}).isNotEmpty
        );
        final bWrongContext = wrongIds.any((wid) =>
          (questionTagMap[wid] ?? {}).intersection(questionTagMap[b.id] ?? {}).isNotEmpty
        );
        if (aWrongContext != bWrongContext) return aWrongContext ? -1 : 1;
        return 0;
      });
      for (final q in solutionCandidates) {
        if (solution.length >= 2) break;
        final reason = weakTag != null && (questionTagMap[q.id]?.contains(weakTag.id) == true)
            ? '薄弱概念：${weakTag.name}'
            : '解答题推荐练习';
        solution.add(RecommendedQuestion(
          id: q.id,
          title: q.stem,
          questionType: q.questionType,
          difficulty: q.difficulty ?? 0.0,
          recommendReason: reason,
          status: _computeStatus(q.id, attemptsMap),
        ));
      }
    }

    // 合并
    final result = <RecommendedQuestion>[];
    final c = choiceFill.where((r) => r.questionType == 'choice').take(2).toList();
    final f = choiceFill.where((r) => r.questionType == 'fill').take(2).toList();
    result.addAll(c);
    result.addAll(f);
    result.addAll(solution.take(2));
    return result;
  }

  /// 根据 attemptsMap 判断题目真实状态
  String _computeStatus(int questionId, Map<int, List<user_db.SubmissionDetailRow>> attemptsMap) {
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
      if (tagQIds.isEmpty) { mastery[tag.id] = double.infinity; continue; }

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
      if (weightedTotal <= 0) { mastery[tag.id] = double.infinity; continue; }
      final rawMastery = weightedCorrect / weightedTotal;
      final shrinkage = weightedTotal / (weightedTotal + minConfidence);
      mastery[tag.id] = 1.0 - (shrinkage * rawMastery + (1 - shrinkage) * 0.5);
    }

    assets_db.ConceptTagRow? best;
    double? bestScore;
    for (final tag in allTags) {
      final score = mastery[tag.id] ?? double.infinity;
      if (best == null || score < bestScore!) { best = tag; bestScore = score; }
    }
    return best;
  }

  Future<Set<int>> _getRecentWrongIds() async {
    return _progressDao.getRecentWrongQuestionIds(3);
  }
}
