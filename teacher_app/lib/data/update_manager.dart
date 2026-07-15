import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/database_provider.dart';

/// 版本检查结果
class UpdateSummary {
  final String type;
  final int localVersion;
  final int serverVersion;
  final bool forceUpdate;
  final String? downloadUrl;
  final String? checksum;
  final int? sizeBytes;
  final String? message;

  const UpdateSummary({
    required this.type,
    required this.localVersion,
    required this.serverVersion,
    required this.forceUpdate,
    this.downloadUrl,
    this.checksum,
    this.sizeBytes,
    this.message,
  });
}

/// 更新管理器：版本检查 + .db.gz 下载/校验/替换
/// 与学生端区别：serverUrl 从构造参数传入，不读 AppPrefs；直接调 Dio 而非 SyncApi
class UpdateManager {
  final String _serverUrl;
  final DatabaseProvider _dbProvider;
  final Dio _client;
  final Dio _downloadClient;

  UpdateManager(this._serverUrl, this._dbProvider)
      : _client = Dio(BaseOptions(
          baseUrl: _normalizeBaseUrl(_serverUrl),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        )),
        _downloadClient = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 120),
        ));

  static String _normalizeBaseUrl(String url) {
    if (url.endsWith('/')) return url;
    return '$url/';
  }

  /// 服务器基础 URL
  String get serverUrl => _serverUrl;

  /// 检查 qbank 和 courses 版本
  Future<List<UpdateSummary>> checkAll() async {
    final results = await Future.wait([
      _checkOne('qbank'),
      _checkOne('courses'),
    ]);
    return results;
  }

  Future<UpdateSummary> _checkOne(String type) async {
    final response = await _client.get('api/$type/version/');
    final data = response.data is Map ? response.data as Map : (response.data as Map?)?['data'] as Map? ?? {};

    final serverVersion = (data['data_version'] ?? data['version'] ?? 0) as int;
    final forceUpdate = (data['force_update'] ?? false) as bool;
    final downloadUrl = data['download_url'] as String?;
    final checksum = data['checksum'] as String?;
    final sizeBytes = data['size_bytes'] as int?;
    final message = data['message'] as String?;

    final localVersion = await _getLocalVersion(type);

    return UpdateSummary(
      type: type,
      localVersion: localVersion,
      serverVersion: serverVersion,
      forceUpdate: shouldForceUpdate(
        localVersion: localVersion,
        serverVersion: serverVersion,
        serverForceUpdate: forceUpdate,
      ),
      downloadUrl: downloadUrl,
      checksum: checksum,
      sizeBytes: sizeBytes,
      message: message,
    );
  }

  Future<int> _getLocalVersion(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = type == 'qbank' ? 'qbank_version' : 'courses_version';
    return prefs.getInt(key) ?? 0;
  }

  Future<void> _setLocalVersion(String type, int version) async {
    final prefs = await SharedPreferences.getInstance();
    final key = type == 'qbank' ? 'qbank_version' : 'courses_version';
    await prefs.setInt(key, version);
  }

  /// 下载 .db.gz → 解压 → checksum 校验 → 替换
  Future<void> downloadAndReplace({
    required String type,
    required String url,
    required String expectedChecksum,
    int newVersion = 0,
    void Function(double progress)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final gzPath = '${tempDir.path}/${type}_temp.db.gz';

    await _downloadClient.download(url, gzPath,
        onReceiveProgress: (received, total) {
      if (total > 0 && onProgress != null) onProgress(received / total);
    });

    final gzBytes = await File(gzPath).readAsBytes();
    final digest = sha256.convert(gzBytes);

    if (digest.toString() != expectedChecksum) {
      await File(gzPath).delete();
      throw Exception('Checksum mismatch for $type: expected $expectedChecksum, got ${digest.toString()}');
    }

    final decompressed = gzip.decode(gzBytes);
    final targetPath = '${tempDir.path}/${type}_temp.db';
    await File(targetPath).writeAsBytes(decompressed);

    if (type == 'qbank') {
      await _dbProvider.replaceAssetsDb(targetPath);
    } else if (type == 'courses') {
      await _dbProvider.replaceCoursesDb(targetPath);
    }

    await _setLocalVersion(type, newVersion);

    await File(gzPath).delete();
    await File(targetPath).delete();
  }

  static bool shouldForceUpdate({
    required int localVersion,
    required int serverVersion,
    required bool serverForceUpdate,
  }) {
    return serverForceUpdate || (serverVersion - localVersion >= 3);
  }

  static bool shouldShowBanner({
    required int localVersion,
    required int serverVersion,
  }) {
    return serverVersion > localVersion;
  }
}
