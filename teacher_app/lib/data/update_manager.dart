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

/// 偏好 key
abstract final class PrefKeys {
  static const qbankVersion = 'app_qbank_version';
  static const coursesVersion = 'app_courses_version';
}

/// 版本检查响应
class _VersionStatus {
  final int schemaVersion;
  final int dataVersion;
  final bool forceUpdate;
  final String? message;
  final String? downloadUrl;
  final String? checksum;
  final int? sizeBytes;

  const _VersionStatus({
    required this.schemaVersion,
    required this.dataVersion,
    required this.forceUpdate,
    this.message,
    this.downloadUrl,
    this.checksum,
    this.sizeBytes,
  });

  factory _VersionStatus.fromJson(Map<String, dynamic> json) => _VersionStatus(
        schemaVersion: json['schema_version'] as int,
        dataVersion: json['data_version'] as int,
        forceUpdate: json['force_update'] as bool? ?? false,
        message: json['message'] as String?,
        downloadUrl: json['download_url'] as String?,
        checksum: json['checksum'] as String?,
        sizeBytes: json['size_bytes'] as int?,
      );
}

/// 更新管理器：版本检查 + .db.gz 下载/校验/替换
///
/// 仅支持 qbank 和 courses 两种数据类型。
class UpdateManager {
  final String serverUrl;
  final DatabaseProvider _dbProvider;
  final Dio _client;
  final Dio _downloadClient;

  UpdateManager(this.serverUrl, this._dbProvider)
      : _client = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        )),
        _downloadClient = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 120),
        ));

  /// 检查 qbank 和 courses 版本
  Future<List<UpdateSummary>> checkAll() async {
    final results = await Future.wait([
      _checkOne('qbank'),
      _checkOne('courses'),
    ]);
    return results;
  }

  Future<UpdateSummary> _checkOne(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final localVersion = prefs.getInt(
      type == 'qbank' ? PrefKeys.qbankVersion : PrefKeys.coursesVersion,
    ) ?? 0;

    final response = await _client.get('$serverUrl/sync/$type/version/');
    final status = _VersionStatus.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );

    return UpdateSummary(
      type: type,
      localVersion: localVersion,
      serverVersion: status.dataVersion,
      forceUpdate: shouldForceUpdate(
        localVersion: localVersion,
        serverVersion: status.dataVersion,
        serverForceUpdate: status.forceUpdate,
      ),
      downloadUrl: status.downloadUrl,
      checksum: status.checksum,
      sizeBytes: status.sizeBytes,
      message: status.message,
    );
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

    // 更新本地版本号
    final prefs = await SharedPreferences.getInstance();
    final key = type == 'qbank' ? PrefKeys.qbankVersion : PrefKeys.coursesVersion;
    await prefs.setInt(key, newVersion);

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
