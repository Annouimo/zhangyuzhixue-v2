import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/app_database.dart' as db;
import 'package:flutter_app/data/daos/sync_queue_dao.dart';
import 'package:flutter_app/data/api/api_client.dart';
import 'package:flutter_app/data/api/sync_api.dart';
import 'package:flutter_app/data/sync/sync_manager.dart';
import 'package:flutter_app/data/sync/sync_types.dart';

import 'package:flutter_app/data/database/database_provider.dart';

/// 所有测试共享同一个内存 DB，避免单例重新 init 问题
void main() {
  late db.AppDatabase database;
  late SyncQueueDao dao;
  late SyncManager manager;

  setUp(() async {
    database = db.AppDatabase(NativeDatabase.memory());
    DatabaseProvider().setAppDbForTesting(database);
    dao = SyncQueueDao(DatabaseProvider());
    manager = SyncManager();
    await manager.init(dao, SyncApi(ApiClient()), DatabaseProvider());
  });

  tearDown(() async {
    await database.close();
    await SyncManager.resetForTesting();
  });

  test('enqueue adds to queue', () async {
    await manager.enqueue(
      entityType: SyncEntityType.rating,
      operation: SyncOperationType.upsert,
      localId: 42,
      payload: '{"score":5}',
    );
    expect(await dao.isEmpty(), isFalse);
  });

  test('clearQueue removes all', () async {
    await manager.enqueue(
      entityType: SyncEntityType.rating,
      operation: SyncOperationType.upsert,
      localId: 1,
      payload: '{}',
    );
    await manager.clearQueue();
    expect(await dao.isEmpty(), isTrue);
  });

  test('pushNow returns summary', () async {
    // 不要在 enqueue 之前或之后调 pushNow（enqueue 内部会调一次设冷却）
    // 直接测空队列的 pushAll：返回 successCount=0, failCount=0
    final result = await manager.pushNow();
    expect(result, isNotNull);
    expect(result!.successCount, 0);
    expect(result.failCount, 0);
  });

  test('onAppStart does not throw', () async {
    await manager.onAppStart();
  });
}
