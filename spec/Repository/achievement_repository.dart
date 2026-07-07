/// 章鱼智学 — AchievementRepository
/// data-db: achievement.*
/// 对应页面：achievement.html, profile.html(已解锁成就数)

class AchievementSummary {
  final int unlockedCount;
  final int totalCount;

  const AchievementSummary({
    required this.unlockedCount,
    required this.totalCount,
  });

  factory AchievementSummary.fromJson(Map<String, dynamic> json) =>
      AchievementSummary(
        unlockedCount: json['unlocked_count'] as int,
        totalCount: json['total_count'] as int,
      );
}

class AchievementCategory {
  final String label;
  final List<AchievementItem> list;

  const AchievementCategory({
    required this.label,
    required this.list,
  });

  factory AchievementCategory.fromJson(Map<String, dynamic> json) =>
      AchievementCategory(
        label: json['label'] as String,
        list: (json['list'] as List)
            .map((e) =>
                AchievementItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AchievementItem {
  final String iconEmoji;
  final String name;
  final String description;
  final String status; // unlocked / in_progress / locked
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

  factory AchievementItem.fromJson(Map<String, dynamic> json) =>
      AchievementItem(
        iconEmoji: json['icon_emoji'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        status: json['status'] as String,
        unlockedAt: json['unlocked_at'] as String?,
        progressPercent: (json['progress_percent'] as num).toDouble(),
        progress: json['progress'] as int,
        threshold: json['threshold'] as int,
      );

  /// 根据 status 计算的 CSS 类名
  String get statusClass {
    switch (status) {
      case 'unlocked':
        return 'unlocked';
      case 'in_progress':
        return 'in-progress';
      default:
        return 'locked';
    }
  }

  /// 根据 status 计算的中文标签
  String get statusLabel {
    switch (status) {
      case 'unlocked':
        return '已解锁';
      case 'in_progress':
        return '进行中';
      default:
        return '未解锁';
    }
  }
}

class AchievementRepository {
  /// GET /api/achievements/summary/
  static Future<AchievementSummary> getSummary() async {
    throw UnimplementedError('AchievementRepository.getSummary');
  }

  /// 已解锁数（profile.html 快捷用法）
  static Future<int> unlockedCount() async {
    throw UnimplementedError('AchievementRepository.unlockedCount');
  }

  /// GET /api/achievements/categories/
  static Future<List<AchievementCategory>> getCategories() async {
    throw UnimplementedError('AchievementRepository.getCategories');
  }
}

// ---- 成就引擎 ----
// 按类型分组、判断解锁状态、计算进度百分比
class _AchievementEngine {
  // 扫描用户数据判断每个成就的状态：
  //   LOGIN → 签到记录数
  //   PRACTICE → 做题数
  //   COURSE → 已学讲义数
  //   PAPER → 组卷数
  //   RATING → 评分数
  // 计算：progress / threshold * 100 = progressPercent
}
