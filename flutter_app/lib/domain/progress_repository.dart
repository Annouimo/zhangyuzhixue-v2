import 'dart:convert';
import 'package:drift/drift.dart';
import '../data/daos/progress_dao.dart';
import '../data/daos/question_dao.dart';
import '../data/database/app_database.dart' as db;
import '../data/database/database_provider.dart';
import 'package:shared/debug/audit_logger.dart';
import '../data/sync/sync_manager.dart';
import '../data/sync/sync_types.dart';


/// 单个步骤数据
class Step {
  final int stepNumber;
  final String title;
  final String analysis;
  final List<String> cardTitles;

  const Step({
    required this.stepNumber,
    required this.title,
    required this.analysis,
    required this.cardTitles,
  });
}

/// 一个解法下的步骤组
class SolutionMethodBlock {
  final String? methodName;
  final List<Step> steps;
  const SolutionMethodBlock({this.methodName, required this.steps});
}

/// 一个小题块
class SubQuestionBlock {
  final int index;
  final String label;
  final List<SolutionMethodBlock> solutions;
  const SubQuestionBlock({
    required this.index,
    required this.label,
    required this.solutions,
  });
}

/// 解题模式的完整状态
class SolveProgressState {
  final List<SubQuestionBlock> subQuestions;
  const SolveProgressState({required this.subQuestions});
}

/// 存档摘要
class AttemptSummary {
  final int? id;
  final int attemptNumber;
  final String status;
  final DateTime createdAt;

  const AttemptSummary({
    this.id,
    required this.attemptNumber,
    required this.status,
    required this.createdAt,
  });
}

/// 步骤历史记录
class StepSolveRecord {
  final int stepOrder;
  final bool feedbackGiven;
  final String? feedbackType;

  const StepSolveRecord({
    required this.stepOrder,
    required this.feedbackGiven,
    this.feedbackType,
  });
}

/// 解法历史
class MethodSolveRecord {
  final String methodName;
  final List<StepSolveRecord> steps;
  const MethodSolveRecord({required this.methodName, required this.steps});
}

/// 小问历史
class SubQSolveRecord {
  final int index;
  final String activeMethod;
  final bool completed;
  final List<MethodSolveRecord> methods;

  const SubQSolveRecord({
    required this.index,
    required this.activeMethod,
    required this.completed,
    required this.methods,
  });
}

/// 完整解题历史快照
class PreviousSolveState {
  final int attemptNumber;
  final String? choiceSelected;
  final bool choiceSubmitted;
  final bool fillRevealed;
  final List<SubQSolveRecord> subQRecords;
  final bool isRated;

  const PreviousSolveState({
    required this.attemptNumber,
    this.choiceSelected,
    required this.choiceSubmitted,
    required this.fillRevealed,
    required this.subQRecords,
    required this.isRated,
  });
}

/// 进度 Repository — 本地记录解题进度
class ProgressRepository {
  final ProgressDao _dao;
  final QuestionDao _questionDao;
  
  const ProgressRepository(this._dao, this._questionDao);

  Future<SolveProgressState> getSolveState(int questionId) async {
    final subQuestions = await _questionDao.getSubQuestions(questionId);
    final subQIds = subQuestions.map((sq) => sq.id).toList();
    final allMethods = subQIds.isEmpty
        ? []
        : await _questionDao.getMethodsBySubQuestionIds(subQIds);
    final methodIds = allMethods.map((m) => (m as dynamic).id as int).toList();
    final allSteps = methodIds.isEmpty
        ? []
        : await _questionDao.getStepsByMethodIds(methodIds);

    // 按 subQuestionId 分组方法
    final methodsBySubQ = <int, List<dynamic>>{};
    for (final m in allMethods) {
      methodsBySubQ.putIfAbsent(m.subQuestionId, () => []).add(m);
    }
    // 按 methodId 分组步骤
    final stepsByMethod = <int, List<dynamic>>{};
    for (final s in allSteps) {
      stepsByMethod.putIfAbsent(s.methodId, () => []).add(s);
    }

    final blocks = <SubQuestionBlock>[];
    for (final sq in subQuestions) {
      final methods = methodsBySubQ[sq.id] ?? [];
      final methodBlocks = <SolutionMethodBlock>[];
      for (final m in methods) {
        final steps = stepsByMethod[m.id] ?? [];
        methodBlocks.add(SolutionMethodBlock(
          methodName: m.methodName,
          steps: steps.map((s) {
            final step = s as dynamic;
            return Step(
              stepNumber: step.stepNumber,
              title: step.title,
              analysis: step.content,
              cardTitles: _parseCardTitles(step.cardTitles),
            );
          }).toList(),
        ));
      }
      blocks.add(SubQuestionBlock(
        index: sq.sortOrder,
        label: '(${sq.sortOrder})',
        solutions: methodBlocks,
      ));
    }
    return SolveProgressState(subQuestions: blocks);
  }

