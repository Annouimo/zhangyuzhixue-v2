import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;

/// 组卷/收藏/点赞数据访问层（user 库）
class ExamDao {
  final db.AppDatabase _db;
  const ExamDao(this._db);

  // ── 我创建的组卷 ──

  Future<List<db.CustomPaperRow>> listCreated() async {
    final rows = await _db.customSelect(
      'SELECT * FROM custom_papers ORDER BY created_at DESC',
      readsFrom: {_db.customPapers},
    ).get();
    return rows.map((r) => _db.customPapers.map(r.data)).toList();
  }

  Future<db.CustomPaperRow?> getById(int id) async {
    final rows = await _db.customSelect(
      'SELECT * FROM custom_papers WHERE id = ?',
      variables: [Variable(id)],
      readsFrom: {_db.customPapers},
    ).get();
    if (rows.isEmpty) return null;
    return _db.customPapers.map(rows.first.data);
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
    final q = _db.delete(_db.customPapers);
    q.where((t) => t.id.equals(id));
    await q.go();
  }

  Future<void> togglePublic(int id) async {
    final paper = await getById(id);
    if (paper != null) {
      final q = _db.update(_db.customPapers);
      q.where((t) => t.id.equals(id));
      await q.write(db.CustomPapersCompanion(
        isPublic: Value(paper.isPublic == 0 ? 1 : 0),
      ));
    }
  }

  // ── 组卷题目 ──

  Future<List<db.CustomPaperQuestionRow>> getQuestions(int paperId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM custom_paper_questions WHERE paper_id = ? ORDER BY sort_order',
      variables: [Variable(paperId)],
      readsFrom: {_db.customPaperQuestions},
    ).get();
    return rows.map((r) => _db.customPaperQuestions.map(r.data)).toList();
  }

  Future<void> savePaperQuestions(int paperId, List<int> questionIds) async {
    // 先删后插
    final dq = _db.delete(_db.customPaperQuestions);
    dq.where((t) => t.paperId.equals(paperId));
    await dq.go();
    for (var i = 0; i < questionIds.length; i++) {
      await _db.into(_db.customPaperQuestions).insert(db.CustomPaperQuestionsCompanion(
        paperId: Value(paperId),
        questionId: Value(questionIds[i]),
        sortOrder: Value(i),
      ));
    }
  }

  // ── 点赞 ──

  Future<db.PaperLikeRow?> getLike(int paperId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM paper_likes WHERE paper_id = ?',
      variables: [Variable(paperId)],
      readsFrom: {_db.paperLikes},
    ).get();
    if (rows.isEmpty) return null;
    return _db.paperLikes.map(rows.first.data);
  }

  Future<void> toggleLike(int paperId) async {
    final existing = await getLike(paperId);
    if (existing != null) {
      final q = _db.delete(_db.paperLikes);
      q.where((t) => t.paperId.equals(paperId));
      await q.go();
    } else {
      final now = DateTime.now().toIso8601String();
      await _db.into(_db.paperLikes).insert(db.PaperLikesCompanion(
        paperId: Value(paperId),
        createdAt: Value(now),
      ));
    }
  }

  // ── 收藏 ──

  Future<db.PaperCollectRow?> getCollect(int paperId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM paper_collects WHERE paper_id = ?',
      variables: [Variable(paperId)],
      readsFrom: {_db.paperCollects},
    ).get();
    if (rows.isEmpty) return null;
    return _db.paperCollects.map(rows.first.data);
  }

  Future<void> toggleCollect(int paperId) async {
    final existing = await getCollect(paperId);
    if (existing != null) {
      final q = _db.delete(_db.paperCollects);
      q.where((t) => t.paperId.equals(paperId));
      await q.go();
    } else {
      final now = DateTime.now().toIso8601String();
      await _db.into(_db.paperCollects).insert(db.PaperCollectsCompanion(
        paperId: Value(paperId),
        createdAt: Value(now),
      ));
    }
  }
}
