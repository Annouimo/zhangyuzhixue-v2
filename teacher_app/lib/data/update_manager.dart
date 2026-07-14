import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/database_provider.dart';

/// 教师端更新管理器 — 仅检查 qbank 和 courses 版本
class TeacherUpdateManager {
  final DatabaseProvider _dbProvider;
  final Dio _client;
  final String _baseUrl;

  TeacherUpdateManager(this._dbProvider, this._baseUrl)
      : _client = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 120),
        ));

  /// 检查单个数据库版本
  Future<UpdateInfo> checkVersion(String type) async {
    try {
      final res = await _client.get('$_baseUrl/api/v1/sync/$type/version/');
      final data = res.data['data'] as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      final localKey = '${type}_version';
      final localVersion = prefs.getInt(localKey) ?? 0;
      return UpdateInfo(
        type: type,
        localVersion: localVersion,
        serverVersion: data['data_version'] as int,
        hasUpdate: (data['data_version'] as int) > localVersion,
        downloadUrl: data['download_url'] as String? ?? '',
        checksum: data['checksum'] as String? ?? '',
      );
    } catch (e) {
      return UpdateInfo(
        type: type,
        localVersion: 0,
        serverVersion: 0,
        hasUpdate: false,
        downloadUrl: '',
        checksum: '',
      );
    }
  }

  /// 下载并替换数据库
  Future<void> downloadAndReplace({
    required String type,
    required String url,
    required String expectedChecksum,
    required int newVersion,
    void Function(double progress)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final gzPath = '${tempDir.path}/${type}_temp.db.gz';

    await _client.download(url, gzPath,
        onReceiveProgress: (received, total) {
      if (total > 0 && onProgress != null) onProgress(received / total);
    });

    final gzBytes = await File(gzPath).readAsBytes();
    final digest = sha256.convert(gzBytes);
    if (digest.toString() != expectedChecksum) {
      await File(gzPath).delete();
      throw Exception('Checksum mismatch for $type');
    }

    final decompressed = gzip.decode(gzBytes);
    final targetPath = '${tempDir.path}/${type}_temp.db';
    await File(targetPath).writeAsBytes(decompressed);

    if (type == 'qbank') {
      await _dbProvider.replaceAssetsDb(targetPath);
    } else if (type == 'courses') {
      await _dbProvider.replaceCoursesDb(targetPath);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${type}_version', newVersion);

    await File(gzPath).delete();
    await File(targetPath).delete();
  }
}

class UpdateInfo {
  final String type;
  final int localVersion;
  final int serverVersion;
  final bool hasUpdate;
  final String downloadUrl;
  final String checksum;

  const UpdateInfo({
    required this.type,
    required this.localVersion,
    required this.serverVersion,
    required this.hasUpdate,
    required this.downloadUrl,
    required this.checksum,
  });
}
