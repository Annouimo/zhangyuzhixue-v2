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

  /// 等级百分位（调用服务端专用端点）
  Future<Map<String, dynamic>> getLevelPercentile() async {
    final res = await _client.dio.get('/user/level-percentile/');
    return res.data['data'] as Map<String, dynamic>;
  }

  // ── 组卷发现/预览 ──

  /// 获取全平台公开组卷列表
  Future<List<dynamic>> getExplorePapers() async {
    final res = await _client.dio.get('/interactions/exam/explore/');
    return (res.data['data'] as List<dynamic>?) ?? [];
  }

  /// 获取他人组卷预览详情
  Future<Map<String, dynamic>> getPreviewOther(int paperId) async {
    final res = await _client.dio.get('/interactions/exam/preview-other/$paperId/');
    return res.data['data'] as Map<String, dynamic>;
  }

  /// 批量查询收藏组卷详情
  Future<List<dynamic>> getFavoritePapers(List<int> paperIds) async {
    final res = await _client.dio.post('/interactions/exam/favorites/', data: {'paper_ids': paperIds});
    return (res.data['data'] as List<dynamic>?) ?? [];
  }
}
