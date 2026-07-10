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
    return (res.data['data'] as Map<String, dynamic>)['url'] as String;
  }
}
