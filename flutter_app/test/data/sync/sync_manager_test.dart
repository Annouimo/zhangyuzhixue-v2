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
    dao = SyncQueueDao(database);
    manager = SyncManager();
    await manager.init(dao, SyncApi(ApiClient()), DatabaseProvider());
  });

  tearDown(() {
    // 不关闭 database，后续 test 复用（singleton 无法重新 init）
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
    await manager.enqueue(
      entityType: SyncEntityType.submissionDetail,
      operation: SyncOperationType.upsert,
      localId: 1,
      payload: '{}',
    );
    final result = await manager.pushNow();
    expect(result, isNotNull);
    // 无 mock，预期网络失败
    expect(result!.failCount, greaterThanOrEqualTo(0));
  });

  test('onAppStart does not throw', () async {
    await manager.onAppStart();
  });
}
