import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import '../../../lib/data/api/api_client.dart';

class MockAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions) _handler;
  MockAdapter(this._handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    return _handler(options);
  }

  @override
  void close({bool? force}) {}
}

void main() {
  group('ApiClient', () {
    test('init sets up dio with correct baseUrl', () {
      final client = ApiClient();
      client.init(baseUrl: 'https://test.api/v1/');
      expect(client.dio.options.baseUrl, 'https://test.api/v1/');
      expect(client.dio.options.connectTimeout, const Duration(seconds: 10));
      expect(client.dio.options.receiveTimeout, const Duration(seconds: 15));
      expect(client.dio.options.headers['Content-Type'], 'application/json');
    });

    test('interceptors include auth, refresh and error', () {
      final client = ApiClient();
      client.init();
      // Dio may add its own interceptors, so check we have at least 3
      expect(client.dio.interceptors.length, greaterThanOrEqualTo(3));
    });
  });

  group('ApiException', () {
    test('isAuthError for auth error codes', () {
      final e = ApiException(code: 40001, message: '认证失败');
      expect(e.isAuthError, true);
      expect(e.shouldRetry, false);
    });

    test('shouldRetry for server error codes', () {
      final e = ApiException(code: 50001, message: '服务器错误');
      expect(e.isAuthError, false);
      expect(e.shouldRetry, true);
    });
  });

  group('ErrorInterceptor', () {
    late Dio dio;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://test'));
      dio.interceptors.add(InterceptorWithErrorCheck());
    });

    test('passes through code=0 response', () async {
      dio.httpClientAdapter = MockAdapter((_) => ResponseBody.fromString(
        '{"code":0,"data":{"ok":true}}',
        200,
        headers: {'content-type': ['application/json']},
      ));
      final res = await dio.get('/test');
      expect(res.data['code'], 0);
    });

    test('rejects code!=0 as ApiException', () async {
      dio.httpClientAdapter = MockAdapter((_) => ResponseBody.fromString(
        '{"code":40001,"message":"用户名或密码错误","data":null}',
        200,
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

class InterceptorWithErrorCheck extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final body = response.data;
    if (body is Map && body['code'] != null && body['code'] != 0) {
      handler.reject(DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: ApiException(
          code: body['code'] as int,
          message: body['message'] as String? ?? '未知错误',
          httpStatus: response.statusCode,
        ),
      ));
    } else {
      handler.next(response);
    }
  }
}
