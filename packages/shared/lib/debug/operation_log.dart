import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared/debug/audit_logger.dart';

/// 日志导出结果
enum ExportResult {
  /// 分享面板成功打开（移动端）或文件已保存到 Downloads（桌面端）
  success,

  /// OperationLog 未初始化
  notReady,

  /// 日志文件不存在
  fileNotFound,

  /// 系统分享失败（桌面端 share_plus 不可用时的降级——文件已导出到 Downloads，用户手动发送）
  savedToFolder,
}

/// 运行日志（飞行记录器）— release 构建下正常工作
///
/// 记录关键操作流水：页面加载、API 请求、用户操作、异常。
/// 内存中滚动保留最近 200 条，同时写入文件。
/// 用户可通过关于页「导出日志」拿到文件。
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

  void page(String pageName, String detail) =>
      _write('page', pageName, detail);

  void api(String method, String path, int statusCode, [String? extra]) {
    final detail = '$statusCode${extra != null ? ' $extra' : ''}';
    _write('api', '$method $path', detail);
  }

  void action(String action, String detail) =>
      _write('action', action, detail);

  void navigation(String route, String detail) =>
      _write('nav', route, detail);

  void error(String source, Object error, [StackTrace? stack]) {
    var detail = error.toString();
    if (stack != null) {
      final lines = stack.toString().split('\n');
      detail += ' | ${lines.take(2).join(' | ')}';
    }
    _write('error', source, detail);
  }

  void sync(String op, String detail) =>
      _write('sync', op, detail);

  // ── 导出 ──

  /// 日志文件原始路径（app 私有目录）
  Future<String> get logFilePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}${Platform.pathSeparator}operation_log.ndjson';
  }

  /// 导出日志 — 优先系统分享，失败则保存到 Downloads 并打开文件夹
  ///
  /// 移动端：调用系统分享面板直接选择微信/QQ 发送
  /// 桌面端：复制到 Downloads 目录 + 打开文件夹位置，用户手动拖到微信
  Future<ExportResult> exportToShare() async {
    if (!_ready) return ExportResult.notReady;
    await _sink?.flush();

    final src = File(await logFilePath);
    if (!await src.exists()) return ExportResult.fileNotFound;

    // 1. 复制到公共目录（Desktop/Downloads），确保文件可被其他应用访问
    final exportDir = await _exportDirectory();
    final dest = File('${exportDir.path}${Platform.pathSeparator}operation_log_export.ndjson');
    await src.copy(dest.path);

    // 2. 尝试系统分享面板（移动端完美工作）
    try {
      await Share.shareXFiles(
        [XFile(dest.path)],
        subject: 'operation_log.ndjson',
      );
      return ExportResult.success;
    } catch (e) {
      // 3. 分享失败（常见于 Windows），文件已导出到 Downloads
      AuditLogger.instance.error('OperationLog.exportToShare', e);
      _revealInExplorer(dest.path);
      return ExportResult.savedToFolder;
    }
  }

  /// 获取导出目标目录：桌面端→Downloads，移动端→Documents
  Future<Directory> _exportDirectory() async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) return downloads;
    }
    return await getApplicationDocumentsDirectory();
  }

  /// 在文件管理器中定位文件
  void _revealInExplorer(String path) {
    try {
      if (Platform.isWindows) {
        Process.run('explorer', ['/select,', path]);
      } else if (Platform.isMacOS) {
        Process.run('open', ['-R', path]);
      }
    } catch (_) {}
  }

  Future<void> close() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
    _ready = false;
  }

  List<Map<String, dynamic>> get buffer => List.unmodifiable(_buffer);
}
