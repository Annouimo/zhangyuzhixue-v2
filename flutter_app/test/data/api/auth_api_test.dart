import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_app/data/api/auth_api.dart';
import 'package:flutter_app/data/api/api_client.dart';

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

  group('AuthApi', () {
    test('login sends correct request and parses response', () async {
      adapter.on('POST', '/auth/login/', (_) {
        return ResponseBody.fromString(
          '{"code":0,"data":{"access":"acc123","refresh":"ref456","user":{"id":1,"name":"test","role":"student"}}}',
          200,
          headers: {'content-type': ['application/json']},
        );
      });

      final api = AuthApi(client);
      final result = await api.login(LoginRequest(
        username: 'test', password: 'pass', appType: 'student',
      ));

      expect(result.accessToken, 'acc123');
      expect(result.refreshToken, 'ref456');
      expect(result.user['name'], 'test');
    });

    test('register sends correct request', () async {
      var requestBody = <String, dynamic>{};
      adapter.on('POST', '/auth/register/', (opts) {
        requestBody = opts.data as Map<String, dynamic>;
        return ResponseBody.fromString('{"code":0,"data":null}', 200,
            headers: {'content-type': ['application/json']});
      });

      final api = AuthApi(client);
      await api.register(RegisterRequest(
        inviteCode: 'ABC123',
        username: 'newuser',
        realName: '小明',
        phone: '13800138000',
        gaokaoYear: '2026',
        password: 'pass123',
      ));

      expect(requestBody['invitation_code'], 'ABC123');
      expect(requestBody['username'], 'newuser');
    });

    test('refresh returns new access token', () async {
      adapter.on('POST', '/auth/refresh/', (_) {
        return ResponseBody.fromString(
          '{"code":0,"data":{"access":"new_acc_789"}}', 200,
          headers: {'content-type': ['application/json']},
        );
      });

      final api = AuthApi(client);
      final result = await api.refresh('old_refresh');
      expect(result.accessToken, 'new_acc_789');
    });
  });
}
