import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

/// API 异常
class ApiException implements Exception {
  final int code;
  final String message;
  final int? httpStatus;

  const ApiException({
    required this.code,
    required this.message,
    this.httpStatus,
  });

  bool get isAuthError => code >= 40001 && code <= 40099;
  bool get shouldRetry => code >= 50001 && code <= 50099;

  @override
  String toString() => 'ApiException($code): $message';
}

// ── 全局状态（拦截器回调）──

typedef TokenProvider = String? Function();
typedef RefreshTokenProvider = String? Function();
typedef OnTokenRefreshed = Future<void> Function(String newAccess);
typedef OnRefreshFailed = void Function();
typedef OnAuthFailure = void Function();

TokenProvider _tokenProvider = () => null;
void setTokenProvider(TokenProvider p) => _tokenProvider = p;

RefreshTokenProvider _refreshTokenProvider = () => null;
void setRefreshTokenProvider(RefreshTokenProvider p) => _refreshTokenProvider = p;

OnTokenRefreshed _onTokenRefreshed = (_) async {};
void setOnTokenRefreshed(OnTokenRefreshed cb) => _onTokenRefreshed = cb;

OnRefreshFailed _onRefreshFailed = () {};
void setOnRefreshFailed(OnRefreshFailed cb) => _onRefreshFailed = cb;

OnAuthFailure _onAuthFailure = () {};
void setOnAuthFailure(OnAuthFailure cb) => _onAuthFailure = cb;

// ═══════════════════════════════════════════════
// HTTP 客户端单例
// ═══════════════════════════════════════════════

/// 管理 Dio 连接池和拦截器链
class ApiClient {
  ApiClient._internal();
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  Dio? _dio;
  bool _initialized = false;

  void init({String baseUrl = 'https://zhangyuzhixue.top/api/v1'}) {
    if (_initialized) return;
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio!.interceptors.addAll([
      _AuthInterceptor(),
      _RefreshInterceptor(),
      _ErrorInterceptor(),
    ]);
    _initialized = true;
  }

  Dio get dio {
    if (_dio == null) {
      throw StateError('ApiClient not initialized. Call init() first.');
    }
    return _dio!;
  }

  @visibleForTesting
  void setMockAdapter(HttpClientAdapter adapter) {
    dio.httpClientAdapter = adapter;
  }
}

// ═══════════════════════════════════════════════
// 拦截器
// ═══════════════════════════════════════════════

/// 请求前注入 Authorization header
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenProvider.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ${token}';
    }
    handler.next(options);
  }
}

/// 401 时自动刷新 token（失败跳登录）
class _RefreshInterceptor extends Interceptor {
  bool _refreshing = false;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    try {
      final refreshToken = _refreshTokenProvider.call();
      if (refreshToken == null) {
        _onAuthFailure.call();
        return handler.reject(err);
      }

      if (_refreshing) return handler.next(err);
      _refreshing = true;

      try {
        final response = await Dio().post(
          '${err.requestOptions.baseUrl}/auth/refresh/',
          data: {'refresh': refreshToken},
        );
        final newAccess = response.data['data']['access'] as String;
        await _onTokenRefreshed.call(newAccess);
        _refreshing = false;

        final retryOpts = err.requestOptions;
        retryOpts.headers['Authorization'] = 'Bearer ${newAccess}';
        final retryRes = await Dio().fetch(retryOpts);
        handler.resolve(retryRes);
      } catch (_) {
        _refreshing = false;
        _onRefreshFailed.call();
        handler.reject(err);
      }
    } catch (_) {
      handler.reject(err);
    }
  }
}

/// 将业务错误码转为 ApiException
class _ErrorInterceptor extends Interceptor {
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
