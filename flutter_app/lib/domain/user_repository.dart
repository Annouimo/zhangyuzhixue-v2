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

  const UserInfo({
    required this.id,
    required this.name,
    this.realName,
    this.studentId,
    this.avatar,
    this.school,
    this.gaokaoYear,
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
      gaokaoYear: remote['gaokao_year'] as String?,
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

  Future<double> bonusPoints() async {
    final rows = await _dao.getTransactionsBySource(['SIGNUP_BONUS']);
    var total = 0;
    for (final r in rows) { total += r.amount; }
    return total.toDouble();
  }

  Future<double> spentPoints() async {
    final rows = await _dao.getTransactionsBySource(['PAPER_PURCHASE']);
    var total = 0;
    for (final r in rows) { total += r.amount; }
    return total.abs().toDouble();
  }

  Future<double> availablePoints() async {
    final e = await _dao.getEarnedPoints();
    final bRows = await _dao.getTransactionsBySource(['SIGNUP_BONUS']);
    final pRows = await _dao.getTransactionsBySource(['PAPER_PURCHASE']);
    var bonus = 0;
    for (final r in bRows) { bonus += r.amount; }
    var spent = 0;
    for (final r in pRows) { spent += r.amount; }
    return (e + bonus + spent).toDouble();
  }

  Future<double> todayPoints() async {
    final earned = await _dao.getTodayEarnedPoints();
    return earned.toDouble();
  }

  // ── 等级 ──
  Future<List<LevelRow>> getLevels() async {
    final configs = await _questionDao.getAllLevelConfigs();
    return configs.map((c) => LevelRow(
      level: c.level,
      range: '${c.minXp}+',
    )).toList();
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
      await _api.getInfo();
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // ── 签到 ──
  Future<int> streakDays() => _dao.getStreakDays();

  Future<double> todayReward() async => 0;

  Future<double> nextReward() async => 0;

  Future<double> todayEarned() async => 0;

  // ── 版本 ──
  Future<String> appVersion() async => '2.0.0';

  Future<String> questionBankVersion() async => AppPrefs().qbankVersion.toString();
}

// ── 积分计算引擎 ──
class _PointsCalculator {
  final List<db.PointsTransactionRow> _rows;
  _PointsCalculator(this._rows);

  int get earned {
    var total = 0;
    for (final r in _rows) {
      if (['LOGIN_BONUS', 'PRACTICE_REWARD', 'TASK_REWARD'].contains(r.source)) {
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

