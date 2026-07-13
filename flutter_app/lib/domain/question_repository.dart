import 'dart:convert';
import '../data/daos/question_dao.dart';
import '../data/daos/progress_dao.dart';


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
  final String questionType;
  final Map<String, String>? options;
  final String? answer;
  final String? explanation;

  const QuestionDetail({
    required this.id,
    this.title = '',
    this.number = '',
    this.assignName = '',
    required this.stem,
    this.images = const [],
    required this.difficulty,
    this.pointsEarned = 0,
    required this.conceptTags,
    required this.questionType,
    this.options,
    this.answer,
    this.explanation,
  });
}

/// 解题存档
class SolveAttempt {
  final int id;
  final int questionId;
  final int attemptNumber;
  final DateTime createdAt;
  final bool isCompleted;
  final bool isStarted;

  const SolveAttempt({
    required this.id,
    required this.questionId,
    required this.attemptNumber,
    required this.createdAt,
    required this.isCompleted,
    required this.isStarted,
  });
}

/// 入口页路由辅助
class SolveRouteHelper {
  static String pageName(String questionType) {
    switch (questionType) {
      case 'choice': return 'solve-choice';
      case 'fill': return 'solve-fill';
      case 'solution': return 'solve-map';
      default: return 'solve-map';
    }
  }

  static String resolve(String questionType, int attemptCount,
      {int? latestAttemptId, bool latestIsInProgress = false}) {
    final page = 'solve-pages/${pageName(questionType)}';
    if (attemptCount == 0) return '$page?mode=first';
    if (latestIsInProgress) return '$page?mode=resume&attempt_id=$latestAttemptId';
    if (attemptCount == 1) return '$page?mode=review&attempt_id=$latestAttemptId';
    return '$page?mode=review&attempt_id=$latestAttemptId';
  }
}

/// 题目 Repository — 从本地资产库读取，组装 QuestionDetail
class QuestionRepository {
  final QuestionDao _dao;
  final ProgressDao _progressDao;
  const QuestionRepository(this._dao, this._progressDao);

  Future<QuestionDetail> getDetail(int id) async {
    final q = await _dao.getById(id);
    if (q == null) throw Exception('Question not found: $id');

    // 概念标签
    final tags = await _dao.getTagsByQuestion(id);
    final tagNames = tags.map((t) => t.name).toList();

    // 选择题选项
    Map<String, String>? options;
    if (q.questionType == 'choice') {
      final ext = await _dao.getChoiceExt(id);
      if (ext != null) {
        final raw = ext.options;
        final parsed = jsonDecode(raw) as Map<String, dynamic>;
        options = parsed.map((k, v) => MapEntry(k, v as String));
      }
    }

    // 答案与解析（选填题直读 sub_question.answer + explanation）
    String? answer;
    String? explanation;
    if (q.questionType == 'choice' || q.questionType == 'fill') {
      final subs = await _dao.getSubQuestions(id);
      if (subs.isNotEmpty) {
        answer = subs.first.answer;
        explanation = subs.first.explanation;
      }
    }

    return QuestionDetail(
      id: q.id,
      title: '${q.year} ${q.examType} ${q.region}',
      number: q.number,
      assignName: '${q.examType} ${q.region}',
      stem: q.stem,
      images: _parseImages(q.images),
      difficulty: q.difficulty ?? 0,
      conceptTags: tagNames,
      questionType: q.questionType,
      options: options,
      answer: answer,
      explanation: explanation,
    );
  }

  Future<SolveAttempt> startSolve(int questionId) async {
    await _progressDao.createAttempt(questionId: questionId);
    final detail = await _progressDao.getLatestAttempt(questionId);
    return SolveAttempt(
      id: detail?.id ?? 0,
      questionId: questionId,
      attemptNumber: detail?.attemptNumber ?? 1,
      createdAt: DateTime.now(),
      isCompleted: false,
      isStarted: true,
    );
  }

  Future<List<SolveAttempt>> getAttempts(int questionId) async {
    final rows = await _progressDao.getAttempts(questionId);
    return rows.map((r) => SolveAttempt(
      id: r.id,
      questionId: r.questionId,
      attemptNumber: r.attemptNumber,
      createdAt: DateTime.parse(r.createdAt),
      isCompleted: r.status == 'completed',
      isStarted: r.status != 'pending' && r.status != 'new',
    )).toList();
  }

  Future<int?> nextQuestion(int currentId) async {
    final all = await _dao.getAll();
    if (all.isEmpty) return null;
    final sorted = all.map((q) => q.id).toList()..sort();
    final idx = sorted.indexOf(currentId);
    return idx < sorted.length - 1 ? sorted[idx + 1] : null;
  }

  /// 保存作答记录到 user.db
  Future<void> saveAttempt(int questionId, {
    required String answerText,
    required bool isCorrect,
  }) async {
    final latest = await _progressDao.getLatestAttempt(questionId);
    if (latest != null) {
      await _progressDao.updateAttemptAnswer(
        latest.id,
        answerText,
        isCorrect ? 1 : 0,
      );
    }
  }

  List<String> _parseImages(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }
}

