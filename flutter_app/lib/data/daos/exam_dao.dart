import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;
import '../debug/audit_logger.dart';

/// 组卷/收藏/点赞数据访问层（user 库）
class ExamDao {
  final db.AppDatabase _db;
  const ExamDao(this._db);

  Future<List<db.CustomPaperRow>> listCreated() async {
    final q = _db.select(_db.customPapers)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    final rows = await q.get();
    AuditLogger.instance.dao('ExamDao.listCreated', rows.length, {});
    return rows;
  }

  Future<List<db.CustomPaperRow>> listPublic() async {
    final q = _db.select(_db.customPapers)
      ..where((t) => t.isPublic.equals(1))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    final rows = await q.get();
    AuditLogger.instance.dao('ExamDao.listPublic', rows.length, {});
    return rows;
  }

  Future<db.CustomPaperRow?> getById(int id) async {
    final q = _db.select(_db.customPapers)..where((t) => t.id.equals(id));
    final result = await q.getSingleOrNull();
    AuditLogger.instance.dao('ExamDao.getById', result != null ? 1 : 0, {'id': id});
    return result;
  }

  Future<int> savePaper({
    required String title,
    String? description,
    String? filterSnapshot,
  }) async {
    final now = DateTime.now().toIso8601String();
    return _db.into(_db.customPapers).insert(db.CustomPapersCompanion(
      title: Value(title),
      description: Value(description),
      filterSnapshot: Value(filterSnapshot),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  Future<void> deletePaper(int id) async {
    final q = _db.delete(_db.customPapers)..where((t) => t.id.equals(id));
    await q.go();
  }

  Future<void> togglePublic(int id) async {
    final paper = await getById(id);
    if (paper != null) {
      final q = _db.update(_db.customPapers)..where((t) => t.id.equals(id));
      await q.write(db.CustomPapersCompanion(
        isPublic: Value(paper.isPublic == 0 ? 1 : 0),
      ));
    }
  }

  Future<List<db.CustomPaperQuestionRow>> getQuestions(int paperId) async {
    final q = _db.select(_db.customPaperQuestions)
      ..where((t) => t.paperId.equals(paperId));
    q.orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    final rows = await q.get();
    AuditLogger.instance.dao('ExamDao.getQuestions', rows.length, {'paperId': paperId});
    return rows;
  }

  Future<void> savePaperQuestions(int paperId, List<int> questionIds) async {
    final dq = _db.delete(_db.customPaperQuestions)
      ..where((t) => t.paperId.equals(paperId));
    await dq.go();
    for (var i = 0; i < questionIds.length; i++) {
      await _db.into(_db.customPaperQuestions).insert(
        db.CustomPaperQuestionsCompanion(
          paperId: Value(paperId),
          questionId: Value(questionIds[i]),
          sortOrder: Value(i),
        ),
      );
    }
  }

  Future<db.PaperLikeRow?> getLike(int paperId) async {
    final q = _db.select(_db.paperLikes)
      ..where((t) => t.paperId.equals(paperId));
    final result = await q.getSingleOrNull();
    AuditLogger.instance.dao('ExamDao.getLike', result != null ? 1 : 0, {'paperId': paperId});
    return result;
  }

  Future<void> toggleLike(int paperId) async {
    final existing = await (_db.select(_db.paperLikes)
      ..where((t) => t.paperId.equals(paperId))).getSingleOrNull();
    if (existing != null) {
      final q = _db.delete(_db.paperLikes)..where((t) => t.paperId.equals(paperId));
      await q.go();
    } else {
      final now = DateTime.now().toIso8601String();
      await _db.into(_db.paperLikes).insert(db.PaperLikesCompanion(
        paperId: Value(paperId),
        createdAt: Value(now),
      ));
    }
  }

  Future<db.PaperCollectRow?> getCollect(int paperId) async {
    final q = _db.select(_db.paperCollects)
      ..where((t) => t.paperId.equals(paperId));
    final result = await q.getSingleOrNull();
    AuditLogger.instance.dao('ExamDao.getCollect', result != null ? 1 : 0, {'paperId': paperId});
    return result;
  }

  Future<void> toggleCollect(int paperId) async {
    final existing = await (_db.select(_db.paperCollects)
      ..where((t) => t.paperId.equals(paperId))).getSingleOrNull();
    if (existing != null) {
      await (_db.delete(_db.paperCollects)
        ..where((t) => t.paperId.equals(paperId))).go();
    } else {
      await _db.into(_db.paperCollects).insert(db.PaperCollectsCompanion(
        paperId: Value(paperId),
        createdAt: Value(DateTime.now().toIso8601String()),
      ));
    }
  }

  /// 获取所有收藏的试卷 ID
  Future<List<int>> getCollectedPaperIds() async {
    final rows = await _db.select(_db.paperCollects).get();
    AuditLogger.instance.dao('ExamDao.getCollectedPaperIds', rows.length, {});
    return rows.map((r) => r.paperId).toList();
  }

  /// 获取已创建的组卷总数
  Future<int> getPaperCount() async {
    final result = await _db.customSelect(
      'SELECT COUNT(*) AS cnt FROM custom_paper',
    ).getSingle();
    final count = result.read<int>('cnt');
    AuditLogger.instance.dao('ExamDao.getPaperCount', count, {});
    return count;
  }

  /// 获取试卷点赞总数
  Future<int> getLikeCount(int paperId) async {
    final rows = await (_db.select(_db.paperLikes)
      ..where((t) => t.paperId.equals(paperId))).get();
    return rows.length;
  }

  /// 获取试卷收藏总数
  Future<int> getCollectCount(int paperId) async {
    final rows = await (_db.select(_db.paperCollects)
      ..where((t) => t.paperId.equals(paperId))).get();
    return rows.length;
  }
}
