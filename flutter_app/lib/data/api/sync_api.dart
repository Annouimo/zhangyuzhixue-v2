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

  const PushBatchResult({required this.serverIds});

  factory PushBatchResult.fromJson(Map<String, dynamic> json) {
    final raw = json['server_ids'] as Map<String, dynamic>? ?? {};
    return PushBatchResult(
      serverIds: raw.map((k, v) => MapEntry(int.parse(k), v as int)),
    );
  }
}

/// 同步 API
class SyncApi {
  final ApiClient _client;
  const SyncApi(this._client);

  Future<VersionStatus> checkVersion(String type) async {
    final res = await _client.dio.get('/sync/\/version/');
    return VersionStatus.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<PushBatchResult> pushBatch(List<Map<String, dynamic>> items) async {
    final res = await _client.dio.post('/sync/push/', data: {'batch': items});
    return PushBatchResult.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
