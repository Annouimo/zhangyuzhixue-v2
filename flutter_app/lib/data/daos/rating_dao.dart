import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;

/// 题目评分数据访问层（user 库）
class RatingDao {
  final db.AppDatabase _db;
  const RatingDao(this._db);

  Future<db.QuestionRatingRow?> getRating(int questionId) async {
    final q = _db.select(_db.questionRatings)
      ..where((t) => t.questionId.equals(questionId));
    return q.getSingleOrNull();
  }

  Future<void> upsertRating({
    required int questionId,
    required int difficultyScore,
    required int calculationScore,
    required int eleganceScore,
  }) async {
    final now = DateTime.now().toIso8601String();
    final existing = await (_db.select(_db.questionRatings)
      ..where((t) => t.questionId.equals(questionId))).get();
    if (existing.isNotEmpty) {
      final q = _db.update(_db.questionRatings)
        ..where((t) => t.questionId.equals(questionId));
      await q.write(db.QuestionRatingsCompanion(
        difficultyScore: Value(difficultyScore),
        calculationScore: Value(calculationScore),
        eleganceScore: Value(eleganceScore),
        createdAt: Value(now),
      ));
    } else {
      await _db.into(_db.questionRatings).insert(db.QuestionRatingsCompanion(
        questionId: Value(questionId),
        difficultyScore: Value(difficultyScore),
        calculationScore: Value(calculationScore),
        eleganceScore: Value(eleganceScore),
        createdAt: Value(now),
      ));
    }
  }
}
