import 'package:drift/drift.dart';

import '../database/app_database.dart' as db;
import '../database/database_provider.dart';

class PaperFolderDao {
  PaperFolderDao(this._provider);

  final DatabaseProvider _provider;
  db.AppDatabase get _db => _provider.appDb;

  Future<List<db.PaperFolderRow>> listFolders() {
    final query = _db.select(_db.paperFolders)
      ..orderBy([
        (row) =>
            OrderingTerm(expression: row.updatedAt, mode: OrderingMode.desc),
      ]);
    return query.get();
  }

  Future<db.PaperFolderRow?> getFolder(int id) => (_db.select(
    _db.paperFolders,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<List<db.PaperFolderQuestionRow>> getQuestions(int folderId) {
    final query = _db.select(_db.paperFolderQuestions)
      ..where((row) => row.folderId.equals(folderId))
      ..orderBy([(row) => OrderingTerm(expression: row.sortOrder)]);
    return query.get();
  }

  Future<int> createFolder(String name, {bool isDefault = false}) {
    final now = DateTime.now().toIso8601String();
    return _db
        .into(_db.paperFolders)
        .insert(
          db.PaperFoldersCompanion.insert(
            name: name,
            isDefault: Value(isDefault ? 1 : 0),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<int> getOrCreateDefault() async {
    final folders = await listFolders();
    for (final folder in folders) {
      if (folder.isDefault == 1) return folder.id;
    }
    return createFolder('默认试题篮', isDefault: true);
  }

  Future<void> rename(int folderId, String name) async {
    await (_db.update(
      _db.paperFolders,
    )..where((row) => row.id.equals(folderId))).write(
      db.PaperFoldersCompanion(
        name: Value(name),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> replaceQuestions(int folderId, List<int> questionIds) async {
    final uniqueIds = <int>[];
    final seen = <int>{};
    for (final id in questionIds) {
      if (seen.add(id)) uniqueIds.add(id);
    }
    await _db.transaction(() async {
      await (_db.delete(
        _db.paperFolderQuestions,
      )..where((row) => row.folderId.equals(folderId))).go();
      final now = DateTime.now().toIso8601String();
      for (var index = 0; index < uniqueIds.length; index++) {
        await _db
            .into(_db.paperFolderQuestions)
            .insert(
              db.PaperFolderQuestionsCompanion.insert(
                folderId: folderId,
                questionId: uniqueIds[index],
                sortOrder: index,
                createdAt: now,
              ),
            );
      }
      await (_db.update(_db.paperFolders)
            ..where((row) => row.id.equals(folderId)))
          .write(db.PaperFoldersCompanion(updatedAt: Value(now)));
    });
  }

  Future<void> addQuestions(int folderId, Iterable<int> questionIds) async {
    final existing = await getQuestions(folderId);
    await replaceQuestions(folderId, [
      ...existing.map((row) => row.questionId),
      ...questionIds,
    ]);
  }

  Future<int> prependQuestions(int folderId, Iterable<int> questionIds) async {
    final existing = await getQuestions(folderId);
    final existingIds = existing.map((row) => row.questionId).toSet();
    final added = <int>[];
    for (final id in questionIds) {
      if (!existingIds.contains(id) && !added.contains(id)) added.add(id);
    }
    if (added.isEmpty) return 0;
    await replaceQuestions(folderId, [
      ...added,
      ...existing.map((row) => row.questionId),
    ]);
    return added.length;
  }

  Future<void> deleteFolder(int folderId) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.paperFolderQuestions,
      )..where((row) => row.folderId.equals(folderId))).go();
      await (_db.delete(
        _db.paperFolders,
      )..where((row) => row.id.equals(folderId))).go();
    });
  }

  Future<void> markGenerated({
    required int folderId,
    required int paperId,
    required String fingerprint,
  }) async {
    final now = DateTime.now().toIso8601String();
    await (_db.update(
      _db.paperFolders,
    )..where((row) => row.id.equals(folderId))).write(
      db.PaperFoldersCompanion(
        updatedAt: Value(now),
        lastGeneratedAt: Value(now),
        lastGeneratedFingerprint: Value(fingerprint),
        lastGeneratedPaperId: Value(paperId),
      ),
    );
  }
}
