import 'dart:async';
import '../data/daos/user_dao.dart';
import '../data/api/user_api.dart';
import '../data/daos/question_dao.dart';
import '../data/prefs/app_prefs.dart';
import '../data/database/app_database.dart' as db;
import 'package:shared/debug/audit_logger.dart';

/// 用户信息
class UserInfo {
  final int id;
  final String name;
  final String? realName;
  final String? studentId;
  final String? avatar;
  final String? school;
  final String? gaokaoYear;
  final String? phone;

  const UserInfo({
    required this.id,
    required this.name,
    this.realName,
    this.studentId,
    this.avatar,
    this.school,
    this.gaokaoYear,
    this.phone,
  });
}

/// 做题历史
class HistoryItem {
  final int id;
  final String title;
  final String questionType;
  final int questionId;
  final String date;
  final String status;
  final String source;
  final double? difficulty;

  bool get isCompleted => status == 'completed';

  const HistoryItem({
    required this.id,
    required this.title,
    required this.questionType,
    required this.questionId,
    required this.date,
    required this.status,
    required this.source,
    this.difficulty,
  });
}

/// 积分记录
class PointsRecord {
  final String time;
  final String type;
  final double change;
  final double earned;
  final double bonus;
  final double spent;
  final double available;

  const PointsRecord({
    required this.time,
    required this.type,
    required this.change,
    required this.earned,
    required this.bonus,
    required this.spent,
    required this.available,
  });
}

/// 等级行
class LevelRow {
  final int level;
  final String range;
  final String title;
  final String? iconEmoji;
  const LevelRow({
    required this.level,
    required this.range,
    required this.title,
    this.iconEmoji,
  });
}

/// 首页任务状态
class TaskState {
  final bool done;
  final bool inProgress;
  final String label;
  final String rewardText;
  final double reward;
  const TaskState({
    required this.done,
    required this.inProgress,
    required this.label,
    required this.rewardText,
    required this.reward,
  });
}

/// 用户 Repository — 本地 + API
class UserRepository {
  static const bool _performanceTestMode = bool.fromEnvironment(
    'PERFORMANCE_TEST_MODE',
  );

  final UserDao _dao;
  final UserApi _api;
  final QuestionDao _questionDao;

  UserRepository(this._dao, this._api, this._questionDao);

  Future<UserInfo> getUserInfo() async {
    final local = await _dao.getProfile();
    if (local != null) {
      // 有本地缓存：立即返回，后台调 API 刷新
      if (!_performanceTestMode) unawaited(_refreshProfileFromApi());
      return UserInfo(
        id: local.id,
        name: local.name,
        realName: local.realName,
        studentId: local.studentId,
        avatar: local.avatar,
        school: local.school,
        gaokaoYear: local.gaokaoYear,
        phone: local.phone,
      );
    }
    // 无本地缓存：从 API 获取并回写
    final remote = await _api.getInfo();
    await _dao.saveProfile(
      id: remote['id'] as int,
      name: remote['username'] as String,
      realName: remote['real_name'] as String?,
      studentId: remote['student_id'] as String?,
      avatar: remote['avatar'] as String?,
      gaokaoYear: (remote['gaokao_year'] as Object?)?.toString(),
    );
    return UserInfo(
      id: remote['id'] as int,
      name: remote['username'] as String,
      realName: remote['real_name'] as String?,
      studentId: remote['student_id'] as String?,
      avatar: remote['avatar'] as String?,
      gaokaoYear: (remote['gaokao_year'] as Object?)?.toString(),
    );
  }

  /// 后台刷新用户信息（API 覆盖本地缓存，静默失败）
  Future<void> _refreshProfileFromApi() async {
    try {
      final remote = await _api.getInfo();
      // 读当前本地缓存，保住 API 不返回的字段（school、phone）
      final local = await _dao.getProfile();
      await _dao.saveProfile(
        id: remote['id'] as int,
        name: remote['username'] as String,
        realName: remote['real_name'] as String?,
        studentId: remote['student_id'] as String?,
        avatar: remote['avatar'] as String?,
        school: local?.school,
        gaokaoYear: (remote['gaokao_year'] as Object?)?.toString(),
        phone: local?.phone,
      );
      AuditLogger.instance.sync('refreshProfile',
          {'id': remote['id'], 'name': remote['username']});
    } catch (e) {
      AuditLogger.instance.error('UserRepository._refreshProfileFromApi', e);
    }
  }

  Future<void> saveProfile(UserInfo data) async {
    await _dao.saveProfile(
      id: data.id,
      name: data.name,
      realName: data.realName,
      studentId: data.studentId,
      avatar: data.avatar,
      school: data.school,
      gaokaoYear: data.gaokaoYear,
      phone: data.phone,
    );
    await _api.updateProfile({
      if (data.realName != null) 'real_name': data.realName,
      'gaokao_year': data.gaokaoYear,
    });
  }

