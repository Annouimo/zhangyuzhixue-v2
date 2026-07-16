import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 运行日志（飞行记录器）— release 构建下正常工作
///
/// 记录关键操作流水：页面加载、API 请求、用户操作、异常。
/// 内存中滚动保留最近 200 条，同时写入文件。
/// 用户可通过关于页「导出日志」调用系统分享面板发送文件。
class OperationLog {
  OperationLog._();
  static final OperationLog instance = OperationLog._();

  static const int _maxEntries = 200;
  final List<Map<String, dynamic>> _buffer = [];
  int _seq = 0;
  IOSink? _sink;
  bool _ready = false;

  /// 初始化（main.dart 启动时调用）
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}operation_log.ndjson');
    // 保留上次的日志（追加模式），但先读进来裁剪行数
    if (await file.exists()) {
      final lines = await file.readAsLines();
      if (lines.length > _maxEntries) {
        await file.writeAsString('${lines.sublist(lines.length - _maxEntries).join('\n')}\n');
      }
    }
    _sink = file.openWrite(mode: FileMode.append);
    _ready = true;
    _write('_sys', 'init', 'started');
  }

  void _write(String category, String source, String detail) {
    if (!_ready || _sink == null) return;
    _seq++;
    final entry = <String, dynamic>{
      't': DateTime.now().toIso8601String(),
      'seq': _seq,
      'cat': category,
      'src': source,
      'd': detail,
    };
    _buffer.add(entry);
    if (_buffer.length > _maxEntries) {
      _buffer.removeAt(0);
    }
    _sink!.writeln(jsonEncode(entry));
  }

  // ── 公开记录方法 ──

  /// 页面加载
  void page(String pageName, String detail) =>
      _write('page', pageName, detail);

  /// API 请求
  void api(String method, String path, int statusCode, [String? extra]) {
    final detail = '$statusCode${extra != null ? ' $extra' : ''}';
    _write('api', '$method $path', detail);
  }

  /// 用户操作（签到/做题/评分/组卷等）
  void action(String action, String detail) =>
      _write('action', action, detail);

  /// 导航
  void navigation(String route, String detail) =>
      _write('nav', route, detail);

  /// 异常（catch 块调用）
  void error(String source, Object error, [StackTrace? stack]) {
    var detail = error.toString();
    if (stack != null) {
      final lines = stack.toString().split('\n');
      detail += ' | ${lines.take(2).join(' | ')}';
    }
    _write('error', source, detail);
  }

  /// 同步操作
  void sync(String op, String detail) =>
      _write('sync', op, detail);

  // ── 导出 ──

  /// 日志文件路径
  Future<String> get logFilePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}${Platform.pathSeparator}operation_log.ndjson';
  }

  /// 调用系统分享面板导出日志文件
  ///
  /// 返回 true 表示文件存在并尝试打开了分享面板，false 表示无日志或失败。
  /// 使用系统分享面板而非剪贴板，避免第三方剪贴板软件截断长日志。
  Future<bool> exportToShare() async {
    if (!_ready) return false;
    await _sink?.flush();

    final file = File(await logFilePath);
    if (!await file.exists()) return false;

    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'operation_log.ndjson',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 关闭
  Future<void> close() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
    _ready = false;
  }

  /// 获取当前缓冲（调试用）
  List<Map<String, dynamic>> get buffer => List.unmodifiable(_buffer);
}
