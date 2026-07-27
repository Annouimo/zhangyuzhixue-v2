import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_app/data/api/api_client.dart';
import 'package:flutter_app/domain/auth_repository.dart';
import 'package:flutter_app/data/api/auth_api.dart';

class _MockAdapter implements HttpClientAdapter {
  final handlers = <String, Function(RequestOptions)>{};
  void on(String method, String path, Function(RequestOptions) h) {
    handlers['$method $path'] = h;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? rs,
    Future? cf,
  ) async {
    final h = handlers['${o.method} ${o.path}'];
    if (h != null) return h(o);
    return ResponseBody.fromString(
      '{"code":0,"data":{}}',
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
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

  group('AuthRepository', () {
    test('login returns LoginResult', () async {
      adapter.on(
        'POST',
        '/auth/login/',
        (_) => ResponseBody.fromString(
          '{"code":0,"data":{"access":"acc1","refresh":"ref1","user":{"id":1,"name":"stu","role":"student"}}}',
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );
      final repo = AuthRepository(AuthApi(client));
      final r = await repo.login(
        LoginRequest(username: 's1', password: 'p', appType: 'student'),
      );
      expect(r.accessToken, 'acc1');
      expect(r.refreshToken, 'ref1');
      expect(r.user['name'], 'stu');
    });

    test('register succeeds', () async {
      adapter.on(
        'POST',
        '/auth/register/',
        (_) => ResponseBody.fromString(
          '{"code":0,"data":null}',
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );
      final repo = AuthRepository(AuthApi(client));
      await repo.register(
        RegisterRequest(
          inviteCode: 'X',
          username: 'u',
          realName: 'n',
          phone: '138',
          gaokaoYear: '2026',
          password: 'p',
          acceptedTerms: true,
          acceptedPrivacy: true,
        ),
      );
    });

    test('refresh returns new token', () async {
      adapter.on(
        'POST',
        '/auth/refresh/',
        (_) => ResponseBody.fromString(
          '{"code":0,"data":{"access":"new_acc"}}',
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );
      final repo = AuthRepository(AuthApi(client));
      final r = await repo.refresh('old');
      expect(r.accessToken, 'new_acc');
    });

    test('logout succeeds', () async {
      adapter.on(
        'POST',
        '/auth/logout/',
        (_) => ResponseBody.fromString(
          '{"code":0,"data":null}',
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );
      final repo = AuthRepository(AuthApi(client));
      await repo.logout();
    });
  });
}