  Future<List<AttemptSummary>> getAttempts(int questionId) async {
    final rows = await _dao.getAttempts(questionId);
    return rows.map((r) => AttemptSummary(
      id: r.id,
      attemptNumber: r.attemptNumber,
      status: r.status,
      createdAt: DateTime.parse(r.createdAt),
    )).toList();
  }

  Future<int> createAttempt(int questionId) async {
    final id = await _dao.createAttempt(questionId: questionId);
    return id;
  }

  Future<PreviousSolveState?> getAttemptState(
    int questionId,
    int attemptNumber,
  ) async {
    final all = await _dao.getAttempts(questionId);
    final match = all.where((a) => a.attemptNumber == attemptNumber).toList();
    if (match.isEmpty) return null;
    final detail = match.first;

    // 查询该存档的步骤反馈
    final feedbacks = await _dao.getStepFeedbacks(detail.id);
    final feedbacksBySubQ = <int, List<db.StepFeedbackRow>>{};
    for (final f in feedbacks) {
      final idx = f.subQuestionIndex ?? 0;
      feedbacksBySubQ.putIfAbsent(idx, () => []).add(f);
    }

    // 查询该题是否已评分
    final hasRating = await _dao.hasRating(questionId);

    // 重建 subQRecords
    final subQRecords = <SubQSolveRecord>[];
    // 从 assets 库读题目结构（批量查询）
    final subQuestions = await _questionDao.getSubQuestions(questionId);
    final subQIds = subQuestions.map((sq) => sq.id).toList();
    final allMethods = subQIds.isEmpty
        ? []
        : await _questionDao.getMethodsBySubQuestionIds(subQIds);
    final methodIds = allMethods.map((m) => (m as dynamic).id as int).toList();
    final allSteps = methodIds.isEmpty
        ? []
        : await _questionDao.getStepsByMethodIds(methodIds);

    // 按 subQuestionId 分组方法
    final methodsBySubQ = <int, List<dynamic>>{};
    for (final m in allMethods) {
      methodsBySubQ.putIfAbsent(m.subQuestionId, () => []).add(m);
    }
    // 按 methodId 分组步骤
    final stepsByMethod = <int, List<dynamic>>{};
    for (final s in allSteps) {
      stepsByMethod.putIfAbsent(s.methodId, () => []).add(s);
    }

    for (final sq in subQuestions) {
      final methods = methodsBySubQ[sq.id] ?? [];
      final methodRecords = <MethodSolveRecord>[];
      for (final mEntry in methods.asMap().entries) {
        final mIdx = mEntry.key;
        final m = mEntry.value;
        final steps = stepsByMethod[m.id] ?? [];
        final stepRecords = <StepSolveRecord>[];
        for (final s in steps) {
          final stepObj = s as dynamic;
          final feedbackList = feedbacksBySubQ[sq.sortOrder - 1];
          final fb = feedbackList
              ?.where((f) => f.stepNumber == stepObj.stepNumber && f.methodId == mIdx)
              .toList();
          stepRecords.add(StepSolveRecord(
            stepOrder: stepObj.stepNumber,
            feedbackGiven: fb != null && fb.isNotEmpty,
            feedbackType: (fb != null && fb.isNotEmpty) ? fb.last.status : null,
          ));
        }
        methodRecords.add(MethodSolveRecord(
          methodName: m.methodName ?? '',
          steps: stepRecords,
        ));
      }
      subQRecords.add(SubQSolveRecord(
        index: sq.sortOrder,
        activeMethod: '',
        completed: methodRecords.any((m) => m.steps.every((s) => s.feedbackGiven)),
        methods: methodRecords,
      ));
    }

    return PreviousSolveState(
      attemptNumber: attemptNumber,
      choiceSubmitted: detail.status == 'completed',
      fillRevealed: detail.status == 'completed',
      subQRecords: subQRecords,
      isRated: hasRating,
    );
  }