  Future<String> uploadAvatar(String localPath) => _api.uploadAvatar(localPath);

  Future<List<HistoryItem>> getAnswerHistory() async {
    // 从本地 submission_detail 取最近做题记录
    final submissions = await _dao.getRecentSubmissions(limit: 10);
    final items = <HistoryItem>[];
    for (final s in submissions) {
      String qType = '';
      String title = '#${s.questionId}';
      String source = '';
      double? difficulty;
      try {
        final q = await _questionDao.getById(s.questionId);
        if (q != null) {
          qType = q.questionType;
          title = q.stem;
          source = '${q.year} ${q.examType} ${q.region}';
          difficulty = q.difficulty;
        }
      } catch (_) {}
      items.add(
        HistoryItem(
          id: s.id,
          title: title,
          questionType: qType,
          questionId: s.questionId,
          date: s.createdAt.substring(0, 10),
          status: s.status,
          source: source,
          difficulty: difficulty,
        ),
      );
    }
    return items;
  }

  Future<int> getAnswerHistoryCount() async {
    final total = await _dao.getTotalSubmissions();
    return total;
  }

  // ── 积分 ──
  static const Map<String, String> _sourceLabels = {
    'LOGIN_BONUS': '签到',
    'PRACTICE_REWARD': '做题',
    'TASK_REWARD': '完成任务',
    'REVIEW_REWARD': '退出评价',
    'RATING_REWARD': '题目评价',
    'SIGNUP_BONUS': '新人赠送',
    'PAPER_PURCHASE': '组卷',
    'ADMIN_ADJUST': '管理员调整',
  };

  Future<List<PointsRecord>> getPointsHistory() async {
    final rows = await _dao.getPointsHistory();
    // 计算每行的累计值。rows 按 createdAt DESC（最新在前）。
    // 从最旧的行（数组末端）向前遍历，逐行累积四种积分。
    var cumEarned = 0.0, cumBonus = 0.0, cumSpent = 0.0;
    final records = <PointsRecord>[];
    for (var i = rows.length - 1; i >= 0; i--) {
      final r = rows[i];
      if (r.source == 'PRACTICE_REWARD') {
        cumEarned += r.amount;
      } else if (['LOGIN_BONUS', 'TASK_REWARD', 'SIGNUP_BONUS', 'REVIEW_REWARD', 'RATING_REWARD', 'ADMIN_ADJUST'].contains(r.source)) {
        cumBonus += r.amount;
      } else if (r.source == 'PAPER_PURCHASE') {
        cumSpent += r.amount.abs();
      }
      records.add(PointsRecord(
        time: r.createdAt,
        type: _sourceLabels[r.source] ?? r.source,
        change: r.amount,
        earned: cumEarned,
        bonus: cumBonus,
        spent: cumSpent,
        available: cumEarned + cumBonus - cumSpent,
      ));
    }
    // records 现在是倒序（最新在前），最前面已经是累加到最后的值
    // 但我们需要每行是"到该笔交易时的累计值" — 从旧到新累积后反转
    // 因为我们是反向遍历（从旧到新），records 是按 createdAt ASC 添加的
    // 所以需要再反转一次得到 DESC（最新在前）
    return records.reversed.toList();
  }

  /// 一次性获取所有积分汇总（earned + bonus + spent + available）
  /// 使用 Drift 原生聚合，1 次 DB 查询替代全量加载+Dart 循环
  Future<({double earned, double bonus, double spent, double available})> getPointsSummary() =>
      _dao.getPointsSummaryAggregated();

  Future<double> earnedPoints() async => (await _dao.getEarnedPoints()).toDouble();

  /// 一次性获取所有积分行，通过 _PointsCalculator 计算四种积分汇总
  Future<({double earned, double bonus, double spent, double available})> _computePointsSummary() async {
    final rows = await _dao.getPointsHistory();
    final calc = _PointsCalculator(rows);
    return (
      earned: calc.earned,
      bonus: calc.bonus,
      spent: calc.spent,
      available: calc.available,
    );
  }

  Future<double> bonusPoints() async {
    final s = await _computePointsSummary();
    return s.bonus;
  }

  Future<double> spentPoints() async {
    final s = await _computePointsSummary();
    return s.spent;
  }

  Future<double> availablePoints() async {
    final s = await _computePointsSummary();
    return s.available;
  }

  Future<double> todayPoints() async {
    final earned = await _dao.getTodayEarnedPoints();
    return earned.toDouble();
  }

  /// 今日做题统计
  Future<({int total, int correct})> getTodaySubmissionStats() =>
      _dao.getTodaySubmissionStats();

  // ── 首页任务 ──

  /// 任务状态
  static const _taskDefs = [
    (label: '开张有礼（完成第1题）', threshold: 1, reward: 0.5),
    (label: '小试牛刀（完成5题）', threshold: 5, reward: 1.0),
    (label: '精益求精（正确完成3题）', threshold: 3, reward: 1.0),
    (label: '更进一步（完成15题）', threshold: 15, reward: 2.0),
  ];

