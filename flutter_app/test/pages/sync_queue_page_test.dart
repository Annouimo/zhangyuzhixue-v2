import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/app_database.dart' as db;
import 'package:flutter_app/data/daos/sync_queue_dao.dart';
import 'package:flutter_app/domain/sync_repository.dart';
import 'package:flutter_app/pages/sync_queue_page.dart';

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

  group('SyncQueueDao', () {
    test('hasFailed false when empty', () async {
      expect(await dao.hasFailed(), false);
    });

    test('hasFailed true after markFailed', () async {
      final id = await dao.enqueue(entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{}');
      await dao.markFailed(id);
      expect(await dao.hasFailed(), true);
    });

    test('resetFailed restores pending', () async {
      final id = await dao.enqueue(entityType: 'submission', operationType: 'upsert', entityId: 1, payload: '{}');
      await dao.markFailed(id);
      // 验证有失败
      expect(await dao.hasFailed(), true);
      expect(await dao.getFailedCount(), 1);
      // 重置
      await repo.retryAll();
      expect(await dao.hasFailed(), false);
      expect(await dao.getFailedCount(), 0);
      // 队列项仍在（标记为 pending 而非删除）
      final rows = await dao.getPending();
      expect(rows.length, 1);
      expect(rows.first.status, 'pending');
    });
  });

  group('SyncQueuePage', () {
    testWidgets('shows empty state when queue empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SyncQueuePage(syncRepository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('全部已同步'), findsOneWidget);
    });

    testWidgets('shows pending items', (tester) async {
      await dao.enqueue(entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{}');
      await tester.pumpWidget(
        MaterialApp(home: SyncQueuePage(syncRepository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('评分'), findsOneWidget);
      expect(find.text('等待同步'), findsOneWidget);
    });

    testWidgets('shows failed items with retry count', (tester) async {
      final id = await dao.enqueue(entityType: 'submission', operationType: 'upsert', entityId: 1, payload: '{}');
      await dao.markFailed(id);
      await tester.pumpWidget(
        MaterialApp(home: SyncQueuePage(syncRepository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('提交'), findsOneWidget);
      expect(find.text('同步失败'), findsOneWidget);
      // 有重试按钮（AppBar action）
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
