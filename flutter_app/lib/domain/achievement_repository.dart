import '../data/daos/achievement_dao.dart';
import '../data/daos/question_dao.dart';
import '../data/daos/exam_dao.dart';
import '../data/database/assets_database.dart' as assets;
import '../data/database/app_database.dart' as user_db;

/// 成就摘要
class AchievementSummary {
  final int unlockedCount;
  final int totalCount;
  const AchievementSummary({required this.unlockedCount, required this.totalCount});
}

/// 单条成就
class AchievementItem {
  final String iconEmoji;
  final String name;
  final String description;
  final String status;
  final String? unlockedAt;
  final double progressPercent;
  final int progress;
  final int threshold;

  const AchievementItem({
    required this.iconEmoji,
    required this.name,
    required this.description,
    required this.status,
    this.unlockedAt,
    required this.progressPercent,
    required this.progress,
    required this.threshold,
  });

  String get statusLabel {
    switch (status) {
      case 'unlocked': return '已解锁';
      case 'in_progress': return '进行中';
      default: return '未解锁';
    }
  }

  /// ACCURACY_RATE 成就的进度文本带 % 后缀
  bool get isAccuracyRate => threshold >= 50 && threshold <= 100 && progress <= 100;
}

/// 成就分类
class AchievementCategory {
  final String label;
  final List<AchievementItem> list;
  const AchievementCategory({required this.label, required this.list});
}

/// 成就 Repository
class AchievementRepository {
  final AchievementDao _dao;
  final QuestionDao _questionDao;
  final ExamDao _examDao;
  const AchievementRepository(this._dao, this._questionDao, this._examDao);

  Future<AchievementSummary> getSummary() async {
    final cats = await getCategories();
    int unlocked = 0, total = 0;
    for (final cat in cats) {
      for (final a in cat.list) {
        total++;
        if (a.status == 'unlocked') unlocked++;
      }
    }
    return AchievementSummary(unlockedCount: unlocked, totalCount: total);
  }

  Future<int> unlockedCount() => _dao.getUnlockedCount();

  Future<List<AchievementCategory>> getCategories() async {
    final defs = await _questionDao.getAllAchievementDefs();
    final progressList = await _dao.getAllProgress();
    final progressMap = {for (final p in progressList) p.achievementCode: p};

    final engine = _AchievementEngine(_dao, _examDao);
    final grouped = <String, List<AchievementItem>>{};
    for (final def in defs) {
      final label = def.categoryLabel ?? def.category;
      grouped.putIfAbsent(label, () => []);
      final cached = progressMap[def.code];
      final item = await engine.compute(def, cached);
      grouped[label]!.add(item);

      // 缓存已解锁记录
      if (item.status == 'unlocked' && (cached == null || cached.isUnlocked == 0)) {
        await _dao.upsertProgress(
          achievementCode: def.code,
          progress: item.progress,
          isUnlocked: 1,
          unlockedAt: DateTime.now().toIso8601String().substring(0, 10),
        );
      }
    }
    return grouped.entries.map((e) => AchievementCategory(label: e.key, list: e.value)).toList();
  }
}

// ── 成就引擎 ──
class _AchievementEngine {
  final AchievementDao _dao;
  final ExamDao _examDao;
  const _AchievementEngine(this._dao, this._examDao);

  Future<AchievementItem> compute(assets.AchievementDefRow def, user_db.StudentAchievementRow? cached) async {
    final threshold = def.threshold ?? 1;

    int progress;
    switch (def.triggerType) {
      case 'LOGIN_STREAK':
        progress = await _dao.getLoginStreak();
        break;
      case 'PRACTICE_COUNT':
        progress = await _dao.getSubmissionCount();
        break;
      case 'PAPER_COUNT':
        progress = await _examDao.getPaperCount();
        break;
      case 'RATING_COUNT':
        progress = await _dao.getRatingCount();
        break;
      case 'PRACTICE_STREAK':
        progress = await _dao.getPracticeStreak();
        break;
      case 'CONSECUTIVE_CORRECT':
        progress = await _dao.getMaxConsecutiveCorrect();
        break;
      case 'ACCURACY_RATE': {
        final (correct, total) = await _dao.getAccuracyStats();
        progress = total > 0 ? (correct * 100 ~/ total) : 0;
        final pct = (progress / threshold * 100.0).clamp(0.0, 100.0);
        final isUnlocked = progress >= threshold && total >= 10;
        final status = isUnlocked ? 'unlocked' : (total > 0 ? 'in_progress' : 'locked');
        return AchievementItem(
          iconEmoji: def.iconEmoji ?? '🏆',
          name: def.name,
          description: def.description ?? '',
          status: status,
          unlockedAt: cached?.unlockedAt,
          progressPercent: pct,
          progress: progress,
          threshold: threshold,
        );
      }
      default:
        progress = 0;
    }

    final pct = (progress / threshold * 100.0).clamp(0.0, 100.0);
    final isUnlocked = progress >= threshold;
    final status = isUnlocked ? 'unlocked' : (progress > 0 ? 'in_progress' : 'locked');

    return AchievementItem(
      iconEmoji: def.iconEmoji ?? '🏆',
      name: def.name,
      description: def.description ?? '',
      status: status,
      unlockedAt: cached?.unlockedAt,
      progressPercent: pct,
      progress: progress,
      threshold: threshold,
    );
  }
}
