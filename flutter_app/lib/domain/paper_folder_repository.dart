import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../data/daos/exam_dao.dart';
import '../data/daos/paper_folder_dao.dart';
import '../data/daos/question_dao.dart';
import '../data/database/app_database.dart' as db;
import '../data/database/assets_database.dart' as assets_db;
import '../data/database/database_provider.dart';
import '../data/prefs/app_prefs.dart';
import '../data/sync/sync_manager.dart';
import '../data/sync/sync_types.dart';
import 'exam_repository.dart';

String normalizePaperBasketName(String name) => name.replaceAll('组卷夹', '试题篮');

class PaperFolderSummary {
  const PaperFolderSummary({
    required this.id,
    required this.name,
    required this.questionCount,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final int questionCount;
  final String updatedAt;
}

class PaperFolderDetail {
  const PaperFolderDetail({required this.folder, required this.questions});

  final db.PaperFolderRow folder;
  final List<SearchQuestion> questions;
}

class PaperFolderRepository {
  PaperFolderRepository(
    this._folderDao,
    this._questionDao,
    this._examDao,
    this._provider,
  );

  factory PaperFolderRepository.local() {
    final provider = DatabaseProvider();
    return PaperFolderRepository(
      PaperFolderDao(provider),
      QuestionDao(provider),
      ExamDao(provider),
      provider,
    );
  }

  final PaperFolderDao _folderDao;
  final QuestionDao _questionDao;
  final ExamDao _examDao;
  final DatabaseProvider _provider;

  Future<List<PaperFolderSummary>> list() async {
    final folders = await _folderDao.listFolders();
    final result = <PaperFolderSummary>[];
    for (final folder in folders) {
      result.add(
        PaperFolderSummary(
          id: folder.id,
          name: normalizePaperBasketName(folder.name),
          questionCount: (await _folderDao.getQuestions(folder.id)).length,
          updatedAt: folder.updatedAt,
        ),
      );
    }
    return result;
  }

  Future<int> create(String name) async {
    return _create(normalizePaperBasketName(name), isDefault: false);
  }

  Future<int> _create(String name, {required bool isDefault}) async {
    late int id;
    await _provider.appDb.transaction(() async {
      id = await _folderDao.createFolder(name.trim(), isDefault: isDefault);
      await _enqueueSnapshot(id);
    });
    SyncManager().scheduleOutboxPush();
    return id;
  }

  Future<int> defaultFolderId() async {
    final activeId = AppPrefs().activePaperFolderId;
    if (activeId != null && await _folderDao.getFolder(activeId) != null) {
      return activeId;
    }
    final existing = await _folderDao.listFolders();
    for (final folder in existing) {
      if (folder.isDefault == 1) {
        await AppPrefs().setActivePaperFolderId(folder.id);
        return folder.id;
      }
    }
    final id = await _create('默认试题篮', isDefault: true);
    await AppPrefs().setActivePaperFolderId(id);
    return id;
  }

  Future<void> setActiveFolder(int folderId) async {
    if (await _folderDao.getFolder(folderId) == null) {
      throw StateError('试题篮不存在');
    }
    await AppPrefs().setActivePaperFolderId(folderId);
  }

  Future<PaperFolderDetail> detail(int folderId) async {
    final folder = await _folderDao.getFolder(folderId);
    if (folder == null) throw StateError('试题篮不存在');
    final links = await _folderDao.getQuestions(folderId);
    final rows = await _questionDao.getByIds(
      links.map((item) => item.questionId).toList(growable: false),
    );
    final byId = {for (final row in rows) row.id: row};
    final questions = links
        .map((link) => byId[link.questionId])
        .whereType<assets_db.QuestionRow>()
        .map(
          (row) => SearchQuestion(
            id: row.id,
            title: row.stem,
            meta: '${row.year} ${row.examType} ${row.region}',
            questionType: row.questionType,
            difficulty: row.difficulty ?? 0,
            calculation: row.calculation ?? 0,
          ),
        )
        .toList(growable: false);
    return PaperFolderDetail(
      folder: folder.copyWith(name: normalizePaperBasketName(folder.name)),
      questions: questions,
    );
  }

  Future<void> rename(int folderId, String name) async {
    await _mutateAndSync(
      folderId,
      () => _folderDao.rename(folderId, normalizePaperBasketName(name.trim())),
    );
  }

  Future<void> addQuestions(int folderId, Iterable<int> ids) async {
    await _mutateAndSync(
      folderId,
      () => _folderDao.addQuestions(folderId, ids),
    );
  }

  Future<void> replaceQuestions(int folderId, List<int> ids) async {
    await _mutateAndSync(
      folderId,
      () => _folderDao.replaceQuestions(folderId, ids),
    );
  }

  Future<void> delete(int folderId) async {
    final folder = await _folderDao.getFolder(folderId);
    if (folder == null) return;
    await _provider.appDb.transaction(() async {
      await _folderDao.deleteFolder(folderId);
      await _enqueue(folderId, {
        'server_id': folder.serverId,
        'client_id': 'folder-${folder.id}-${folder.createdAt}',
        'base_revision': folder.revision,
        'deleted': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
    });
    SyncManager().scheduleOutboxPush();
    if (AppPrefs().activePaperFolderId == folderId) {
      await AppPrefs().clearActivePaperFolderId();
    }
  }

  Future<int> copyFromPaper(int paperId, {String? name}) async {
    final paper = await _examDao.getById(paperId);
    if (paper == null) throw StateError('试卷不存在');
    final questions = await _examDao.getQuestions(paperId);
    late int folderId;
    await _provider.appDb.transaction(() async {
      folderId = await _folderDao.createFolder(name ?? '${paper.title}副本');
      await _folderDao.replaceQuestions(
        folderId,
        questions.map((item) => item.questionId).toList(growable: false),
      );
      await _enqueueSnapshot(folderId);
    });
    SyncManager().scheduleOutboxPush();
    return folderId;
  }

  String fingerprint(List<int> questionIds) =>
      sha256.convert(utf8.encode(questionIds.join(','))).toString();

  Future<void> markGenerated(
    int folderId,
    int paperId,
    List<int> questionIds,
  ) async {
    await _mutateAndSync(
      folderId,
      () => _folderDao.markGenerated(
        folderId: folderId,
        paperId: paperId,
        fingerprint: fingerprint(questionIds),
      ),
    );
  }

  Future<void> _enqueueSnapshot(int folderId) async {
    final folder = await _folderDao.getFolder(folderId);
    if (folder == null) return;
    final questions = await _folderDao.getQuestions(folderId);
    int? generatedPaperServerId;
    if (folder.lastGeneratedPaperId != null) {
      generatedPaperServerId = (await _examDao.getById(
        folder.lastGeneratedPaperId!,
      ))?.serverId;
    }
    await _enqueue(folderId, {
      'server_id': folder.serverId,
      'client_id': 'folder-${folder.id}-${folder.createdAt}',
      'base_revision': folder.revision,
      'name': folder.name,
      'is_default': folder.isDefault == 1,
      'updated_at': folder.updatedAt,
      'last_generated_at': folder.lastGeneratedAt,
      'last_generated_fingerprint': folder.lastGeneratedFingerprint,
      'last_generated_paper_id': generatedPaperServerId,
      'questions': questions
          .map(
            (item) => {
              'question_id': item.questionId,
              'sort_order': item.sortOrder,
            },
          )
          .toList(growable: false),
    });
  }

  Future<void> _enqueue(int localId, Map<String, dynamic> payload) async {
    await SyncManager().addToOutbox(
      entityType: SyncEntityType.paperFolder,
      operation: SyncOperationType.upsert,
      localId: localId,
      payload: jsonEncode(payload),
    );
  }

  Future<void> _mutateAndSync(
    int folderId,
    Future<void> Function() mutation,
  ) async {
    await _provider.appDb.transaction(() async {
      await mutation();
      await _enqueueSnapshot(folderId);
    });
    SyncManager().scheduleOutboxPush();
  }
}
