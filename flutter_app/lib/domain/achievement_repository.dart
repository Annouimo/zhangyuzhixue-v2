import '../data/daos/achievement_dao.dart';


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
  const AchievementRepository(this._dao);

  Future<AchievementSummary> getSummary() async {
    final unlocked = await _dao.getUnlockedCount();
    return AchievementSummary(unlockedCount: unlocked, totalCount: 0);
  }

  Future<int> unlockedCount() => _dao.getUnlockedCount();

  Future<List<AchievementCategory>> getCategories() async {
    final progressList = await _dao.getAllProgress();
    final groups = <String, List<AchievementItem>>{};
    for (final p in progressList) {
      final stat = p.isUnlocked == 1 ? 'unlocked' : (p.progress > 0 ? 'in_progress' : 'locked');
      groups.putIfAbsent('成就', () => []).add(AchievementItem(
        iconEmoji: '🏆',
        name: p.achievementCode,
        description: '',
        status: stat,
        unlockedAt: p.unlockedAt,
        progressPercent: (p.progress / 100.0).clamp(0, 100),
        progress: p.progress,
        threshold: 100,
      ));
    }
    return groups.entries.map((e) => AchievementCategory(label: e.key, list: e.value)).toList();
  }
}
