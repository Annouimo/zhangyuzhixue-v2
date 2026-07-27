import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import '../data/daos/question_dao.dart';
import '../data/daos/progress_dao.dart';
import '../pages/router.dart';
import '../data/database/database_provider.dart';
import '../data/database/app_database.dart' as app_db;
import '../data/sync/sync_manager.dart';
import '../data/sync/sync_types.dart';

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
      case 'choice':
        return AppRoutes.solveChoice;
      case 'fill':
        return AppRoutes.solveFill;
      case 'solution':
        return AppRoutes.solveMap;
      default:
        return AppRoutes.solveMap;
    }
  }

  /// 从题目入口页跳转到解题页，自动查询存档决定 mode/attemptId
  static Future<void> navigateTo(
    BuildContext context,
    int questionId,
    String questionType, {
    List<int> sequence = const [],
    List<int> quickPracticeSeen = const [],
  }) async {
    final repo = QuestionRepository(
      QuestionDao(DatabaseProvider()),
      ProgressDao(DatabaseProvider()),
    );
    final attempts = await repo.getAttempts(questionId);
    String mode;
    String? attemptId;
    if (attempts.isEmpty) {
      mode = 'first';
      attemptId = null;
    } else {
      final last = attempts.last;
      attemptId = last.id.toString();
      mode = !last.isCompleted ? 'resume' : 'review';
    }
    final page = pageName(questionType);
    final sequenceParam = sequence.length > 1
        ? '&sequence=${sequence.join(',')}'
        : '';
    final quickPracticeParam = quickPracticeSeen.isNotEmpty
        ? '&quickPractice=${quickPracticeSeen.join(',')}'
        : '';
    if (!context.mounted) return;
    RouterUtils.push(
      context,
      '$page?id=$questionId'
      '${mode != 'first' ? '&mode=$mode' : ''}'
      '${attemptId != null ? '&attemptId=$attemptId' : ''}'
      '$sequenceParam'
      '$quickPracticeParam',
    );
  }

  static Future<bool> navigateToNextQuickPractice(
    BuildContext context,
    List<int> seenIds,
  ) async {
    final dao = QuestionDao(DatabaseProvider());
    final excluded = seenIds.toSet();
    var question = await dao.getRandomExcluding(
      excluded,
      preferredType: 'choice',
    );
    question ??= await dao.getRandomExcluding(excluded, preferredType: 'fill');
    question ??= await dao.getRandomExcluding(excluded);
    if (question == null || !context.mounted) return false;
    await navigateTo(
      context,
      question.id,
      question.questionType,
      quickPracticeSeen: [...seenIds, question.id],
    );
    return true;
  }

  static Future<void> navigateToNext(
    BuildContext context,
    int questionId,
    List<int> sequence,
  ) async {
    final question = await QuestionDao(DatabaseProvider()).getById(questionId);
    if (question == null || !context.mounted) return;
    await navigateTo(
      context,
      questionId,
      question.questionType,
      sequence: sequence,
    );
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

    // 答案与解析（选填题直读 sub_question.answer + explanation，回退到 solution_step.content）
    String? answer;
    String? explanation;
    if (q.questionType == 'choice' || q.questionType == 'fill') {
      final subs = await _dao.getSubQuestions(id);
      if (subs.isNotEmpty) {
        answer = subs.first.answer;
        explanation = subs.first.explanation;
        if ((explanation ?? '').isEmpty) {
          try {
            final methods = await _dao.getMethods(subs.first.id);
            if (methods.isNotEmpty) {
              final steps = await _dao.getSteps(methods.first.id);
              if (steps.isNotEmpty) explanation = steps.first.content;
            }
          } catch (_) {}
        }
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
    return rows
        .map(
          (r) => SolveAttempt(
            id: r.id,
            questionId: r.questionId,
            attemptNumber: r.attemptNumber,
            createdAt: DateTime.parse(r.createdAt),
            isCompleted: r.status == 'completed',
            isStarted: r.status != 'pending' && r.status != 'new',
          ),
        )
        .toList();
  }

  Future<int?> nextQuestion(int currentId) async {
    final all = await _dao.getAll();
    if (all.isEmpty) return null;
    final sorted = all.map((q) => q.id).toList()..sort();
    final idx = sorted.indexOf(currentId);
    return idx < sorted.length - 1 ? sorted[idx + 1] : null;
  }

  /// 保存作答记录到 user.db
  Future<void> saveAttempt(
    int questionId, {
    required String answerText,
    required bool isCorrect,
  }) async {
    var latest = await _progressDao.getLatestAttempt(questionId);
    if (latest == null) {
      await _progressDao.createAttempt(questionId: questionId);
      latest = await _progressDao.getLatestAttempt(questionId);
    }
    if (latest != null) {
      await _progressDao.updateAttemptAnswer(
        latest.id,
        answerText,
        isCorrect ? 1 : 0,
      );
      // 入同步队列（完成一道题后推送）
      try {
        await SyncManager().enqueue(
          entityType: SyncEntityType.submission,
          operation: SyncOperationType.upsert,
          localId: latest.id,
          payload: jsonEncode({
            'details': [
              {
                'question_id': questionId,
                'attempt_number': latest.attemptNumber,
                'status': 'completed',
                'answer_text': answerText,
                'is_correct': isCorrect ? 1 : 0,
              },
            ],
          }),
        );
      } catch (_) {
        // 入队失败不阻塞主流程
      }
      // 赠送做题积分（写本地流水）
      try {
        final now = DateTime.now().toIso8601String();
        final db = DatabaseProvider();
        final question = await _dao.getById(questionId);
        final difficulty = question?.difficulty ?? 0.0;
        final amount = difficulty.floor() / 10.0; // 难度 floor 0~10，除以10得 0~1.0 分
        final newId = await db.appDb
            .into(db.appDb.pointsTransactions)
            .insert(
              app_db.PointsTransactionsCompanion(
                amount: Value(amount),
                source: const Value('PRACTICE_REWARD'),
                transactionType: const Value('EARN'),
                createdAt: Value(now),
                description: const Value('做题奖励'),
              ),
            );
        // 入同步队列
        try {
          await SyncManager().enqueue(
            entityType: SyncEntityType.pointsTransaction,
            operation: SyncOperationType.upsert,
            localId: newId,
            payload: jsonEncode({
              'amount': amount,
              'source': 'PRACTICE_REWARD',
              'transaction_type': 'EARN',
              'description': '做题奖励',
              'created_at': now,
            }),
          );
        } catch (_) {}
      } catch (_) {}
    }
  }

  List<String> _parseImages(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .cast<String>()
          .map((p) => p.replaceAll('\\', '/'))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
