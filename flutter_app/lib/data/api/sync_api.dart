import 'api_client.dart';

/// 版本检查响应
class VersionStatus {
  final int schemaVersion;
  final int dataVersion;
  final bool forceUpdate;
  final String? message;
  final String? downloadUrl;
  final String? checksum;
  final int? sizeBytes;

  const VersionStatus({
    required this.schemaVersion,
    required this.dataVersion,
    required this.forceUpdate,
    this.message,
    this.downloadUrl,
    this.checksum,
    this.sizeBytes,
  });

  factory VersionStatus.fromJson(Map<String, dynamic> json) => VersionStatus(
        schemaVersion: json['schema_version'] as int,
        dataVersion: json['data_version'] as int,
        forceUpdate: json['force_update'] as bool? ?? false,
        message: json['message'] as String?,
        downloadUrl: json['download_url'] as String?,
        checksum: json['checksum'] as String?,
        sizeBytes: json['size_bytes'] as int?,
      );
}

/// 推送结果
class PushBatchResult {
  final Map<int, int> serverIds;
  final Map<int, Map<String, dynamic>> entityMeta;

  const PushBatchResult({required this.serverIds, this.entityMeta = const {}});

  factory PushBatchResult.fromJson(Map<String, dynamic> json) {
    final raw = json['server_ids'] as Map<String, dynamic>? ?? {};
    final rawMeta = json['entity_meta'] as Map<String, dynamic>? ?? {};
    return PushBatchResult(
      serverIds: raw.map((k, v) => MapEntry(int.parse(k), v as int)),
      entityMeta: rawMeta.map(
        (key, value) => MapEntry(
          int.parse(key),
          Map<String, dynamic>.from(value as Map),
        ),
      ),
    );
  }
}

/// 用户数据拉取信息
class UserPullInfo {
  final String downloadUrl;
  final String checksum;
  final int sizeBytes;
  final int version;

  const UserPullInfo({
    required this.downloadUrl,
    required this.checksum,
    required this.sizeBytes,
    required this.version,
  });

  factory UserPullInfo.fromJson(Map<String, dynamic> json) => UserPullInfo(
        downloadUrl: json['download_url'] as String,
        checksum: json['checksum'] as String,
        sizeBytes: json['size_bytes'] as int,
        version: json['data_version'] as int,
      );
}

/// 同步 API
class SyncApi {
  final ApiClient _client;
  const SyncApi(this._client);

  Future<VersionStatus> checkVersion(String type) async {
    final res = await _client.dio.get('/sync/$type/version/');
    return VersionStatus.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<PushBatchResult> pushBatch(List<Map<String, dynamic>> items) async {
    final res = await _client.dio.post('/sync/push/', data: {'batch': items});
    return PushBatchResult.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// 获取用户数据拉取信息（下载 URL + checksum）
  Future<UserPullInfo> fetchUserPullInfo() async {
    final res = await _client.dio.get('/sync/user/pull/');
    return UserPullInfo.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// 检查用户数据版本
  Future<VersionStatus> checkUserVersion() async {
    final res = await _client.dio.get('/sync/user/version/');
    return VersionStatus.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
