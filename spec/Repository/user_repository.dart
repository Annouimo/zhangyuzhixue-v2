/// 章鱼智学 — UserRepository
/// 对应页面：home.html, profile.html, question_history.html, points.html
/// data-db: user.getInfo.*, user.getAnswerHistory.*, points.getHistory.*

class UserInfo {
  final int id;
  final String name;           // 昵称/用户名，UI 统一展示
  final String? realName;      // 真实姓名（只读，管理员使用）
  final String? studentId;
  final double points;
  final String? school;

  const UserInfo({
    required this.id,
    required this.name,
    this.realName,
    this.studentId,
    required this.points,
    this.school,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        id: json['id'] as int,
        name: json['name'] as String,
        realName: json['real_name'] as String?,
        studentId: json['student_id'] as String?,
        points: (json['points'] as num).toDouble(),
        school: json['school'] as String?,
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
  final double balance;
  final String note;

  const PointsRecord({
    required this.time,
    required this.type,
    required this.change,
    required this.balance,
    required this.note,
  });

  factory PointsRecord.fromJson(Map<String, dynamic> json) => PointsRecord(
        time: json['time'] as String,
        type: json['type'] as String,
        change: (json['change'] as num).toDouble(),
        balance: (json['balance'] as num).toDouble(),
        note: json['note'] as String,
      );
}

class UserRepository {
  /// GET /api/user/info/  →  { id, name, real_name, student_id, points, school }
  static Future<UserInfo> getUserInfo() async {
    throw UnimplementedError('UserRepository.getUserInfo');
  }

  /// GET /api/user/answer-history/
  static Future<List<HistoryItem>> getAnswerHistory() async {
    throw UnimplementedError('UserRepository.getAnswerHistory');
  }

  /// GET /api/user/points-history/
  static Future<List<PointsRecord>> getPointsHistory() async {
    throw UnimplementedError('UserRepository.getPointsHistory');
  }
}
