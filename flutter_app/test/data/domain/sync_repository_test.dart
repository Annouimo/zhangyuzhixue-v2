import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/app_database.dart' as db;
import 'package:flutter_app/data/daos/sync_queue_dao.dart';
import 'package:flutter_app/domain/sync_repository.dart';

void main() {
  late db.AppDatabase database;
  late SyncQueueDao dao;
  late SyncRepository repo;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    dao = SyncQueueDao(database);
    repo = SyncRepository(dao);
  });

  tearDown(() => database.close());

  group('SyncRepository', () {
    test('isEmpty returns true when empty', () async {
      expect(await repo.isEmpty(), true);
    });

    test('getFailedCount returns 0 initially', () async {
      expect(await repo.getFailedCount(), 0);
    });

    test('hasFailed returns false initially', () async {
      expect(await repo.hasFailed(), false);
    });

    test('allSuccessText returns text when empty', () async {
      final text = await repo.allSuccessText();
      expect(text, '全部已同步');
    });

    test('getQueue returns items after enqueue', () async {
      await dao.enqueue(entityType: 'submission', operationType: 'create', entityId: 1, payload: '{}');
      final queue = await repo.getQueue();
      expect(queue.length, 1);
      expect(queue.first.entityType, 'submission');
    });
  });
}
