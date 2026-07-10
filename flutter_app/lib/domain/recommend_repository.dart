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
  const RecommendRepository(this._questionDao, this._progressDao);

  Future<List<RecommendedQuestion>> getSmartList() async {
    final engine = _RecommendationEngine(_questionDao, _progressDao);
    return engine.compute();
  }

  Future<List<RecommendPreset>> getPresets() async {
    // 偏好预设由 PreferenceRepository 提供，这里返回空
    return [];
  }

  Future<List<PresetQuestion>> getPresetQuestions(int presetId) async {
    return [];
  }
}

// ── 推荐算法引擎（极简 v1） ──
// ⚠️ 极简 v1 方案，与同事讨论后替换为正式方案。
// 替换时只需重写 _RecommendationEngine 类，外部模块不受影响。
//
// v1 方案：
//   1. 统计所有概念标签的做题记录
//   2. 取做题最少的 3 个概念标签
//   3. 每个标签取 1 道没做过的题
//
// 已知缺点：
//   - 不区分权重/难度匹配
//   - 不做时间衰减
//   - 不做解答题路线B（卡片卡住率）
class _RecommendationEngine {
  final QuestionDao _questionDao;
  final ProgressDao _progressDao;

  const _RecommendationEngine(this._questionDao, this._progressDao);

  static const int maxItems = 6;

  Future<List<RecommendedQuestion>> compute() async {
    final allTags = await _questionDao.getAllConceptTags();
    final tagCounts = <int, int>{};
    for (final tag in allTags) {
      tagCounts[tag.id] = 0;
    }

    // 统计各标签已做题数
    final allQuestions = await _questionDao.getAll();
    for (final q in allQuestions) {
      final hasAttempt = await _progressDao.hasAttempt(q.id);
      if (hasAttempt) {
        final tags = await _questionDao.getTagsByQuestion(q.id);
        for (final tag in tags) {
          tagCounts[tag.id] = (tagCounts[tag.id] ?? 0) + 1;
        }
      }
    }

    // 取做题最少的 3 个标签
    final sorted = tagCounts.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final weakTags = sorted.take(3).map((e) => e.key).toList();

    // 从这些标签中找未做题
    final result = <RecommendedQuestion>[];
    for (final tagId in weakTags) {
      final tag = allTags.firstWhere((t) => t.id == tagId);
      for (final q in allQuestions) {
        if (result.length >= maxItems) break;
        final qTags = await _questionDao.getTagsByQuestion(q.id);
        if (qTags.any((t) => t.id == tagId)) {
          final done = await _progressDao.hasAttempt(q.id);
          if (!done) {
            result.add(RecommendedQuestion(
              id: q.id,
              title: q.stem.length > 80 ? '${q.stem.substring(0, 80)}...' : q.stem,
              questionType: q.questionType,
              difficulty: q.difficulty ?? 0,
              recommendReason: '薄弱概念：${tag.name}',
              status: 'pending',
            ));
          }
        }
      }
    }

    return result;
  }
}