  /// 今日任务状态
  static List<TaskState> computeTodayTasks(int total, int correct) {
    final results = <TaskState>[];
    for (var i = 0; i < _taskDefs.length; i++) {
      final d = _taskDefs[i];
      final done = i == 2 ? correct >= d.threshold : total >= d.threshold;
      final prevDone = i == 0 || results.last.done;
      results.add(TaskState(
        done: done,
        inProgress: !done && prevDone,
        label: d.label,
        rewardText: d.reward.toStringAsFixed(1),
        reward: d.reward,
      ));
    }
    return results;
  }

  /// 今日签到奖励（基于连续天数）
  static double todayReward(int streakDays) => 0.5 + (streakDays % 7) * 0.3;
  static double nextReward(int streakDays) => 0.5 + ((streakDays + 1) % 7) * 0.3;

  /// 今日签到奖励文本
  static String todayRewardText(int streakDays) =>
      todayReward(streakDays).toStringAsFixed(1);
  static String nextRewardText(int streakDays) =>
      nextReward(streakDays).toStringAsFixed(1);

  // ── 等级 ──
  Future<List<LevelRow>> getLevels() async {
    final configs = await _questionDao.getAllLevelConfigs();
    final list = <LevelRow>[];
    for (var i = 0; i < configs.length; i++) {
      final c = configs[i];
      final isLast = i + 1 >= configs.length;
      final range = isLast
          ? '${c.minXp}+'
          : '${c.minXp} ~ ${configs[i + 1].minXp - 1}';
      list.add(LevelRow(
        level: c.level,
        range: range,
        title: c.title,
        iconEmoji: c.iconEmoji,
      ));
    }
    return list;
  }

  /// 当前等级编号（推算）
  Future<int> currentLevel() async {
    final lv = await getLevelAndProgress();
    return lv.level;
  }

  Future<String> levelProgress() async {
    final lv = await getLevelAndProgress();
    return lv.progress;
  }

  /// 一次性获取等级+进度（共享一次 earnedPoints + getAllLevelConfigs 查询）
  Future<({int level, String progress})> getLevelAndProgress() async {
    final totalPoints = await earnedPoints();
    final configs = await _questionDao.getAllLevelConfigs();
    if (configs.isEmpty) return (level: 1, progress: '0/0');
    final totalXp = totalPoints.toInt();
    int? currentMin, nextMin;
    int lv = 1;
    for (var i = 0; i < configs.length; i++) {
      if (configs[i].minXp <= totalXp) {
        currentMin = configs[i].minXp;
        nextMin = i + 1 < configs.length ? configs[i + 1].minXp : configs[i].minXp;
        lv = configs[i].level;
      } else {
        break;
      }
    }
    if (currentMin == null || nextMin == null) return (level: 1, progress: '0/0');
    final range = nextMin - currentMin;
    final progress = totalXp - currentMin;
    return (level: lv, progress: '$progress/$range');
  }

  /// 从本地缓存读取等级百分位（秒开，不调 API）
  int getCachedLevelPercentile() => AppPrefs().levelPercentile;

  /// 从 API 刷新等级百分位，失败时回退缓存
  Future<int> levelPercentile() async {
    try {
      final data = await _api.getLevelPercentile();
      final raw = data['level_percentile'];
      final result = (raw is num) ? raw.toInt() : 0;
      if (result > 0) AppPrefs().setLevelPercentile(result);
      return result;
    } catch (_) {
      return AppPrefs().levelPercentile;
    }
  }

  // ── 签到 ──
  Future<int> streakDays() => _dao.getStreakDays();

  /// 签到（调用 API）
  Future<Map<String, dynamic>> checkin() async {
    return _api.checkin();
  }

  Future<String> questionBankVersion() async => AppPrefs().qbankVersion.toString();

}

// ── 积分计算引擎 ──
class _PointsCalculator {
  final List<db.PointsTransactionRow> _rows;
  _PointsCalculator(this._rows);

  double get earned {
    var total = 0.0;
    for (final r in _rows) {
      if (r.source == 'PRACTICE_REWARD') {
        total += r.amount;
      }
    }
    return total;
  }

  double get bonus {
    var total = 0.0;
    for (final r in _rows) {
      if (['LOGIN_BONUS', 'TASK_REWARD', 'SIGNUP_BONUS', 'REVIEW_REWARD', 'RATING_REWARD', 'ADMIN_ADJUST'].contains(r.source)) {
        total += r.amount;
      }
    }
    return total;
  }

  double get spent {
    var total = 0.0;
    for (final r in _rows) {
      if (r.source == 'PAPER_PURCHASE') total += r.amount;
    }
    return total.abs();
  }

  double get available => earned + bonus - spent;
}
