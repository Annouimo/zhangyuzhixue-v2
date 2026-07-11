import 'dart:convert';
import 'dart:io';

/// 运行时审计日志 — 仅在 --dart-define=AUDIT_MODE=true 时生效
///
/// 用法:
///   flutter run --dart-define=AUDIT_MODE=true
///
/// Release 构建中 tree-shaking 消除所有调用，零影响。
const _auditEnabled = bool.fromEnvironment('AUDIT_MODE', defaultValue: false);

/// 审计日志文件路径
/// Windows: %TEMP%/zhangyuzhixue_audit.ndjson
/// macOS/Linux: $TMPDIR/zhangyuzhixue_audit.ndjson
String get _auditLogPath {
  final tmp = Platform.environment['TEMP'] ??
      Platform.environment['TMPDIR'] ??
      '/tmp';
  return '$tmp${Platform.pathSeparator}zhangyuzhixue_audit.ndjson';
}

/// 运行时审计日志器。
///
/// 每条日志是一条 NDJSON 行（JSON 对象，以 \n 分隔）。
/// Python 审计引擎逐行读取，json.loads 解析后做断言。
class AuditLogger {
  AuditLogger._();
  static final AuditLogger instance = AuditLogger._();

  int _seq = 0;
  IOSink? _sink;
  bool get enabled => _auditEnabled;

  /// 初始化审计日志文件（追加模式）
  Future<void> init() async {
    if (!_auditEnabled) return;
    final file = File(_auditLogPath);
    // 每次启动覆盖旧文件
    _sink = file.openWrite(mode: FileMode.writeOnly);
    _write('_meta', '_session', 'startedAt', DateTime.now().toIso8601String());
  }

  void _write(String category, String source, String key, Object? value) {
    if (_sink == null) return;
    _seq++;
    final entry = {
      'seq': _seq,
      'ts': DateTime.now().toIso8601String(),
      'cat': category,
      'src': source,
      'key': key,
      'val': value?.toString() ?? '',
      'vt': value == null ? 'null' : _typeTag(value.runtimeType),
    };
    _sink!.writeln(jsonEncode(entry));
  }

  /// 页面层：页面数据加载完成后调用
  void page(String pageName, Map<String, Object?> fields) {
    if (!_auditEnabled) return;
    for (final e in fields.entries) {
      _write('page', pageName, e.key, e.value);
    }
  }

  /// DAO/Repository 层：每次查询后调用
  void dao(String method, int rowCount, [Map<String, Object?>? params]) {
    if (!_auditEnabled) return;
    _write('dao', method, 'rowCount', rowCount);
    if (params != null && params.isNotEmpty) {
      _write('dao', method, 'params', jsonEncode(params));
    }
  }

  /// SharedPreferences 层：每次 getter 读取后调用
  void prefs(String key, Object? value) {
    if (!_auditEnabled) return;
    _write('prefs', 'AppPrefs', key, value);
  }

  /// 同步引擎层：同步操作后调用
  void sync(String op, Map<String, Object?> data) {
    if (!_auditEnabled) return;
    _write('sync', op, 'data', jsonEncode(data));
  }

  /// API 响应层：网络请求后调用
  void api(String endpoint, int statusCode, Map<String, Object?>? summary) {
    if (!_auditEnabled) return;
    _write('api', endpoint, 'statusCode', statusCode);
    if (summary != null && summary.isNotEmpty) {
      _write('api', endpoint, 'summary', jsonEncode(summary));
    }
  }

  /// 运行时错误：try/catch 捕获的异常
  void error(String source, Object error, [StackTrace? stack]) {
    if (!_auditEnabled) return;
    _write('error', source, 'message', error.toString());
    if (stack != null) {
      // 只取前 3 行避免日志膨胀
      final lines = stack.toString().split('\n');
      _write('error', source, 'stack', lines.take(3).join('\n'));
    }
  }

  /// API 响应错误快捷方法
  void apiResponse(String endpoint, int statusCode, Object? error) {
    if (!_auditEnabled) return;
    _write('api', endpoint, 'statusCode', statusCode);
    if (error != null) {
      _write('api', endpoint, 'error', error.toString());
    }
  }

  /// 关闭日志文件
  Future<void> close() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }

  static String _typeTag(Type t) {
    if (t == int) return 'int';
    if (t == double) return 'double';
    if (t == String) return 'str';
    if (t == bool) return 'bool';
    return t.toString();
  }
}
