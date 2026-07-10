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

/// HTTP 客户端单例，管理 Dio 连接池和拦截器链
class ApiClient {
  ApiClient._internal();
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  Dio? _dio;

  void init({String baseUrl = 'https://zhangyuzhixue.top/api/v1/'}) {
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
  }

  Dio get dio => _dio!;

  @visibleForTesting
  void setMockAdapter(HttpClientAdapter adapter) {
    _dio!.httpClientAdapter = adapter;
  }
}

// ═══════════════════════════════════════════════
// 拦截器
// ═══════════════════════════════════════════════

/// 请求前附加 Authorization header
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ' + token;
    }
    handler.next(options);
  }
}

typedef TokenProvider = String? Function();
TokenProvider? _tokenProvider;
void setTokenProvider(TokenProvider provider) {
  _tokenProvider = provider;
}

/// 401 时自动刷新 token
class _RefreshInterceptor extends Interceptor {
  bool _isRefreshing = false;
  final _pendingRequests = <_PendingRequest>[];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    if (_isRefreshing) {
      _pendingRequests.add(_PendingRequest(
        options: err.requestOptions,
        handler: handler,
      ));
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = _refreshTokenProvider?.call();
      if (refreshToken == null || refreshToken.isEmpty) {
        _redirectToLogin();
        return handler.resolve(err.response!);
      }

      final response = await Dio().post(
        err.requestOptions.baseUrl + '/auth/refresh/',
        data: {'refresh': refreshToken},
      );

      final newAccess = response.data['access'] as String;
      await _onTokenRefreshed?.call(newAccess);

      err.requestOptions.headers['Authorization'] = 'Bearer ' + newAccess;
      final retryResponse = await Dio().fetch(err.requestOptions);
      handler.resolve(retryResponse);

      _processPending(newAccess);
    } catch (e) {
      _onRefreshFailed?.call();
      _redirectToLogin();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  void _processPending(String newToken) {
    final pending = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();
    for (final p in pending) {
      p.options.headers['Authorization'] = 'Bearer ' + newToken;
      Dio().fetch(p.options).then((r) => p.handler.resolve(r));
    }
  }

  void _redirectToLogin() {
    _onAuthFailure?.call();
  }
}

class _PendingRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;
  const _PendingRequest({required this.options, required this.handler});
}

typedef RefreshTokenProvider = String? Function();
typedef OnTokenRefreshed = Future<void> Function(String newAccess);
typedef OnRefreshFailed = void Function();
typedef OnAuthFailure = void Function();

RefreshTokenProvider? _refreshTokenProvider;
OnTokenRefreshed? _onTokenRefreshed;
OnRefreshFailed? _onRefreshFailed;
OnAuthFailure? _onAuthFailure;

void setRefreshTokenProvider(RefreshTokenProvider p) => _refreshTokenProvider = p;
void setOnTokenRefreshed(OnTokenRefreshed cb) => _onTokenRefreshed = cb;
void setOnRefreshFailed(OnRefreshFailed cb) => _onRefreshFailed = cb;
void setOnAuthFailure(OnAuthFailure cb) => _onAuthFailure = cb;

/// 统一解析 {code, message, data} 格式
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
