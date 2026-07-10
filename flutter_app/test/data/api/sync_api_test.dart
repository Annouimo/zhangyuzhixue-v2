import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import '../../../lib/data/api/sync_api.dart';
import '../../../lib/data/api/api_client.dart';

class _MockAdapter implements HttpClientAdapter {
  final Map<String, Function(RequestOptions)> handlers = {};

  void on(String method, String path, Function(RequestOptions) handler) {
    handlers[method + ' ' + path] = handler;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    final key = options.method + ' ' + options.path;
    final handler = handlers[key];
    if (handler != null) {
      return handler(options);
    }
    return ResponseBody.fromString('{"code":0,"data":{}}', 200,
        headers: {'content-type': ['application/json']});
  }

  @override
  void close({bool? force}) {}
}

void main() {
  late ApiClient client;
  late _MockAdapter adapter;

  setUp(() {
    client = ApiClient();
    client.init(baseUrl: 'https://test/');
    adapter = _MockAdapter();
    client.setMockAdapter(adapter);
  });

  group('SyncApi', () {
    test('checkVersion qbank', () async {
      adapter.on('GET', '/sync/qbank/version/', (_) {
        return ResponseBody.fromString(
          '{"code":0,"data":{"schema_version":1,"data_version":3,"force_update":false,"download_url":"/media/db/qbank_v3.db.gz","checksum":"abc123","size_bytes":500000}}',
          200,
          headers: {'content-type': ['application/json']},
        );
      });

      final api = SyncApi(client);
      final result = await api.checkVersion('qbank');
      expect(result.schemaVersion, 1);
      expect(result.dataVersion, 3);
      expect(result.forceUpdate, false);
      expect(result.downloadUrl, '/media/db/qbank_v3.db.gz');
    });

    test('checkVersion lecture', () async {
      adapter.on('GET', '/sync/lecture/version/', (_) {
        return ResponseBody.fromString(
          '{"code":0,"data":{"schema_version":1,"data_version":2,"force_update":true,"message":"更新了内容"}}',
          200,
          headers: {'content-type': ['application/json']},
        );
      });

      final api = SyncApi(client);
      final result = await api.checkVersion('lecture');
      expect(result.dataVersion, 2);
      expect(result.forceUpdate, true);
      expect(result.message, '更新了内容');
    });

    test('pushBatch sends batch data', () async {
      List<dynamic>? sentBatch;
      adapter.on('POST', '/sync/push/', (opts) {
        sentBatch = (opts.data as Map)['batch'] as List<dynamic>;
        return ResponseBody.fromString(
          '{"code":0,"data":{"success_count":2,"fail_count":0}}', 200,
          headers: {'content-type': ['application/json']},
        );
      });

      final api = SyncApi(client);
      final result = await api.pushBatch([
        {'entity_type': 'rating', 'local_id': 1, 'payload': {'score': 5}},
        {'entity_type': 'rating', 'local_id': 2, 'payload': {'score': 3}},
      ]);

      expect(result.successCount, 2);
      expect(result.failCount, 0);
      expect(sentBatch!.length, 2);
    });
  });
}
