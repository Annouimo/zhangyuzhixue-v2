import '../data/daos/achievement_dao.dart';
import '../data/daos/question_dao.dart';
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
  const AchievementRepository(this._dao, this._questionDao);

  Future<AchievementSummary> getSummary() async {
    final defs = await _questionDao.getAllAchievementDefs();
    final unlocked = await _dao.getUnlockedCount();
    return AchievementSummary(unlockedCount: unlocked, totalCount: defs.length);
  }

  Future<int> unlockedCount() => _dao.getUnlockedCount();

  Future<List<AchievementCategory>> getCategories() async {
    final defs = await _questionDao.getAllAchievementDefs();
    final progressList = await _dao.getAllProgress();
    final progressMap = {for (final p in progressList) p.achievementCode: p};

    final engine = _AchievementEngine(_dao);
    final grouped = <String, List<AchievementItem>>{};
    for (final def in defs) {
      final label = def.categoryLabel ?? def.category;
      grouped.putIfAbsent(label, () => []);
      final cached = progressMap[def.code];
      final item = await engine.compute(def, cached);
      grouped[label]!.add(item);
    }
    return grouped.entries.map((e) => AchievementCategory(label: e.key, list: e.value)).toList();
  }
}

// ── 成就引擎 ──
class _AchievementEngine {
  final AchievementDao _dao;
  const _AchievementEngine(this._dao);

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
        progress = 0; // 需 ExamDao 提供
        break;
      case 'RATING_COUNT':
        progress = await _dao.getRatingCount();
        break;
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
      unlockedAt: null,
      progressPercent: pct,
      progress: progress,
      threshold: threshold,
    );
  }
}
