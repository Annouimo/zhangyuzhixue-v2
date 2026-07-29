import 'package:drift/native.dart';
import 'package:flutter_app/data/daos/paper_folder_dao.dart';
import 'package:flutter_app/data/database/app_database.dart' as db;
import 'package:flutter_app/data/database/database_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late db.AppDatabase database;
  late PaperFolderDao dao;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    DatabaseProvider().setAppDbForTesting(database);
    dao = PaperFolderDao(DatabaseProvider());
  });

  tearDown(() => database.close());

  test('creates a default folder only once', () async {
    final first = await dao.getOrCreateDefault();
    final second = await dao.getOrCreateDefault();

    expect(second, first);
    expect(await dao.listFolders(), hasLength(1));
  });

  test('replaces questions in order and removes duplicates', () async {
    final folderId = await dao.createFolder('函数题');

    await dao.replaceQuestions(folderId, [7, 3, 7, 9]);

    final rows = await dao.getQuestions(folderId);
    expect(rows.map((row) => row.questionId), [7, 3, 9]);
    expect(rows.map((row) => row.sortOrder), [0, 1, 2]);
  });

  test(
    'addQuestions preserves existing order and delete cascades locally',
    () async {
      final folderId = await dao.createFolder('综合题');
      await dao.replaceQuestions(folderId, [1, 2]);
      await dao.addQuestions(folderId, [2, 3]);

      expect((await dao.getQuestions(folderId)).map((row) => row.questionId), [
        1,
        2,
        3,
      ]);

      await dao.deleteFolder(folderId);
      expect(await dao.getFolder(folderId), isNull);
      expect(await dao.getQuestions(folderId), isEmpty);
    },
  );
}
