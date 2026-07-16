import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 运行日志（飞行记录器）— release 构建下正常工作
///
/// 写入到应用支持目录下的 operation.log，用于诊断用户环境问题。
/// 每行一条 JSON，按时间戳排序（追加写入）。
/// 最多保留 5000 条，超出时清理最早的一半。
class OperationLog {
  OperationLog._internal();
  static OperationLog? _instance;
  static OperationLog get instance {
    _instance ??= OperationLog._internal();
    return _instance!;
  }

  File? _logFile;
  List<Map<String, dynamic>> _buffer = [];
  bool _ready = false;

  static const int _maxEntries = 5000;

  String? get logFilePath => _logFile?.path;

  Future<void> init() async {
    if (_ready) return;
    final dir = await getApplicationSupportDirectory();
    _logFile = File('${dir.path}/operation.log');
    await _load();
    _ready = true;
  }

  Future<void> _load() async {
    if (!await _logFile!.exists()) return;
    try {
      final lines = await _logFile!.readAsLines();
      _buffer = lines
          .map((line) {
            try {
              return jsonDecode(line) as Map<String, dynamic>;
            } catch (_) {
              return null;
            }
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (_) {}
  }

  Future<void> log(String category, String action,
      {Map<String, dynamic>? detail}) async {
    final entry = {
      'ts': DateTime.now().toIso8601String(),
      'cat': category,
      'action': action,
      if (detail != null) 'detail': detail,
    };
    _buffer.add(entry);

    if (_buffer.length > _maxEntries) {
      _buffer = _buffer.sublist(_buffer.length ~/ 2);
    }

    if (_ready) {
      try {
        await _logFile!.writeAsString(
          _buffer.map((e) => jsonEncode(e)).join('\n') + '\n',
        );
      } catch (_) {}
    }
  }

  Future<void> error(String category, Object message, [Object? details]) async {
    await log('error', message.toString(), detail: {
      'category': category,
      if (details != null) 'details': details.toString(),
    });
  }

  Future<void> action(String actionName, [String? detail]) async {
    await log('action', actionName,
        detail: detail != null ? {'detail': detail} : null);
  }

  Future<void> api(String method, String url, int statusCode) async {
    await log('api', '$method $url', detail: {'statusCode': statusCode});
  }

  Future<void> navigation(String route, [String? action]) async {
    await log('navigation', route,
        detail: action != null ? {'action': action} : null);
  }

  List<Map<String, dynamic>> get recent => List.unmodifiable(
      _buffer.length > 100 ? _buffer.sublist(_buffer.length - 100) : _buffer);

  List<Map<String, dynamic>> query({
    String? category,
    int limit = 50,
  }) {
    var result = _buffer.reversed;
    if (category != null) {
      result = result.where((e) => e['cat'] == category);
    }
    return result.take(limit).toList();
  }
}
