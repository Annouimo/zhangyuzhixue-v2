import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/database/app_database.dart' as app_db;
import '../data/daos/exam_dao.dart';
import '../data/database/database_provider.dart';
import '../data/sync/sync_manager.dart';
import '../data/sync/sync_types.dart';
import 'exam_repository.dart';
import 'user_repository.dart';

const manualPaperCost = 20;
const smartPaperCost = 10;

class InsufficientPointsException implements Exception {
  final int requiredPoints;
  final double availablePoints;

  const InsufficientPointsException({
    required this.requiredPoints,
    required this.availablePoints,
  });
}

/// 在统一选题工作台中创建手选试卷，并保持现有积分与同步语义。
class PaperCreationService {
  final ExamRepository _examRepository;
  final UserRepository _userRepository;
  final DatabaseProvider _databaseProvider;

  const PaperCreationService(
    this._examRepository,
    this._userRepository,
    this._databaseProvider,
  );

  Future<int> createManualPaper({
    required String name,
    required List<int> selectedIds,
  }) async {
    return _createWithPoints(
      cost: manualPaperCost,
      description: '手动选题',
      create: () => _saveManualPaper(name: name, questionIds: selectedIds),
    );
  }

  Future<int> createDraftPaper({
    required String name,
    required List<int> questionIds,
    required int cost,
    required String description,
  }) async {
    return _createWithPoints(
      cost: cost,
      description: description,
      create: () => _saveManualPaper(name: name, questionIds: questionIds),
    );
  }

  Future<int> createPaper({
    required SearchFilters filters,
    required int cost,
    required String description,
  }) async {
    return _createWithPoints(
      cost: cost,
      description: description,
      create: () => _examRepository.confirm(filters),
    );
  }

  Future<int> _createWithPoints({
    required int cost,
    required String description,
    required Future<int> Function() create,
  }) async {
    final available = await _userRepository.availablePoints();
    if (available < cost) {
      throw InsufficientPointsException(
        requiredPoints: cost,
        availablePoints: available,
      );
    }

    final now = DateTime.now().toIso8601String();
    int? pointId;
    try {
      pointId = await _databaseProvider.appDb
          .into(_databaseProvider.appDb.pointsTransactions)
          .insert(
            app_db.PointsTransactionsCompanion(
              amount: Value(-cost * 1.0),
              source: const Value('PAPER_PURCHASE'),
              transactionType: const Value('SPEND'),
              createdAt: Value(now),
              description: Value(description),
            ),
          );

      final paperId = await create();

      try {
        await SyncManager().enqueue(
          entityType: SyncEntityType.pointsTransaction,
          operation: SyncOperationType.upsert,
          localId: pointId,
          payload: jsonEncode({
            'amount': -cost * 1.0,
            'source': 'PAPER_PURCHASE',
            'transaction_type': 'SPEND',
            'description': description,
            'created_at': now,
          }),
        );
      } catch (_) {
        // 试卷已创建；积分流水会由后续同步修复，不回滚用户结果。
      }
      return paperId;
    } catch (_) {
      if (pointId != null) {
        final failedPointId = pointId;
        await (_databaseProvider.appDb.delete(
          _databaseProvider.appDb.pointsTransactions,
        )..where((row) => row.id.equals(failedPointId))).go();
      }
      rethrow;
    }
  }

  Future<int> _saveManualPaper({
    required String name,
    required List<int> questionIds,
  }) async {
    final examDao = ExamDao(_databaseProvider);
    final paperId = await examDao.savePaper(title: name);
    await examDao.savePaperQuestions(paperId, questionIds);
    try {
      await SyncManager().enqueue(
        entityType: SyncEntityType.exam,
        operation: SyncOperationType.upsert,
        localId: paperId,
        payload: jsonEncode({'title': name, 'questions': questionIds}),
      );
    } catch (_) {
      // The local paper is complete; a later sync pass can repair the queue.
    }
    return paperId;
  }
}
