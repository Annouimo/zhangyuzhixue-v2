import 'dart:convert';
import '../data/daos/rating_dao.dart';
import '../data/daos/question_dao.dart';
import '../data/sync/sync_manager.dart';
import '../data/sync/sync_types.dart';

/// 评分数据
class Rating {
  final double? userDifficulty;
  final double? userCalculation;
  final double? userElegance;
  final double algorithmDifficulty;
  final double algorithmCalculation;

  const Rating({
    this.userDifficulty,
    this.userCalculation,
    this.userElegance,
    required this.algorithmDifficulty,
    required this.algorithmCalculation,
  });
}

/// 评分 Repository — 本地读写 + 同步入队
class RatingRepository {
  final RatingDao _dao;
  final QuestionDao _questionDao;

  const RatingRepository(this._dao, this._questionDao);

  Future<Rating> getRating(int questionId) async {
    final row = await _dao.getRating(questionId);
    // 同时从 assets.db 读取算法标注分
    double algoDiff = 0, algoCalc = 0;
    try {
      final q = await _questionDao.getById(questionId);
      if (q != null) {
        algoDiff = q.difficulty ?? 0;
        algoCalc = q.calculation ?? 0;
      }
    } catch (_) {}

    if (row == null) {
      return Rating(
        algorithmDifficulty: algoDiff,
        algorithmCalculation: algoCalc,
      );
    }
    return Rating(
      userDifficulty: row.difficultyScore.toDouble(),
      userCalculation: row.calculationScore.toDouble(),
      userElegance: row.eleganceScore.toDouble(),
      algorithmDifficulty: algoDiff,
      algorithmCalculation: algoCalc,
    );
  }

  Future<void> submitRating({
    required int questionId,
    required double difficulty,
    required double calculation,
    required double elegance,
  }) async {
    await _dao.upsertRating(
      questionId: questionId,
      difficultyScore: difficulty.round(),
      calculationScore: calculation.round(),
      eleganceScore: elegance.round(),
    );
    // 入同步队列
    try {
      await SyncManager().enqueue(
        entityType: SyncEntityType.rating,
        operation: SyncOperationType.upsert,
        localId: questionId,
        payload: jsonEncode({
          'question_id': questionId,
          'difficulty': difficulty,
          'calculation': calculation,
          'elegance': elegance,
        }),
      );
    } catch (_) {
      // 静默
    }
  }
}
