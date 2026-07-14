import '../data/daos/user_dao.dart';
import '../data/api/user_api.dart';
import '../data/daos/question_dao.dart';
import '../data/prefs/app_prefs.dart';
import '../data/database/app_database.dart' as db;

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
  final String title;
  final String questionType;
  final String date;
  final String status;

  const HistoryItem({
    required this.title,
    required this.questionType,
    required this.date,
    required this.status,
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
  const LevelRow({required this.level, required this.range});
}

/// 用户 Repository — 本地 + API
class UserRepository {
  final UserDao _dao;
  final UserApi _api;
  final QuestionDao _questionDao;

  UserRepository(this._dao, this._api, this._questionDao);
  Future<UserInfo> getUserInfo() async {
    final local = await _dao.getProfile();
    if (local != null) {
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
    // fallback: 从 API 获取
    final remote = await _api.getInfo();
    return UserInfo(
      id: remote['id'] as int,
      name: remote['username'] as String,
      realName: remote['real_name'] as String?,
      studentId: remote['student_id'] as String?,
      avatar: remote['avatar'] as String?,
      gaokaoYear: (remote['gaokao_year'] as Object?)?.toString(),
    );
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
    return submissions.map((s) => HistoryItem(
      title: '#${s.questionId}',
      questionType: '',
      date: s.createdAt.substring(0, 10),
      status: s.status,
    )).toList();
  }

  Future<int> getAnswerHistoryCount() async {
    final total = await _dao.getTotalSubmissions();
    return total;
  }

  // ── 积分 ──
  Future<List<PointsRecord>> getPointsHistory() async {
    final rows = await _dao.getPointsHistory();
    final calc = _PointsCalculator(rows);
    return rows.map((r) => PointsRecord(
      time: r.createdAt,
      type: r.source,
      change: r.amount.toDouble(),
      earned: calc.earned.toDouble(),
      bonus: calc.bonus.toDouble(),
      spent: calc.spent.toDouble(),
      available: calc.available.toDouble(),
    )).toList();
  }

  Future<double> earnedPoints() async => (await _dao.getEarnedPoints()).toDouble();

  /// 一次性获取所有积分行，通过 _PointsCalculator 计算四种积分汇总
  Future<({double earned, double bonus, double spent, double available})> _computePointsSummary() async {
    final rows = await _dao.getPointsHistory();
    final calc = _PointsCalculator(rows);
    return (
      earned: calc.earned.toDouble(),
      bonus: calc.bonus.toDouble(),
      spent: calc.spent.toDouble(),
      available: calc.available.toDouble(),
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

  // ── 等级 ──
  Future<List<LevelRow>> getLevels() async {
    final configs = await _questionDao.getAllLevelConfigs();
    final list = <LevelRow>[];
    for (var i = 0; i < configs.length; i++) {
      final c = configs[i];
      final nextMin = i + 1 < configs.length ? configs[i + 1].minXp : c.minXp * 2;
      list.add(LevelRow(
        level: c.level,
        range: '${c.minXp} ~ ${nextMin - 1}',
      ));
    }
    return list;
  }

  /// 当前等级编号（推算）
  Future<int> currentLevel() async {
    final totalPoints = await earnedPoints();
    final configs = await _questionDao.getAllLevelConfigs();
    if (configs.isEmpty) return 1;
    int lv = 1;
    for (var i = 0; i < configs.length; i++) {
      if (configs[i].minXp <= totalPoints.toInt()) {
        lv = configs[i].level;
      } else {
        break;
      }
    }
    return lv;
  }

  Future<String> levelProgress() async {
    final totalPoints = await earnedPoints();
    final configs = await _questionDao.getAllLevelConfigs();
    if (configs.isEmpty) return '0/0';
    final totalXp = totalPoints.toInt();
    // 找当前等级
    int? currentMin;
    int? nextMin;
    for (var i = 0; i < configs.length; i++) {
      if (configs[i].minXp <= totalXp) {
        currentMin = configs[i].minXp;
        nextMin = i + 1 < configs.length ? configs[i + 1].minXp : configs[i].minXp;
      } else {
        break;
      }
    }
    if (currentMin == null || nextMin == null) return '0/0';
    final range = nextMin - currentMin;
    final progress = totalXp - currentMin;
    return '$progress/$range';
  }

  Future<int> levelPercentile() async {
    try {
      final info = await _api.getInfo();
      final raw = info['level_percentile'];
      return (raw is num) ? raw.toInt() : 0;
    } catch (_) {
      return 0;
    }
  }

  // ── 签到 ──
  Future<int> streakDays() => _dao.getStreakDays();

  /// 签到（调用 API）
  Future<Map<String, dynamic>> checkin() async {
    return _api.checkin();
  }

  Future<String> questionBankVersion() async => AppPrefs().qbankVersion.toString();

  /// 从 user_profile 读取 accessible_course_ids 并缓存到 AppPrefs
  Future<void> syncAccessibleCourseIds() async {
    final raw = await _dao.getAccessibleCourseIds();
    if (raw != null && raw.isNotEmpty) {
      final ids = raw.split(',').map((e) => int.tryParse(e.trim()) ?? 0)
          .where((id) => id > 0).toList();
      if (ids.isNotEmpty) {
        await AppPrefs().setAccessibleCourseIds(ids);
      }
    }
  }
}

// ── 积分计算引擎 ──
class _PointsCalculator {
  final List<db.PointsTransactionRow> _rows;
  _PointsCalculator(this._rows);

  int get earned {
    var total = 0;
    for (final r in _rows) {
      if (['LOGIN_BONUS', 'PRACTICE_REWARD', 'TASK_REWARD', 'REVIEW_REWARD'].contains(r.source)) {
        total += r.amount;
      }
    }
    return total;
  }

  int get bonus {
    var total = 0;
    for (final r in _rows) {
      if (r.source == 'SIGNUP_BONUS') total += r.amount;
    }
    return total;
  }

  int get spent {
    var total = 0;
    for (final r in _rows) {
      if (r.source == 'PAPER_PURCHASE') total += r.amount;
    }
    return total.abs();
  }

  int get available => earned + bonus - spent;
}

