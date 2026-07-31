import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../api/sync_api.dart';
import 'package:shared/debug/operation_log.dart';
import '../database/database_provider.dart';
import '../prefs/app_prefs.dart';
import 'package:shared/debug/audit_logger.dart';

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
  final Object? error;

  const UpdateSummary({
    required this.type,
    required this.localVersion,
    required this.serverVersion,
    required this.forceUpdate,
    this.downloadUrl,
    this.checksum,
    this.sizeBytes,
    this.message,
    this.error,
  });

  bool get hasUpdate => serverVersion > localVersion;

  bool get canDownload =>
      hasUpdate &&
      downloadUrl != null &&
      downloadUrl!.trim().isNotEmpty &&
      checksum != null &&
      checksum!.trim().isNotEmpty &&
      (sizeBytes ?? 0) > 0;

  /// User databases obtain download metadata lazily from /sync/user/pull/.
  bool get canApply => type == 'user' ? hasUpdate : canDownload;

  bool get localIsNewer => localVersion > serverVersion;
  bool get checkFailed => error != null;
}

/// 更新管理器：版本检查 + .db.gz 下载/校验/替换
class UpdateManager {
  final SyncApi _syncApi;
  final DatabaseProvider _dbProvider;
  final Dio _downloadClient;

  UpdateManager(this._syncApi, this._dbProvider)
    : _downloadClient = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

  /// 检查 qbank、courses 和 user 版本
  Future<List<UpdateSummary>> checkAll() async {
    final results = await Future.wait([
      _checkOne('qbank'),
      _checkOne('courses'),
      _checkOne('user'),
    ]);
    return results;
  }

  Future<UpdateSummary> checkUser() => _checkOne('user');

  Future<UpdateSummary> _checkOne(String type) async {
    final localVersion = await _readLocalVersion(type);
    try {
      final status = await _syncApi.checkVersion(type);
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
    } catch (e) {
      AuditLogger.instance.error('UpdateManager._checkOne($type)', e);
      OperationLog.instance.error('UpdateManager.checkVersion.$type', e);
      return UpdateSummary(
        type: type,
        localVersion: localVersion,
        serverVersion: localVersion, // 失败时视为无更新，不阻塞其他类型
        forceUpdate: false,
        error: e,
      );
    }
  }

  Future<int> _readLocalVersion(String type) async {
    if (type == 'user') return AppPrefs().userVersion;
    try {
      return await _dbProvider.dataVersion(type);
    } catch (error, stack) {
      OperationLog.instance.error(
        'UpdateManager.localVersion.$type',
        error,
        stack,
      );
      return type == 'qbank'
          ? AppPrefs().qbankVersion
          : AppPrefs().coursesVersion;
    }
  }

  /// 下载 .db.gz → 解压 → checksum 校验 → 替换
  Future<void> downloadAndReplace({
    required String type,
    required String url,
    required String expectedChecksum,
    int newVersion = 0,
    void Function(double progress)? onProgress,
  }) async {
    if (type != 'user') {
      if (newVersion <= 0) {
        throw ArgumentError.value(newVersion, 'newVersion', 'Must be positive');
      }
      final currentVersion = await _dbProvider.dataVersion(type);
      if (newVersion <= currentVersion) {
        throw StateError(
          'Refusing to replace $type v$currentVersion with v$newVersion',
        );
      }
    }

    final tempDir = await getTemporaryDirectory();
    final gzPath = '${tempDir.path}/${type}_temp.db.gz';

    // 清理上次残留的临时文件
    final gzFile = File(gzPath);
    if (await gzFile.exists()) await gzFile.delete();
    final dbPath = '${tempDir.path}/${type}_temp.db';
    final dbFile = File(dbPath);
    if (await dbFile.exists()) await dbFile.delete();

    await _downloadClient.download(
      url,
      gzPath,
      onReceiveProgress: (received, total) {
        OperationLog.instance.action('download_progress', '$received/$total');
        if (total > 0 && onProgress != null) onProgress(received / total);
      },
    );

    final gzBytes = await File(gzPath).readAsBytes();
    final digest = sha256.convert(gzBytes);

    if (digest.toString() != expectedChecksum) {
      await File(gzPath).delete();
      AuditLogger.instance.sync('checksum', {'type': type, 'match': false});
      throw Exception(
        'Checksum mismatch for $type: expected $expectedChecksum, got ${digest.toString()}',
      );
    }
    AuditLogger.instance.sync('checksum', {'type': type, 'match': true});

    final decompressed = gzip.decode(gzBytes);
    final targetPath = '${tempDir.path}/${type}_temp.db';
    await File(targetPath).writeAsBytes(decompressed);

    if (type == 'qbank') {
      await _dbProvider.replaceAssetsDb(targetPath);
      await AppPrefs().setQbankVersion(newVersion);
    } else if (type == 'courses') {
      await _dbProvider.replaceCoursesDb(targetPath);
      await AppPrefs().setCoursesVersion(newVersion);
    } else if (type == 'user') {
      await _dbProvider.replaceUserDb(targetPath);
      await AppPrefs().setUserVersion(newVersion);
    }

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

  static bool shouldUpdateSilently(UpdateSummary summary) =>
      summary.hasUpdate && summary.canApply && !summary.forceUpdate;
}
