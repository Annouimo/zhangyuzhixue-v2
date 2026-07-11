/// 章鱼智学 — QuestionRepository
/// data-db: question.*
/// 对应页面：solve-*.html (解题模式), paper_quicklook.html (做题), etc.
///
/// [入口页面路由逻辑]
/// 每个入口页面根据题目状态 + 题型决定跳转参数：
///
///   入口页判断:
///     question.attempts.length == 0          → mode=first
///     latestAttempt.isInProgress             → mode=resume&attempt_id=X
///     question.attempts.length == 1          → mode=review&attempt_id=X
///     question.attempts.length > 1 && isNew  → 弹出存档选择器
///
///   路由参数:
///     solve-{type}.html?mode=first
///     solve-{type}.html?mode=resume&attempt_id=X
///     solve-{type}.html?mode=review&attempt_id=X
///
///   {type} 由 questionType 决定:
///     "选择" → solve-choice  |  "填空" → solve-fill  |  "解答" → solve-map
///
/// [solve-*.html 接收参数后的行为]
///   mode=first  → 显示首次欢迎视图（全新存档，防剧透）
///   mode=resume → 加载 attempt_id 存档，恢复进度
///   mode=review → 加载 attempt_id 存档，只读浏览

/// 题目详情
class QuestionDetail {
  final int id;
  final String title;
  final String number;
  final String assignName;
  final String stem;
  final List<String> images;
  final double difficulty;
  final double pointsEarned;
  final List<String> conceptTags;
  final String questionType;               // "选择" / "填空" / "解答"
  final Map<String, String>? options;      // 仅选择题: {"A":"x>1", "B":"x<1", ...}
  final String? answer;                    // 标准答案（选填题展示用）

  const QuestionDetail({
    required this.id,
    required this.title,
    required this.number,
    required this.assignName,
    required this.stem,
    this.images = const [],
    required this.difficulty,
    required this.pointsEarned,
    required this.conceptTags,
    required this.questionType,
    this.options,
    this.answer,
  });

  factory QuestionDetail.fromJson(Map<String, dynamic> json) => QuestionDetail(
        id: json['id'] as int,
        title: json['title'] as String,
        number: json['number'] as String,
        assignName: json['assign_name'] as String,
        stem: json['stem'] as String,
        images: (json['images'] as List?)?.cast<String>() ?? [],
        difficulty: (json['difficulty'] as num).toDouble(),
        pointsEarned: (json['points_earned'] as num).toDouble(),
        conceptTags: (json['concept_tags'] as List).cast<String>(),
        questionType: json['question_type'] as String,
        options: json['options'] != null
            ? Map<String, String>.from(json['options'] as Map)
            : null,
        answer: json['answer'] as String?,
      );
}

/// 解题存档 — 记录学生对一道题的一次完整作答
class SolveAttempt {
  final int id;
  final int questionId;
  final int attemptNumber;  // 第几次作答
  final DateTime createdAt;
  final bool isCompleted;   // 是否完成（用于区分 resume/review）
  final bool isStarted;     // 是否开始过（用于区分 first 和 in-progress）

  const SolveAttempt({
    required this.id,
    required this.questionId,
    required this.attemptNumber,
    required this.createdAt,
    required this.isCompleted,
    required this.isStarted,
  });

  factory SolveAttempt.fromJson(Map<String, dynamic> json) => SolveAttempt(
        id: json['id'] as int,
        questionId: json['question_id'] as int,
        attemptNumber: json['attempt_number'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
        isCompleted: json['is_completed'] as bool,
        isStarted: json['is_started'] as bool,
      );
}

/// 入口页路由辅助
class SolveRouteHelper {
  /// 根据题目状态返回正确的 solve 文件名
  static String pageName(String questionType) {
    switch (questionType) {
      case '选择': return 'solve-choice.html';
      case '填空': return 'solve-fill.html';
      case '解答': return 'solve-map.html';
      default: return 'solve-map.html';
    }
  }

  /// 构造路由参数
  static String urlParams(String mode, {int? attemptId}) {
    if (mode == 'first') return '?mode=first';
    return '?mode=$mode&attempt_id=$attemptId';
  }

  /// 入口页统一路由逻辑
  /// 在页面点击题目时调用此方法，返回最终的页面路径
  static String resolve(String questionType, int attemptCount, {int? latestAttemptId, bool latestIsInProgress = false}) {
    final page = pageName(questionType);
    if (attemptCount == 0) {
      return 'solve-pages/$page?mode=first';
    }
    if (latestIsInProgress) {
      return 'solve-pages/$page?mode=resume&attempt_id=$latestAttemptId';
    }
    if (attemptCount == 1) {
      return 'solve-pages/$page?mode=review&attempt_id=$latestAttemptId';
    }
    // ≥2 个已完成存档：弹选择器（在入口页处理），默认跳第一个
    return 'solve-pages/$page?mode=review&attempt_id=$latestAttemptId';
  }
}

class QuestionRepository {
  /// GET /api/questions/{id}/
  Future<QuestionDetail> getDetail(int id) async {
    throw UnimplementedError('QuestionRepository.getDetail');
  }

  /// POST /api/questions/{id}/start-solve/
  Future<SolveAttempt> startSolve(int questionId) async {
    throw UnimplementedError('QuestionRepository.startSolve');
  }

  /// GET /api/questions/{id}/attempts/
  Future<List<SolveAttempt>> getAttempts(int questionId) async {
    throw UnimplementedError('QuestionRepository.getAttempts');
  }

  /// GET /api/questions/{id}/next/
  Future<int?> nextQuestion(int currentId) async {
    throw UnimplementedError('QuestionRepository.nextQuestion');
  }
}
