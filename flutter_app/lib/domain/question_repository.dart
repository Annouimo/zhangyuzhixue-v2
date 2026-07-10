import 'dart:convert';
import '../data/daos/question_dao.dart';
import '../data/daos/progress_dao.dart';


/// 题目详情
class QuestionDetail {
  final int id;
  final String stem;
  final List<String> images;
  final double difficulty;
  final List<String> conceptTags;
  final String questionType; // choice / fill / solution
  final Map<String, String>? options;
  final String? answer;

  const QuestionDetail({
    required this.id,
    required this.stem,
    this.images = const [],
    required this.difficulty,
    required this.conceptTags,
    required this.questionType,
    this.options,
    this.answer,
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

    // 答案（选填题直读 sub_question.answer）
    String? answer;
    if (q.questionType == 'choice' || q.questionType == 'fill') {
      final subs = await _dao.getSubQuestions(id);
      if (subs.isNotEmpty && subs.first.answer != null) {
        answer = subs.first.answer;
      }
    }

    return QuestionDetail(
      id: q.id,
      stem: q.stem,
      images: _parseImages(q.images),
      difficulty: q.difficulty ?? 0,
      conceptTags: tagNames,
      questionType: q.questionType,
      options: options,
      answer: answer,
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

  List<String> _parseImages(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }
}

