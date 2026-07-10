import 'dart:convert';
import '../data/daos/progress_dao.dart';
import '../data/daos/question_dao.dart';


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
    final blocks = <SubQuestionBlock>[];
    for (final sq in subQuestions) {
      final methods = await _questionDao.getMethods(sq.id);
      final methodBlocks = <SolutionMethodBlock>[];
      for (final m in methods) {
        final steps = await _questionDao.getSteps(m.id);
        methodBlocks.add(SolutionMethodBlock(
          methodName: m.methodName,
          steps: steps.map((s) => Step(
            stepNumber: s.stepNumber,
            title: s.title,
            analysis: s.content,
            cardTitles: _parseCardTitles(s.cardTitles),
          )).toList(),
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
    // feedbacks unused in v1
    // 简化的状态重建
    return PreviousSolveState(
      attemptNumber: attemptNumber,
      choiceSubmitted: detail.status == 'completed',
      fillRevealed: detail.status == 'completed',
      subQRecords: [],
      isRated: false,
    );
  }

  Future<void> submitStepFeedback({
    required int questionId,
    required int attemptNumber,
    required int stepNumber,
    required String status,
  }) async {
    final all = await _dao.getAttempts(questionId);
    final match = all.where((a) => a.attemptNumber == attemptNumber).toList();
    if (match.isEmpty) return;
    await _dao.insertStepFeedback(
      submissionDetailId: match.first.id,
      questionId: questionId,
      stepNumber: stepNumber,
      status: status,
    );
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

