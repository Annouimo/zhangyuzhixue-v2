import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared/constants/app_version.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

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
typedef OnTokenRefreshed = Future<void> Function(String newAccess, String? newRefresh);
typedef OnRefreshFailed = void Function();
typedef OnAuthFailure = void Function();

TokenProvider _tokenProvider = () => null;
void setTokenProvider(TokenProvider p) => _tokenProvider = p;

RefreshTokenProvider _refreshTokenProvider = () => null;
void setRefreshTokenProvider(RefreshTokenProvider p) => _refreshTokenProvider = p;

OnTokenRefreshed _onTokenRefreshed = (_, __) async {};
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

  void init({String baseUrl = appBaseUrl}) {
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
      _NetworkLogInterceptor(),
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
      options.headers['Authorization'] = 'Bearer $token';
      // debugPrint('[Hermes] ➡️ ${options.method} ${options.path} — Auth: Bearer ${token.length > 20 ? "${token.substring(0, 20)}..." : token}');
    } else {
      // debugPrint('[Hermes] ➡️ ${options.method} ${options.path} — NO token');
    }
    AuditLogger.instance.apiRequest(options.method, options.path, options.data);
    handler.next(options);
  }
}

/// 401 时自动刷新 token（失败跳登录）
class _RefreshInterceptor extends Interceptor {
  bool _refreshing = false;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      AuditLogger.instance.apiResponse(
        err.requestOptions.path,
        err.response?.statusCode ?? 0,
        err,
      );
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
        final response = await ApiClient().dio.post(
          '/auth/refresh/',
          data: {'refresh': refreshToken},
        );
        final newAccess = response.data['data']['access'] as String;
        final newRefresh = response.data['data']['refresh'] as String?;
        await _onTokenRefreshed.call(newAccess, newRefresh);
        _refreshing = false;

        final retryOpts = err.requestOptions;
        retryOpts.headers['Authorization'] = 'Bearer $newAccess';
        final retryRes = await ApiClient().dio.fetch(retryOpts);
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
      AuditLogger.instance.apiResponse(
        response.requestOptions.path,
        response.statusCode ?? 200,
        ApiException(code: body['code'] as int, message: body['message'] as String? ?? '', httpStatus: response.statusCode),
      );
      OperationLog.instance.api(response.requestOptions.method,
          response.requestOptions.path, response.statusCode ?? 200,
          '业务错误: code=${body['code']}');
      handler.reject(DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: body['message'] as String? ?? '业务错误',
        error: ApiException(
          code: body['code'] as int,
          message: body['message'] as String? ?? '未知错误',
          httpStatus: response.statusCode,
        ),
      ));
    } else {
      // 成功响应也记录审计
      AuditLogger.instance.api(
        response.requestOptions.path,
        response.statusCode ?? 200,
        body is Map ? {'code': body['code'], 'success': true} : null,
      );
      OperationLog.instance.api(response.requestOptions.method,
          response.requestOptions.path, response.statusCode ?? 200);
      handler.next(response);
    }
  }
}

/// 记录网络层异常的日志拦截器
class _NetworkLogInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String serverMsg = "";
    if (err.response?.data is Map) {
      final m = (err.response!.data as Map)["message"];
      if (m is String && m.isNotEmpty) serverMsg = " | $m" ;
    }
    OperationLog.instance.api(
      err.requestOptions.method,
      err.requestOptions.path,
      err.response?.statusCode ?? 0,
      "${err.type.name} ${err.message ?? ""}$serverMsg",
    );
    handler.next(err);
  }
}
