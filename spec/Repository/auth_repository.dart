/// 章鱼智学 — AuthRepository
/// data-db: auth.*
/// 对应页面：login.html, register.html

class UserInfo {
  final int id;
  final String name;
  final String? studentId;
  final double points;
  final String? school;

  const UserInfo({
    required this.id,
    required this.name,
    this.studentId,
    required this.points,
    this.school,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        id: json['id'] as int,
        name: json['name'] as String,
        studentId: json['student_id'] as String?,
        points: (json['points'] as num).toDouble(),
        school: json['school'] as String?,
      );
}

class LoginResult {
  final String token;
  final UserInfo user;

  const LoginResult({required this.token, required this.user});

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
        token: json['token'] as String,
        user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
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

class AuthRepository {
  /// POST /api/auth/login/  →  { token, user }
  static Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    throw UnimplementedError('AuthRepository.login');
  }

  /// POST /api/auth/register/
  static Future<bool> register(RegisterRequest data) async {
    throw UnimplementedError('AuthRepository.register');
  }
}
