/// 章鱼智学 — UserRepository
/// data-db: user.*, tasks.*, points.*, app.*
/// 对应页面：index.html(任务卡片), profile.html, profile_edit.html,
///          points.html, level_detail.html, about.html, solve.html(积分行)

class UserInfo {
  final int id;
  final String name;
  final String? realName;
  final String? studentId;
  final String? avatar;
  final String? gaokaoYear;

  const UserInfo({
    required this.id,
    required this.name,
    this.realName,
    this.studentId,
    this.avatar,
    this.gaokaoYear,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        id: json['id'] as int,
        name: json['name'] as String,
        realName: json['real_name'] as String?,
        studentId: json['student_id'] as String?,
        avatar: json['avatar'] as String?,
        gaokaoYear: json['gaokao_year'] as String?,
      );
}

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

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        title: json['title'] as String,
        questionType: json['question_type'] as String,
        date: json['date'] as String,
        status: json['status'] as String,
      );
}

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

  factory PointsRecord.fromJson(Map<String, dynamic> json) => PointsRecord(
        time: json['time'] as String,
        type: json['type'] as String,
        change: (json['change'] as num).toDouble(),
        earned: (json['earned'] as num).toDouble(),
        bonus: (json['bonus'] as num).toDouble(),
        spent: (json['spent'] as num).toDouble(),
        available: (json['available'] as num).toDouble(),
      );
}

class LevelRow {
  final int level;
  final String range;

  const LevelRow({required this.level, required this.range});

  factory LevelRow.fromJson(Map<String, dynamic> json) => LevelRow(
        level: json['level'] as int,
        range: json['range'] as String,
      );
}

class UserRepository {
  /// GET /api/user/info/
  Future<UserInfo> getUserInfo() async {
    throw UnimplementedError('UserRepository.getUserInfo');
  }

  /// PUT /api/user/info/
  Future<void> saveProfile(UserInfo data) async {
    throw UnimplementedError('UserRepository.saveProfile');
  }

  /// 头像上传（不进同步队列）
  ///
  /// 流程：用户选图 → resize 200×200 → 存本地文件系统
  ///       → POST multipart/form-data → /api/user/avatar/
  ///       → 服务端返回 URL → 更新本地 avatar 字段
  ///
  /// 头像不走同步队列：同步队列设计用于 JSON 结构化数据批量提交。
  /// 头像是二进制文件（multipart/form-data），队列 payload 只接受 JSON。
  /// 头像走独立上传接口，URL 作为用户信息随下次 UserInfo 同步推送。
  ///
  /// 客户端渲染：优先展示本地缓存版本（cached_network_image），
  /// 后台静默请求最新 URL。上传后立即用本地文件预览，不等待服务端返回。
  ///
  /// PUT /api/user/avatar/
  Future<String> uploadAvatar(String localPath) async {
    throw UnimplementedError('UserRepository.uploadAvatar');
  }

  /// GET /api/user/answer-history/
  Future<List<HistoryItem>> getAnswerHistory() async {
    throw UnimplementedError('UserRepository.getAnswerHistory');
  }

  /// 做题历史总数（profile.html 副标题）
  Future<int> getAnswerHistoryCount() async {
    throw UnimplementedError('UserRepository.getAnswerHistoryCount');
  }

  // ---- 积分相关（委托给 _PointsCalculator） ----

  /// GET /api/user/points/history/
  Future<List<PointsRecord>> getPointsHistory() async {
    throw UnimplementedError('UserRepository.getPointsHistory');
  }

  /// 四种积分汇总：从本地交易表计算或调 API
  Future<double> earnedPoints() async {
    throw UnimplementedError('UserRepository.earnedPoints');
  }

  Future<double> bonusPoints() async {
    throw UnimplementedError('UserRepository.bonusPoints');
  }

  Future<double> spentPoints() async {
    throw UnimplementedError('UserRepository.spentPoints');
  }

  Future<double> availablePoints() async {
    throw UnimplementedError('UserRepository.availablePoints');
  }

  Future<double> todayPoints() async {
    throw UnimplementedError('UserRepository.todayPoints');
  }

  // ---- 等级 ----

  /// 等级对照表
  Future<List<LevelRow>> getLevels() async {
    throw UnimplementedError('UserRepository.getLevels');
  }

  /// 等级进度文本，如 "🏅 Lv.5 → 升级还需 7.8"
  Future<String> levelProgress() async {
    throw UnimplementedError('UserRepository.levelProgress');
  }

  /// 超过百分之多少的用户
  Future<int> levelPercentile() async {
    throw UnimplementedError('UserRepository.levelPercentile');
  }

  // ---- 签到任务 ----

  /// 已连续签到天数
  Future<int> streakDays() async {
    throw UnimplementedError('UserRepository.streakDays');
  }

  /// 今日签到奖励
  Future<double> todayReward() async {
    throw UnimplementedError('UserRepository.todayReward');
  }

  /// 明日签到奖励
  Future<double> nextReward() async {
    throw UnimplementedError('UserRepository.nextReward');
  }

  /// 今日已获得的学习积分
  Future<double> todayEarned() async {
    throw UnimplementedError('UserRepository.todayEarned');
  }

  // ---- app 信息 ----

  /// App 版本号（about.html）
  Future<String> appVersion() async {
    throw UnimplementedError('UserRepository.appVersion');
  }

  /// 题库版本号（about.html）
  Future<String> questionBankVersion() async {
    throw UnimplementedError('UserRepository.questionBankVersion');
  }
}

// ---- 积分计算引擎（私有，仅 UserRepository 内部使用） ----
// 通过 PointsDao 获取交易数据，在 Dart 侧做分类汇总。
//
// source 枚举与分类映射（数据来源：数据库结构设计.md §5.4）：
//   LOGIN_BONUS      → earned（学习积分，每日签到奖励）
//   PRACTICE_REWARD  → earned（学习积分，做题/首题奖励）
//   TASK_REWARD      → earned（学习积分，完成任务奖励）
//   SIGNUP_BONUS     → bonus（赠送积分，新用户注册赠送）
//   PAPER_PURCHASE   → spent（消耗积分，组卷消费，amount 为负）
//   ADMIN_ADJUST     → 管理端手动调整（不归入三类）
//
// 调用链：
//   dao.getAllTransactions() → [{source, amount, createdAt}]
//   → Dart 侧按 source 分类聚合
//
// 5 条公式（全部实时，不进缓存）：
//   累计积分 = sum of amounts where source != PAPER_PURCHASE
//   学习积分 = sum of amounts where source in (LOGIN_BONUS, PRACTICE_REWARD, TASK_REWARD)
//   赠送积分 = sum of amounts where source = SIGNUP_BONUS
//   消耗积分 = abs(sum of amounts where source = PAPER_PURCHASE)
//   可用积分 = earned + bonus - spent
//
// 等级推算：从 assets_db.level_config 表查 min_xp <= 累计积分 的最高等级
// 等级百分位（levelPercentile）必须调服务端 API，本地无法计算（需全量用户数据）
class _PointsCalculator {
}
