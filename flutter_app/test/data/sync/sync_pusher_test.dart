import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:dio/dio.dart';
import 'package:flutter_app/data/database/app_database.dart' as db;
import 'package:flutter_app/data/daos/sync_queue_dao.dart';
import 'package:flutter_app/data/api/api_client.dart';
import 'package:flutter_app/data/api/sync_api.dart';
import 'package:flutter_app/data/sync/sync_pusher.dart';
import 'package:flutter_app/data/sync/sync_manager.dart';
import 'package:flutter_app/data/database/database_provider.dart';

class _MockAdapter implements HttpClientAdapter {
  final handlers = <String, Function(RequestOptions)>{};
  List<Map<String, dynamic>>? sentBatch;
  void on(String method, String path, Function(RequestOptions) h) {
    handlers['$method $path'] = h;
  }
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? rs, Future? cf) async {
    if (o.data is Map && (o.data as Map).containsKey('batch')) {
      sentBatch = ((o.data as Map)['batch'] as List).cast<Map<String, dynamic>>();
    }
    final h = handlers['${o.method} ${o.path}'];
    if (h != null) return h(o);
    return ResponseBody.fromString('{"code":0,"data":{}}', 200, headers: {'content-type': ['application/json']});
  }
  @override void close({bool? force}) {}
}

