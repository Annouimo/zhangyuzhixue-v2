import '../data/api/auth_api.dart';
import '../data/sync/sync_manager.dart';

/// 认证 — 委托 AuthApi
/// 不依赖本地数据库，纯 API 调用。
class AuthRepository {
  final AuthApi _api;
  const AuthRepository(this._api);

  Future<LoginResult> login(LoginRequest request) => _api.login(request);

  Future<void> register(RegisterRequest data) => _api.register(data);

  Future<RefreshResult> refresh(String refreshToken) =>
      _api.refresh(refreshToken);

  Future<DateTime> requestAccountDeletion(String currentPassword) =>
      _api.requestAccountDeletion(currentPassword);

  Future<void> cancelAccountDeletion({
    required String username,
    required String password,
  }) => _api.cancelAccountDeletion(username: username, password: password);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _api.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  Future<void> logout() async {
    await SyncManager().onLogout();
    await _api.logout();
  }
}
