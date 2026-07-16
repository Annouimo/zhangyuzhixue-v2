import 'package:dio/dio.dart';
import 'api_client.dart';

/// 用户 API
class UserApi {
  final ApiClient _client;
  const UserApi(this._client);

  Future<Map<String, dynamic>> getInfo() async {
    final res = await _client.dio.get('/user/me/');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _client.dio.patch('/user/me/', data: data);
  }

  Future<String> uploadAvatar(String localPath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(localPath),
    });
    final res = await _client.dio.post('/user/avatar/', data: formData);
    final avatarUrl = (res.data['data'] as Map<String, dynamic>)['avatar'] as String?;
    return avatarUrl ?? (throw Exception('头像上传成功但未返回URL'));
  }

  /// 签到
  Future<Map<String, dynamic>> checkin() async {
    final res = await _client.dio.post('/user/checkin/');
    return res.data['data'] as Map<String, dynamic>;
  }

  /// 待办作业列表（含 deadline 信息）
  Future<Map<String, dynamic>> pendingAssignments() async {
    final res = await _client.dio.get('/user/pending-assignments/');
    return res.data['data'] as Map<String, dynamic>;
  }

  /// 等级百分位（调用服务端专用端点）
  Future<Map<String, dynamic>> getLevelPercentile() async {
    final res = await _client.dio.get('/user/level-percentile/');
    return res.data['data'] as Map<String, dynamic>;
  }
}