  Future<void> submitStepFeedback({
    required int questionId,
    required int attemptNumber,
    int? subQuestionIndex,
    int? methodIndex,
    required int stepNumber,
    required String status,
  }) async {
    final all = await _dao.getAttempts(questionId);
    final match = all.where((a) => a.attemptNumber == attemptNumber).toList();
    if (match.isEmpty) return;
    final detail = match.first;
    final id = await _dao.insertStepFeedback(
      submissionDetailId: detail.id,
      questionId: questionId,
      subQuestionIndex: subQuestionIndex,
      methodId: methodIndex,
      stepNumber: stepNumber,
      status: status,
    );
    // 入同步队列
    try {
      await SyncManager().enqueue(
        entityType: SyncEntityType.stepFeedback,
        operation: SyncOperationType.upsert,
        localId: id,
        payload: jsonEncode({
          'submission_detail_id': null,
          'question_id': questionId,
          'step_number': stepNumber,
          'sub_question_index': subQuestionIndex ?? 0,
          'method_id': methodIndex,
          'status': status,
        }),
      );
    } catch (e) {
      AuditLogger.instance.sync('enqueue_error', {'type': 'stepFeedback', 'error': '$e'});
    }

    // 检查是否所有步骤已完成（当前方法完成，且所有小问至少一个解法完成）
    try {
      final subQuestions = await _questionDao.getSubQuestions(questionId);
      if (subQuestions.isEmpty) return;
      final sqIdx = subQuestionIndex?.clamp(0, subQuestions.length - 1) ?? 0;
      final sq = subQuestions[sqIdx];
      final methods = await _questionDao.getMethods(sq.id);
      if (methods.isEmpty) return;
      final mIdx = methodIndex?.clamp(0, methods.length - 1) ?? 0;
      final currentMethod = methods[mIdx];
      final methodSteps = await _questionDao.getSteps(currentMethod.id);
      if (methodSteps.isEmpty) return;

      // 获取当前方法的步骤编号集合
      final feedbacks = await _dao.getStepFeedbacks(detail.id);
      final methodDone = methodSteps
          .every((s) => feedbacks.any((f) =>
              f.stepNumber == s.stepNumber &&
              f.subQuestionIndex == subQuestionIndex &&
              f.methodId == methodIndex));

      if (!methodDone) return;

      // 检查每个小问是否至少有一个解法完成
      bool allResolved = true;
      for (final sq2 in subQuestions) {
        final sqMethods = await _questionDao.getMethods(sq2.id);
        bool sqResolved = false;
        for (final mEntry in sqMethods.asMap().entries) {
          final mIdx = mEntry.key;
          final m = mEntry.value;
          final mSteps = await _questionDao.getSteps(m.id);
          if (mSteps.isEmpty) continue;
          if (mSteps.every((s) => feedbacks.any((f) =>
              f.stepNumber == s.stepNumber &&
              f.subQuestionIndex == sq2.sortOrder - 1 &&
              f.methodId == mIdx))) {
            sqResolved = true;
            break;
          }
        }
        if (!sqResolved) { allResolved = false; break; }
      }

      if (!allResolved) return;

      await _dao.updateAttemptStatus(detail.id, 'completed');
      try {
        await SyncManager().enqueue(
          entityType: SyncEntityType.submission,
          operation: SyncOperationType.upsert,
          localId: detail.id,
          payload: jsonEncode({
            'details': [
              {
                'question_id': questionId,
                'attempt_number': attemptNumber,
                'status': 'completed',
              },
            ],
          }),
        );
      } catch (e) {
        AuditLogger.instance.sync('enqueue_error', {
          'type': 'submission',
          'error': '$e',
        });
      }
      // 发放做题积分（amount > 0 才发）
      final now = DateTime.now().toIso8601String();
      final question = await _questionDao.getById(questionId);
      final difficulty = question?.difficulty ?? 0.0;
      final amount = difficulty.floor() / 10.0;
      if (amount > 0) {
        final pointsId = await DatabaseProvider().appDb.into(DatabaseProvider().appDb.pointsTransactions).insert(
          db.PointsTransactionsCompanion(
            amount: Value(amount),
            source: const Value('PRACTICE_REWARD'),
            transactionType: const Value('EARN'),
            createdAt: Value(now),
            description: const Value('做题奖励'),
          ),
        );
        try {
          await SyncManager().enqueue(
            entityType: SyncEntityType.pointsTransaction,
            operation: SyncOperationType.upsert,
            localId: pointsId,
            payload: jsonEncode({
              'amount': amount,
              'source': 'PRACTICE_REWARD',
              'transaction_type': 'EARN',
              'description': '做题奖励',
              'created_at': now,
            }),
          );
        } catch (e) {
          AuditLogger.instance.sync('enqueue_error', {
            'type': 'pointsTransaction',
            'error': '$e',
          });
        }
      }
      AuditLogger.instance.dao('submitStepFeedback.complete',
          amount.toInt(), {'questionId': questionId, 'attemptNumber': attemptNumber});
    } catch (_) {}
  }

  List<String> _parseCardTitles(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }
}

