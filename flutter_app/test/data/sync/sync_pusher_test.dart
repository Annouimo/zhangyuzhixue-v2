import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:dio/dio.dart';
import 'package:flutter_app/data/database/app_database.dart' as db;
import 'package:flutter_app/data/daos/sync_queue_dao.dart';
import 'package:flutter_app/data/api/api_client.dart';
import 'package:flutter_app/data/api/sync_api.dart';
import 'package:flutter_app/data/sync/sync_pusher.dart';
import 'package:flutter_app/data/database/database_provider.dart';

/// Mock adapter that returns controllable server_ids responses
class MockPushAdapter implements HttpClientAdapter {
  int callCount = 0;
  Map<int, int> serverIds = {};
  bool throwOnPush = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    callCount++;
    if (throwOnPush) {
      throw DioException(requestOptions: options, message: '模拟网络错误');
    }
    return ResponseBody.fromString(
      '{"code":0,"data":{"server_ids":${_serverIdsJson()}}}', 200,
      headers: {'content-type': ['application/json']},
    );
  }

  String _serverIdsJson() {
    if (serverIds.isEmpty) return '{}';
    return serverIds.map((k, v) => MapEntry('"$k"', v)).toString();
  }

  @override
  void close({bool? force}) {}
}

void main() {
  late db.AppDatabase database;
  late SyncQueueDao dao;
  late MockPushAdapter adapter;
  late SyncPusher pusher;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    DatabaseProvider().setAppDbForTesting(database);
    dao = SyncQueueDao(DatabaseProvider());

    adapter = MockPushAdapter();
    final client = ApiClient();
    client.init(baseUrl: 'https://test/');
    client.setMockAdapter(adapter);

    final api = SyncApi(client);
    pusher = SyncPusher(dao, api);
  });

  tearDown(() async {
    await database.close();
  });

  group('SyncPusher.pushAll', () {
    test('returns success 0 when queue is empty', () async {
      final result = await pusher.pushAll();
      expect(result.successCount, 0);
      expect(result.failCount, 0);
    });

    test('pushes single item successfully', () async {
      await dao.enqueue(
        entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{"score":5}',
      );
      adapter.serverIds = {1: 101};

      final result = await pusher.pushAll();
      expect(result.successCount, 1);
      expect(result.failCount, 0);
      expect(adapter.callCount, 1);

      // 验证队列已清理
      expect(await dao.isEmpty(), isTrue);
    });

    test('pushes batch of multiple items', () async {
      for (var i = 1; i <= 3; i++) {
        await dao.enqueue(
          entityType: 'rating', operationType: 'upsert', entityId: i, payload: '{"score":$i}',
        );
      }
      adapter.serverIds = {1: 101, 2: 102, 3: 103};

      final result = await pusher.pushAll();
      expect(result.successCount, 3);
      expect(result.failCount, 0);
      expect(await dao.isEmpty(), isTrue);
    });

    test('item without serverId is counted as fail', () async {
      await dao.enqueue(
        entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{"score":5}',
      );
      await dao.enqueue(
        entityType: 'rating', operationType: 'upsert', entityId: 2, payload: '{"score":3}',
      );
      // Only item 1 gets a server_id
      adapter.serverIds = {1: 101};

      final result = await pusher.pushAll();
      expect(result.successCount, 1);
      expect(result.failCount, 1);
    });

    test('network error marks all as failed', () async {
      await dao.enqueue(
        entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{}',
      );
      adapter.throwOnPush = true;

      final result = await pusher.pushAll();
      expect(result.successCount, 0);
      expect(result.failCount, 1);
    });

    test('marks expired retries as permanentFailure', () async {
      await dao.enqueue(
        entityType: 'rating', operationType: 'upsert', entityId: 1, payload: '{}',
      );
      adapter.throwOnPush = true;

      // Push 5 times to exhaust retry count
      for (var i = 0; i < 5; i++) {
        await pusher.pushAll();
        // Reset throw for retry counting (markFailed increments retry_count)
      }

      // Now check: permanentFailure should be set
      final rows = await database.select(database.syncQueue).get();
      expect(rows.first.status, 'permanentFailure');
    });

    test('send correct entity_type and data fields', () async {
      await dao.enqueue(
        entityType: 'step_feedback', operationType: 'upsert', entityId: 42,
        payload: '{"step_number":1,"status":"correct"}',
      );
      adapter.serverIds = {42: 201};

      await pusher.pushAll();
      expect(adapter.callCount, 1);
    });
  });

  group('SyncPusher Constants', () {
    test('maxRetries is 5', () {
      expect(SyncPusher.maxRetries, 5);
    });

    test('batchSize is 20', () {
      expect(SyncPusher.batchSize, 20);
    });
  });
}
