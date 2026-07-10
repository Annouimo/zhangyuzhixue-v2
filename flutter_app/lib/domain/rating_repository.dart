import '../data/daos/rating_dao.dart';

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

/// 评分 Repository — 本地读写
class RatingRepository {
  final RatingDao _dao;
  const RatingRepository(this._dao);

  Future<Rating> getRating(int questionId) async {
    final row = await _dao.getRating(questionId);
    if (row == null) {
      return const Rating(algorithmDifficulty: 0, algorithmCalculation: 0);
    }
    return Rating(
      userDifficulty: row.difficultyScore.toDouble(),
      userCalculation: row.calculationScore.toDouble(),
      userElegance: row.eleganceScore.toDouble(),
      algorithmDifficulty: 0,
      algorithmCalculation: 0,
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
  }
}
