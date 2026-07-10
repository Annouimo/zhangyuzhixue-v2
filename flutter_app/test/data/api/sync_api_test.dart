import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import '../../../lib/data/api/sync_api.dart';
import '../../../lib/data/api/api_client.dart';

class MockAdapter implements HttpClientAdapter {
  int callCount = 0;
  List<Map<String, dynamic>>? sentBatch;
  String? lastUrl;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    callCount++;
    lastUrl = options.path;
    if (options.data is Map) {
      sentBatch = (options.data as Map)['batch'] as List<Map<String, dynamic>>?;
    }
    if (options.path.contains('version')) {
      return ResponseBody.fromString(
        '{"code":0,"data":{"schema_version":1,"data_version":5,"force_update":false}}', 200,
        headers: {'content-type': ['application/json']},
      );
    }
    return ResponseBody.fromString(
      '{"code":0,"data":{"server_ids":{"1":101,"2":102}}}', 200,
      headers: {'content-type': ['application/json']},
    );
  }

  @override
  void close({bool? force}) {}
}

void main() {
  group('SyncApi', () {
    test('checkVersion parses response', () async {
      final client = ApiClient();
      client.init(baseUrl: 'https://test/');
      client.setMockAdapter(MockAdapter());

      final status = await SyncApi(client).checkVersion('qbank');

      expect(status.schemaVersion, 1);
      expect(status.dataVersion, 5);
      expect(status.forceUpdate, false);
    });

    test('pushBatch sends batch and returns serverIds', () async {
      final client = ApiClient();
      client.init(baseUrl: 'https://test/');
      final adapter = MockAdapter();
      client.setMockAdapter(adapter);

      final api = SyncApi(client);
      final result = await api.pushBatch([
        {'entity_type': 'rating', 'local_id': 1, 'payload': {'score': 5}},
        {'entity_type': 'rating', 'local_id': 2, 'payload': {'score': 3}},
      ]);

      expect(result.serverIds, {1: 101, 2: 102});
      expect(adapter.sentBatch!.length, 2);
    });
  });
}
