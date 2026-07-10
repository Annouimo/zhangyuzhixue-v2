import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import '../../../lib/data/database/app_database.dart' as db;
import '../../../lib/data/daos/sync_queue_dao.dart';

void main() {
  late db.AppDatabase database;
  late SyncQueueDao dao;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    dao = SyncQueueDao(database);
  });

  tearDown(() => database.close());

  group('SyncQueueDao', () {
    test('isEmpty returns true initially', () async {
      expect(await dao.isEmpty(), true);
    });

    test('enqueue creates pending record', () async {
      final id = await dao.enqueue(
        entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{}',
      );
      expect(id, greaterThan(0));
    });

    test('getPending returns pending records', () async {
      await dao.enqueue(entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{}');
      final pending = await dao.getPending();
      expect(pending.length, 1);
      expect(pending.first.status, 'pending');
    });

    test('getPending respects limit', () async {
      for (var i = 0; i < 5; i++) {
        await dao.enqueue(entityType: 'rating', operationType: 'upsert', entityId: i, payload: '{}');
      }
      expect((await dao.getPending(limit: 2)).length, 2);
      expect((await dao.getPending(limit: 10)).length, 5);
    });

    test('markInProgress updates status', () async {
      final id = await dao.enqueue(entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{}');
      await dao.markInProgress(id);
      final pending = await dao.getPending();
      expect(pending.length, 1);
      expect(pending.first.status, 'inProgress');
    });

    test('markSuccess deletes record', () async {
      final id = await dao.enqueue(entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{}');
      await dao.markSuccess(id);
      expect(await dao.isEmpty(), true);
    });

    test('markFailed sets status to failed and increments retry_count', () async {
      final id = await dao.enqueue(entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{}');
      await dao.markFailed(id);
      // query directly since markFailed sets status to 'failed' (not pending)
      final rows = await database.customSelect(
        'SELECT * FROM sync_queue WHERE id = ?',
        variables: [Variable(id)],
        readsFrom: {database.syncQueue},
      ).get();
      expect(rows.length, 1);
      expect(rows.first.data['status'], 'failed');
      expect(rows.first.data['retry_count'], 1);
    });

    test('hasFailed returns true when failed exists', () async {
      expect(await dao.hasFailed(), false);
      final id = await dao.enqueue(entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{}');
      await dao.markFailed(id);
      expect(await dao.hasFailed(), true);
    });

    test('clearAll removes all records', () async {
      await dao.enqueue(entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{}');
      await dao.enqueue(entityType: 'exam', operationType: 'upsert', entityId: 2, payload: '{}');
      await dao.clearAll();
      expect(await dao.isEmpty(), true);
    });
  });
}
