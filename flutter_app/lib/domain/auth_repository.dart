import '../data/api/auth_api.dart';

/// 认证 — 委托 AuthApi
/// 不依赖本地数据库，纯 API 调用。
class AuthRepository {
  final AuthApi _api;
  const AuthRepository(this._api);

  Future<LoginResult> login(LoginRequest request) => _api.login(request);

  Future<void> register(RegisterRequest data) => _api.register(data);

  Future<RefreshResult> refresh(String refreshToken) => _api.refresh(refreshToken);

  Future<void> logout() => _api.logout();
}
