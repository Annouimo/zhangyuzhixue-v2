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
// 从 AchievementDao 获取定义和用户数据，在 Dart 侧推算状态。
//
// achievement_def 表结构（数据来源：数据库结构设计.md §5.6）：
//   code          VARCHAR UNIQUE    标识（LOGIN_7, COURSE_MASTER 等）
//   category      VARCHAR            5 类：LOGIN / PRACTICE / COURSE / PAPER / RATING
//   trigger_type  VARCHAR            判定类型：LOGIN_STREAK / PRACTICE_COUNT / COURSE_COMPLETE / PAPER_COUNT / RATING_COUNT
//   threshold     INTEGER            达成阈值（如连续签到 7 天、做题 100 道）
//
// 调用链（通过 DAO 获取，不在引擎内写 SQL）：
//   LOGIN    → dao.getLoginStreak() 返回连续签到天数
//   PRACTICE → dao.getSubmissionCount() 返回做题总数
//   COURSE   → dao.getCompletedLectureCount() 返回已学完讲义数
//   PAPER    → dao.getPaperCount() 返回组卷数
//   RATING   → dao.getRatingCount() 返回评分数
//
// 判定：
//   progress >= threshold → unlocked（同时写 student_achievement 缓存）
//   progress > 0          → in_progress
//   其余                    → locked
//
// 进度百分比：min(progress / threshold * 100, 100)
//
// student_achievement 表（数据库结构设计.md §5.7）仅缓存已解锁记录，
// 引擎每次实时推算，不依赖缓存。
class _AchievementEngine {
}