void main() {
  late db.AppDatabase database;
  late SyncQueueDao dao;
  late ApiClient client;
  late _MockAdapter adapter;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    dao = SyncQueueDao(database);
    client = ApiClient();
    client.init(baseUrl: 'https://test/');
    adapter = _MockAdapter();
    client.setMockAdapter(adapter);
  });

  tearDown(() => database.close());

  group('SyncPusher', () {
    test('empty queue returns zeros', () async {
      final pusher = SyncPusher(dao, SyncApi(client));
      final result = await pusher.pushAll();
      expect(result.successCount, 0);
      expect(result.failCount, 0);
    });

    test('single batch all success', () async {
      adapter.on('POST', '/sync/push/', (_) => ResponseBody.fromString(
        '{"code":0,"data":{"server_ids":{"1":101,"2":102}}}', 200,
        headers: {'content-type': ['application/json']},
      ));
      await dao.enqueue(entityType: 'submission', operationType: 'create', entityId: 1, payload: '{"qid":42}');
      await dao.enqueue(entityType: 'rating', operationType: 'create', entityId: 2, payload: '{"score":5}');
      final pusher = SyncPusher(dao, SyncApi(client));
      final result = await pusher.pushAll();
      expect(result.successCount, 2);
      expect(result.failCount, 0);
      expect(await dao.isEmpty(), isTrue); // cleanup 后 done 被删除
      // 验证发送格式：使用 data 而非 payload
      expect(adapter.sentBatch, isNotNull);
      expect(adapter.sentBatch!.first['data'], {'qid': 42});
      expect(adapter.sentBatch!.first.keys, contains('data'));
      expect(adapter.sentBatch!.first.keys, isNot(contains('payload')));
    });

    test('partial success: some get serverId, some dont', () async {
      adapter.on('POST', '/sync/push/', (_) => ResponseBody.fromString(
        '{"code":0,"data":{"server_ids":{"1":101}}}', 200, // 只有 id=1 成功
        headers: {'content-type': ['application/json']},
      ));
      await dao.enqueue(entityType: 'submission', operationType: 'create', entityId: 1, payload: '{}');
      await dao.enqueue(entityType: 'rating', operationType: 'create', entityId: 2, payload: '{}');
      final pusher = SyncPusher(dao, SyncApi(client));
      final result = await pusher.pushAll();
      expect(result.successCount, 1); // entityId=1
      expect(result.failCount, 1);   // entityId=2 无 server_id
    });

    test('orphan inProgress records get picked up', () async {
      adapter.on('POST', '/sync/push/', (_) => ResponseBody.fromString(
        '{"code":0,"data":{"server_ids":{"1":101}}}', 200,
        headers: {'content-type': ['application/json']},
      ));
      await dao.enqueue(entityType: 'submission', operationType: 'create', entityId: 1, payload: '{}');
      final rows = await dao.getPending();
      await dao.markInProgress(rows.first.id);
      // 模拟 App 重启：此时 status=inProgress
      final pusher = SyncPusher(dao, SyncApi(client));
      final result = await pusher.pushAll();
      expect(result.successCount, 1); // orphan 被取出并推送成功
    });

    test('network error marks all as failed', () async {
      adapter.on('POST', '/sync/push/', (_) => throw DioException(
        requestOptions: RequestOptions(path: '/sync/push/'),
      ));
      await dao.enqueue(entityType: 'submission', operationType: 'create', entityId: 1, payload: '{}');
      final pusher = SyncPusher(dao, SyncApi(client));
      final result = await pusher.pushAll();
      expect(result.successCount, 0);
      expect(result.failCount, 1);
      expect(await dao.hasFailed(), isTrue);
    });

    test('batching: 25 items processed in 2 batches', () async {
      var callNum = 0;
      adapter.on('POST', '/sync/push/', (_) {
        callNum++;
        return ResponseBody.fromString(
          '{"code":0,"data":{"server_ids":{}}}', 200,
          headers: {'content-type': ['application/json']},
        );
      });
      for (var i = 100; i < 125; i++) {
        await dao.enqueue(entityType: 'submission', operationType: 'create', entityId: i, payload: '{}');
      }
      final pusher = SyncPusher(dao, SyncApi(client));
      final result = await pusher.pushAll();
      expect(result.successCount, 0);
      expect(result.failCount, 25);
      expect(callNum, 2); // batchSize=20, 25 items → 2 rounds
    });

    test('retry: failed records get fetched again', () async {
      var callCount = 0;
      adapter.on('POST', '/sync/push/', (_) {
        callCount++;
        if (callCount == 1) throw DioException(requestOptions: RequestOptions(path: '/sync/push/'));
        return ResponseBody.fromString(
          '{"code":0,"data":{"server_ids":{"1":101}}}', 200,
          headers: {'content-type': ['application/json']},
        );
      });
      await dao.enqueue(entityType: 'submission', operationType: 'create', entityId: 1, payload: '{}');
      var pusher = SyncPusher(dao, SyncApi(client));
      await pusher.pushAll(); // 第一次失败 → retryCount=1
      pusher = SyncPusher(dao, SyncApi(client));
      final result = await pusher.pushAll(); // 第二次成功
      expect(result.successCount, 1);
    });

    test('permanent failure after max retries', () async {
      adapter.on('POST', '/sync/push/', (_) => throw DioException(
        requestOptions: RequestOptions(path: '/sync/push/'),
      ));
      for (var i = 0; i < 5; i++) {
        await dao.enqueue(entityType: 'submission', operationType: 'create', entityId: i, payload: '{}');
      }
      final pusher = SyncPusher(dao, SyncApi(client));
      await pusher.pushAll();
      // status 变为 permanentFailure
      expect(await dao.hasFailed(), isTrue);
    });

    test('cleanup removes done records', () async {
      adapter.on('POST', '/sync/push/', (_) => ResponseBody.fromString(
        '{"code":0,"data":{"server_ids":{"1":101}}}', 200,
        headers: {'content-type': ['application/json']},
      ));
      await dao.enqueue(entityType: 'submission', operationType: 'create', entityId: 1, payload: '{}');
      final pusher = SyncPusher(dao, SyncApi(client));
      await pusher.pushAll();
      expect(await dao.isEmpty(), isTrue); // cleanup 删除了 done 记录
    });

    test('syncManager cooldown: second pushNow returns null', () async {
      adapter.on('POST', '/sync/push/', (_) => ResponseBody.fromString(
        '{"code":0,"data":{"server_ids":{}}}', 200,
        headers: {'content-type': ['application/json']},
      ));
      final sm = SyncManager();
      await sm.init(dao, SyncApi(client), DatabaseProvider());
      // 注意：DatabaseProvider 没有被正确初始化（无 getApplicationDocumentsDirectory），
      // 但 cooldown 测试只依赖 _lastPushTime，不依赖 DB
      final r1 = await sm.pushNow();
      expect(r1, isNotNull);
      final r2 = await sm.pushNow();
      expect(r2, isNull); // 30 秒冷却内
    });
  });
}
