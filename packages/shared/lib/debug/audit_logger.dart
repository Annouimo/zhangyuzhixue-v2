import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 审计日志 — 跨端调试追踪
///
/// 写入到应用支持目录下的 audit.log。
/// 每行一条 JSON，包含时间戳、类别、信息。
class AuditLogger {
  AuditLogger._internal();
  static AuditLogger? _instance;
  static AuditLogger get instance {
    _instance ??= AuditLogger._internal();
    return _instance!;
  }

  File? _logFile;
  IOSink? _sink;

  /// 初始化。可传入 Directory（学生端用法），也可不传自动获取（教师端用法）。
  Future<void> init([Directory? dir]) async {
    dir ??= await getApplicationSupportDirectory();
    final f = File('${dir.path}/audit.log');
    _logFile = f;
    _sink = f.openWrite(mode: FileMode.append);
  }

  void _write(String category, Object? info, {Map<String, dynamic>? extra}) {
    final entry = {
      'ts': DateTime.now().toIso8601String(),
      'cat': category,
      'info': info?.toString(),
      if (extra != null) ...extra,
    };
    _sink?.writeln(jsonEncode(entry));
  }

  void dao(String daoName, int count, Map<String, dynamic>? extra) {
    _write('dao', '$daoName → $count 条', extra: extra);
  }

  void prefs(String key, Object? value) {
    _write('prefs', '$key = $value');
  }

  void api(String endpoint, int statusCode, {Map<String, dynamic>? extra}) {
    _write('api', '$endpoint → $statusCode', extra: extra);
  }

  void apiRequest(String method, String path, [dynamic data]) {
    _write('api_request', '$method $path',
        extra: data is Map ? Map<String, dynamic>.from(data as Map) : null);
  }

  void apiResponse(String method, String path, int statusCode, [dynamic data]) {
    _write('api_response', '$method $path → $statusCode',
        extra: data is Map ? Map<String, dynamic>.from(data as Map) : null);
  }

  void page(String route, [Map<String, dynamic>? extra]) {
    _write('page', route, extra: extra);
  }

  void error(String category, Object? message, [Object? details]) {
    _write('error', message, extra: {
      'category': category,
      if (details != null) 'details': details.toString(),
    });
  }

  void info(String category, String message, {Map<String, dynamic>? extra}) {
    _write(category, message, extra: extra);
  }

  void sync(String action, String detail) {
    _write('sync', '$action: $detail');
  }

  void custom(String category, String message, {Map<String, dynamic>? extra}) {
    _write(category, message, extra: extra);
  }

  void close() {
    _sink?.close();
    _sink = null;
  }
}
