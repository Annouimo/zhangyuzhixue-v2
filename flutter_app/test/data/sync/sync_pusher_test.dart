import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:dio/dio.dart';
import 'package:flutter_app/data/database/app_database.dart' as db;
import 'package:flutter_app/data/daos/sync_queue_dao.dart';
import 'package:flutter_app/data/api/api_client.dart';
import 'package:flutter_app/data/api/sync_api.dart';
import 'package:flutter_app/data/sync/sync_pusher.dart';

class _MockAdapter implements HttpClientAdapter {
  final handlers = <String, Function(RequestOptions)>{};
  void on(String method, String path, Function(RequestOptions) h) {
    handlers['$method $path'] = h;
  }
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? rs, Future? cf) async {
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

    test('single batch success', () async {
      adapter.on('POST', '/sync/push/', (_) => ResponseBody.fromString(
        '{"code":0,"data":{"server_ids":{"1":101,"2":102}}}', 200,
        headers: {'content-type': ['application/json']},
      ));
      await dao.enqueue(entityType: 'submission', operationType: 'create', entityId: 1, payload: '{}');
      await dao.enqueue(entityType: 'rating', operationType: 'create', entityId: 2, payload: '{}');
      final pusher = SyncPusher(dao, SyncApi(client));
      final result = await pusher.pushAll();
      expect(result.successCount, 2);
      expect(result.failCount, 0);
      expect(await dao.isEmpty(), isTrue);
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

    test('permanent failure after max retries', () async {
      adapter.on('POST', '/sync/push/', (_) => throw DioException(
        requestOptions: RequestOptions(path: '/sync/push/'),
      ));
      for (var i = 0; i < 7; i++) {
        await dao.enqueue(entityType: 'submission', operationType: 'create', entityId: i, payload: '{}');
      }
      final pusher = SyncPusher(dao, SyncApi(client));
      await pusher.pushAll();
      expect(await dao.hasFailed(), isTrue);
    });
  });
}
