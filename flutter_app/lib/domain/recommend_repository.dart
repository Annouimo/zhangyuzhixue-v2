import '../data/daos/question_dao.dart';
import '../data/daos/progress_dao.dart';

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
  const RecommendRepository(this._questionDao, this._progressDao);

  Future<List<RecommendedQuestion>> getSmartList() async {
    final engine = _RecommendationEngine(_questionDao, _progressDao);
    return engine.compute();
  }

  Future<List<RecommendPreset>> getPresets() async {
    return [];
  }

  Future<List<PresetQuestion>> getPresetQuestions(int presetId) async {
    return [];
  }
}

// ── 推荐算法引擎 ──
class _RecommendationEngine {
  final QuestionDao _questionDao;
  final ProgressDao _progressDao;

  const _RecommendationEngine(this._questionDao, this._progressDao);

  static const int coldStartThreshold = 5;

  Future<List<RecommendedQuestion>> compute() async {
    final allQuestions = await _questionDao.getAll();
    if (allQuestions.isEmpty) return [];

    // 冷启动：做题数 < 5 时返回空
    int totalAttempts = 0;
    for (final q in allQuestions) {
      if (await _progressDao.hasAttempt(q.id)) totalAttempts++;
      if (totalAttempts >= coldStartThreshold) break;
    }
    if (totalAttempts < coldStartThreshold) return [];

    final allTags = await _questionDao.getAllConceptTags();
    final doneIds = await _getDoneQuestionIds();

    // 路线A：选填题 — 概念掌握度
    final weakTag = await _findWeakestConcept(allTags);
    final choiceFill = <RecommendedQuestion>[];
    if (weakTag != null) {
      // 取该概念下未做的 choice/fill 题，按难度适配
      final candidates = <dynamic>[];
      for (final q in allQuestions) {
        if (doneIds.contains(q.id)) continue;
        if (q.questionType == 'solution') continue;
        final tags = await _questionDao.getTagsByQuestion(q.id);
        if (tags.any((t) => t.id == weakTag.id)) {
          candidates.add(q);
        }
      }
      final wrongIds = await _getRecentWrongIds();
      for (final q in candidates) {
        if (choiceFill.length >= 4) break;
        if (wrongIds.contains((q as dynamic).id)) continue;
        choiceFill.add(RecommendedQuestion(
          id: (q as dynamic).id,
          title: (q.stem as String).length > 80 ? '${(q.stem as String).substring(0, 80)}...' : (q.stem as String),
          questionType: (q as dynamic).questionType,
          difficulty: (q as dynamic).difficulty ?? 0.0,
          recommendReason: '薄弱概念：${weakTag.name}',
          status: 'pending',
        ));
      }
    }

    // 路线B：解答题 — 知识卡片卡住率
    // 取用户未解答的 solution 题，优先从做错较多的概念推荐
    final solution = <RecommendedQuestion>[];
    for (final q in allQuestions) {
      if (solution.length >= 2) break;
      if (q.questionType != 'solution') continue;
      if (doneIds.contains(q.id)) continue;
      solution.add(RecommendedQuestion(
        id: q.id,
        title: q.stem.length > 80 ? '${q.stem.substring(0, 80)}...' : q.stem,
        questionType: q.questionType,
        difficulty: q.difficulty ?? 0.0,
        recommendReason: '推荐练习解答题',
        status: 'pending',
      ));
    }

    // 合并排序：choice ×2, fill ×2, solution ×2
    final result = <RecommendedQuestion>[];
    final c = choiceFill.where((r) => r.questionType == 'choice').take(2).toList();
    final f = choiceFill.where((r) => r.questionType == 'fill').take(2).toList();
    result.addAll(c);
    result.addAll(f);
    result.addAll(solution.take(2));
    return result;
  }

  /// 找掌握度最低的概念
  /// 遍历各概念标签，计算该标签下所有已做题的正确率，取掌握度最低的标签
  Future<dynamic> _findWeakestConcept(List<dynamic> allTags) async {
    if (allTags.isEmpty) return null;
    final mastery = <int, double>{};
    for (final tag in allTags) {
      final tagQuestions = <int>[];
      final allQs = await _questionDao.getAll();
      for (final q in allQs) {
        final tags = await _questionDao.getTagsByQuestion(q.id);
        if (tags.any((t) => t.id == tag.id)) tagQuestions.add(q.id);
      }
      if (tagQuestions.isEmpty) { mastery[tag.id] = double.infinity; continue; }
      var correct = 0;
      var total = 0;
      for (final qId in tagQuestions) {
        for (final a in await _progressDao.getAttempts(qId)) {
          total++;
          if (a.isCorrect == 1) correct++;
        }
      }
      mastery[tag.id] = total > 0 ? correct / total : double.infinity;
    }
    dynamic best;
    double? bestScore;
    for (final tag in allTags) {
      final score = mastery[tag.id] ?? double.infinity;
      if (best == null || score < bestScore!) { best = tag; bestScore = score; }
    }
    return best;
  }

  Future<Set<int>> _getDoneQuestionIds() async {
    final available = await _questionDao.getAll();
    final done = <int>{};
    for (final q in available) {
      if (await _progressDao.hasAttempt(q.id)) done.add(q.id);
    }
    return done;
  }

  Future<Set<int>> _getRecentWrongIds() async {
    return _progressDao.getRecentWrongQuestionIds(3);
  }
}
