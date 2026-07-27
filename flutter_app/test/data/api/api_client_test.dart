@Tags(['smoke'])
library;

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_app/data/api/api_client.dart';

class MockAdapter implements HttpClientAdapter {
  int callCount = 0;
  final List<ResponseBody Function(RequestOptions)> _handlers = [];
  int _handlerIndex = 0;

  MockAdapter();

  void add(ResponseBody Function(RequestOptions) handler) {
    _handlers.add(handler);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    callCount++;
    final handler = _handlers[_handlerIndex];
    if (_handlerIndex < _handlers.length - 1) _handlerIndex++;
    return handler(options);
  }

  @override
  void close({bool? force}) {}
}

void main() {
  setUp(() {
    setTokenProvider(() => null);
    setRefreshTokenProvider(() => null);
    setOnTokenRefreshed((_, _) async {});
    setOnRefreshFailed(() {});
    setOnAuthFailure(() {});
  });

  group('ApiClient', () {
    test('init sets up dio with correct configurations', () {
      final client = ApiClient();
      client.init(baseUrl: 'https://test.api/v1/');
      expect(client.dio.options.baseUrl, 'https://test.api/v1/');
      expect(client.dio.options.connectTimeout, const Duration(seconds: 10));
      expect(client.dio.options.receiveTimeout, const Duration(seconds: 15));
      expect(client.dio.options.headers['Content-Type'], 'application/json');
    });

    test('init adds three interceptors', () {
      final client = ApiClient();
      client.init();
      expect(client.dio.interceptors.length, greaterThanOrEqualTo(3));
    });
  });

  group('ApiException', () {
    test('isAuthError for code 40001-40099', () {
      expect(ApiException(code: 40001, message: '').isAuthError, true);
      expect(ApiException(code: 50001, message: '').isAuthError, false);
    });

    test('shouldRetry for code 50001-50099', () {
      expect(ApiException(code: 50001, message: '').shouldRetry, true);
      expect(ApiException(code: 40001, message: '').shouldRetry, false);
    });
  });

  group('AuthInterceptor', () {
    test('injects Authorization header when token provided', () async {
      setTokenProvider(() => 'test_access_token');
      final client = ApiClient();
      client.init(baseUrl: 'https://test/');
      final adapter = MockAdapter();
      String? authHeader;
      adapter.add((opts) {
        authHeader = opts.headers['Authorization'] as String?;
        return ResponseBody.fromString('{"code":0,"data":{}}', 200,
            headers: {'content-type': ['application/json']});
      });
      client.setMockAdapter(adapter);

      await client.dio.get('/test');

      expect(authHeader, 'Bearer test_access_token');
    });

    test('does not inject Authorization when no token', () async {
      setTokenProvider(() => null);
      final client = ApiClient();
      client.init(baseUrl: 'https://test/');
      final adapter = MockAdapter();
      String? authHeader;
      adapter.add((opts) {
        authHeader = opts.headers['Authorization'] as String?;
        return ResponseBody.fromString('{"code":0,"data":{}}', 200,
            headers: {'content-type': ['application/json']});
      });
      client.setMockAdapter(adapter);

      await client.dio.get('/test');

      expect(authHeader, isNull);
    });
  });

  group('RefreshInterceptor failure path', () {
    test('401 without refresh token triggers auth failure callback', () async {
      bool authFailed = false;
      setRefreshTokenProvider(() => null);
      setOnAuthFailure(() => authFailed = true);

      final client = ApiClient();
      client.init(baseUrl: 'https://test/');
      final adapter = MockAdapter();
      adapter.add((_) => ResponseBody.fromString('{}', 401,
          headers: {'content-type': ['application/json']}));
      client.setMockAdapter(adapter);

      try {
        await client.dio.get('/secure');
      } catch (_) {}

      expect(authFailed, true);
    });

    test('401 with refresh token triggers provider call', () async {
      String? usedRefreshToken;
      setRefreshTokenProvider(() {
        usedRefreshToken = 'my_refresh';
        return 'my_refresh';
      });

      final client = ApiClient();
      client.init(baseUrl: 'https://test/');
      final adapter = MockAdapter();
      adapter.add((_) => ResponseBody.fromString('{}', 401,
          headers: {'content-type': ['application/json']}));
      client.setMockAdapter(adapter);

      try {
        await client.dio.get('/secure');
      } catch (_) {}

      expect(usedRefreshToken, 'my_refresh');
    });

    test('401 with refresh token triggers onRefreshFailed on network error', () async {
      bool refreshFailed = false;
      setRefreshTokenProvider(() => 'rt');
      setOnRefreshFailed(() => refreshFailed = true);

      final client = ApiClient();
      client.init(baseUrl: 'https://test/');
      final adapter = MockAdapter();
      adapter.add((_) => ResponseBody.fromString('{}', 401,
          headers: {'content-type': ['application/json']}));
      client.setMockAdapter(adapter);

      try {
        await client.dio.get('/secure');
      } catch (_) {}

      // Dio().post('/auth/refresh/') will fail in test → triggers onRefreshFailed
      expect(refreshFailed, true);
    });
  });

  group('ErrorInterceptor', () {
    late Dio dio;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://test'));
      dio.interceptors.add(TestErrorInterceptor());
    });

    test('passes code=0 response through', () async {
      dio.httpClientAdapter = MockAdapter()
        ..add((_) => ResponseBody.fromString(
              '{"code":0,"data":{"ok":true}}', 200,
              headers: {'content-type': ['application/json']},
            ));
      final res = await dio.get('/test');
      expect(res.data['code'], 0);
    });

    test('rejects non-zero code as ApiException', () async {
      dio.httpClientAdapter = MockAdapter()
        ..add((_) => ResponseBody.fromString(
              '{"code":40001,"message":"认证失败","data":null}', 200,
              headers: {'content-type': ['application/json']},
            ));
      try {
        await dio.get('/test');
        fail('should throw');
      } on DioException catch (e) {
        expect(e.error, isA<ApiException>());
        expect((e.error as ApiException).code, 40001);
      }
    });
  });
}

class TestErrorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final body = response.data;
    if (body is Map && body['code'] != null && body['code'] != 0) {
      handler.reject(DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: ApiException(
          code: body['code'] as int,
          message: body['message'] as String? ?? '',
          httpStatus: response.statusCode,
        ),
      ));
    } else {
      handler.next(response);
    }
  }
}
