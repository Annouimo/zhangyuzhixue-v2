import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/app_database.dart' as db;
import 'package:flutter_app/data/daos/sync_queue_dao.dart';
import 'package:flutter_app/data/database/database_provider.dart';

void main() {
  late db.AppDatabase database;
  late SyncQueueDao dao;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    DatabaseProvider().setAppDbForTesting(database);
    dao = SyncQueueDao(DatabaseProvider());
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

    test('markSuccess sets status to done', () async {
      final id = await dao.enqueue(entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{}');
      await dao.markSuccess(id, serverId: 101);
      final rows = await database.select(database.syncQueue).get();
      expect(rows.length, 1);
      expect(rows.first.status, 'done');
      expect(rows.first.serverId, 101);
    });

    test('markFailed sets status to failed and increments retry_count', () async {
      final id = await dao.enqueue(entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{}');
      await dao.markFailed(id);
      var q = database.select(database.syncQueue);
      q.where((t) => t.id.equals(id));
      final r = await q.get();
      expect(r.length, 1);
      expect(r.first.status, 'failed');
      expect(r.first.retryCount, 1);
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

    test('markPermanentFailures converts expired retries', () async {
      final id = await dao.enqueue(entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{}');
      // 模拟 5 次重试
      for (var i = 0; i < 5; i++) {
        await dao.markFailed(id);
      }
      await dao.markPermanentFailures(5);
      final rows = await database.select(database.syncQueue).get();
      expect(rows.first.status, 'permanentFailure');
    });

    test('resetFailed resets failed items to pending', () async {
      final id = await dao.enqueue(entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{}');
      await dao.markFailed(id);
      expect(await dao.hasFailed(), true);
      // 重置
      await dao.resetFailed();
      expect(await dao.hasFailed(), false);
      final rows = await database.select(database.syncQueue).get();
      expect(rows.first.status, 'pending');
      expect(rows.first.retryCount, 0);
    });

    test('resetFailed no-ops when no failed items', () async {
      // 只有 pending 项
      await dao.enqueue(entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{}');
      await dao.resetFailed();
      expect(await dao.hasFailed(), false);
      final rows = await database.select(database.syncQueue).get();
      expect(rows.length, 1);
      expect(rows.first.status, 'pending');
    });
  });
}
