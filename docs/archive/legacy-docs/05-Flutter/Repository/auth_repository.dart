/// 章鱼智学 — AuthRepository
/// data-db: auth.*
/// 对应页面：login.html, register.html
///
/// 认证方案：JWT (access + refresh)，同一端点 + app_type 参数做角色校验。
/// 详见 docs/教师端功能边界.md 第五章「认证与角色校验」。

/// 登录请求
class LoginRequest {
  final String username;
  final String password;
  final String appType; // "student" | "teacher"

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

/// 登录响应中的用户信息
class UserInfo {
  final int id;
  final String name;
  final String role; // "student" | "teacher"

  const UserInfo({
    required this.id,
    required this.name,
    required this.role,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        id: json['id'] as int,
        name: json['name'] as String,
        role: json['role'] as String,
      );
}

/// 登录响应
class LoginResult {
  final String accessToken;
  final String refreshToken;
  final UserInfo user;

  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
        accessToken: json['access'] as String,
        refreshToken: json['refresh'] as String,
        user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
      );
}

/// Token 刷新响应
class RefreshResult {
  final String accessToken;

  const RefreshResult({required this.accessToken});

  factory RefreshResult.fromJson(Map<String, dynamic> json) => RefreshResult(
        accessToken: json['access'] as String,
      );
}

/// 注册请求
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

class AuthRepository {
  /// POST /api/auth/login/
  /// 请求体含 app_type 参数，服务端校验角色后返回 JWT pair。
  /// app_type = "student" → 仅允许 role=student 的用户登录
  /// app_type = "teacher" → 仅允许 role=teacher 的用户登录
  Future<LoginResult> login(LoginRequest request) async {
    throw UnimplementedError('AuthRepository.login');
  }

  /// POST /api/auth/register/
  /// 注册成功后不返回 token，跳转登录页。
  /// 仅限学生注册，教师账号由管理员在 Django Admin 创建。
  Future<void> register(RegisterRequest data) async {
    throw UnimplementedError('AuthRepository.register');
  }

  /// POST /api/auth/refresh/
  /// 用 refresh token 换取新的 access token。
  Future<RefreshResult> refresh(String refreshToken) async {
    throw UnimplementedError('AuthRepository.refresh');
  }
}
