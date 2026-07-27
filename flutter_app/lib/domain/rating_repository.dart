import 'dart:convert';
import 'package:drift/drift.dart';
import '../data/daos/rating_dao.dart';
import '../data/daos/question_dao.dart';
import '../data/daos/system_config_dao.dart';
import '../data/database/database_provider.dart';
import '../data/database/app_database.dart' as app_db;
import 'package:shared/debug/audit_logger.dart';
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
    final isFirstRating = await _dao.getRating(questionId) == null;
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
          'difficulty_score': difficulty.round(),
          'calculation_score': calculation.round(),
          'elegance_score': elegance.round(),
        }),
      );
    } catch (e) {
      AuditLogger.instance.sync('enqueue_error', {
        'type': 'rating',
        'error': '$e',
      });
    }
    // 每道题仅首次评价赠送积分，后续修改只更新评价内容。
    if (!isFirstRating) return;
    try {
      final cfg = SystemConfigDao(DatabaseProvider());
      final pts = await cfg.getDouble('question_rating_reward', 0.3);
      final now = DateTime.now().toIso8601String();
      final db = DatabaseProvider();
      final newId = await db.appDb
          .into(db.appDb.pointsTransactions)
          .insert(
            app_db.PointsTransactionsCompanion(
              amount: Value(pts),
              source: const Value('RATING_REWARD'),
              transactionType: const Value('EARN'),
              sourceObjectId: Value(questionId),
              createdAt: Value(now),
              description: const Value('题目评价奖励'),
            ),
          );
      // 入同步队列
      try {
        await SyncManager().enqueue(
          entityType: SyncEntityType.pointsTransaction,
          operation: SyncOperationType.upsert,
          localId: newId,
          payload: jsonEncode({
            'amount': pts,
            'source': 'RATING_REWARD',
            'transaction_type': 'EARN',
            'source_object_id': questionId,
            'description': '题目评价奖励',
            'created_at': now,
          }),
        );
      } catch (_) {}
    } catch (e) {
      AuditLogger.instance.error('RatingRepository.submitRating.points', e);
    }
  }
}
