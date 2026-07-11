import 'dart:async';
import '../data/api/auth_api.dart';
import '../data/sync/sync_manager.dart';

/// 认证 — 委托 AuthApi
/// 不依赖本地数据库，纯 API 调用。
class AuthRepository {
  final AuthApi _api;
  const AuthRepository(this._api);

  Future<LoginResult> login(LoginRequest request) async {
    final result = await _api.login(request);
    // 登录后触发用户数据拉取（静默失败不影响登录）
    unawaited(SyncManager().onLogin());
    return result;
  }

  Future<void> register(RegisterRequest data) => _api.register(data);

  Future<RefreshResult> refresh(String refreshToken) => _api.refresh(refreshToken);

  Future<void> logout() async {
    await SyncManager().onLogout();
    await _api.logout();
  }
}
