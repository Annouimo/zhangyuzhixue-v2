import 'api_client.dart';
/// 认证请求模型
class LoginRequest {
  final String username;
  final String password;
  final String appType;

  const LoginRequest({
    required this.username,
    required this.password,
    required this.appType,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
        'app_type': appType,
      };
}

class LoginResult {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;

  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
        accessToken: json['access'] as String,
        refreshToken: json['refresh'] as String,
        user: json['user'] as Map<String, dynamic>,
      );
}

class RefreshResult {
  final String accessToken;
  const RefreshResult({required this.accessToken});

  factory RefreshResult.fromJson(Map<String, dynamic> json) => RefreshResult(
        accessToken: json['access'] as String,
      );
}

class RegisterRequest {
  final String inviteCode;
  final String username;
  final String realName;
  final String phone;
  final String gaokaoYear;
  final String password;

  const RegisterRequest({
    required this.inviteCode,
    required this.username,
    required this.realName,
    required this.phone,
    required this.gaokaoYear,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'invitation_code': inviteCode,
        'username': username,
        'real_name': realName,
        'phone': phone,
        'gaokao_year': gaokaoYear,
        'password': password,
      };
}

/// 认证 API
class AuthApi {
  final ApiClient _client;
  const AuthApi(this._client);

  Future<LoginResult> login(LoginRequest request) async {
    final res = await _client.dio.post('/auth/login/', data: request.toJson());
    return LoginResult.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> register(RegisterRequest request) async {
    await _client.dio.post('/auth/register/', data: request.toJson());
  }

  Future<RefreshResult> refresh(String refreshToken) async {
    final res = await _client.dio.post('/auth/refresh/', data: {
      'refresh': refreshToken,
    });
    return RefreshResult.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _client.dio.post('/auth/logout/');
  }
}
