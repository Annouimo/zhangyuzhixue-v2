import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_theme.dart';
import '../data/api/auth_api.dart';
import '../data/api/api_client.dart';
import '../data/prefs/app_prefs.dart';
import '../data/sync/sync_manager.dart';
import '../domain/auth_repository.dart';
import '../domain/preference_repository.dart';
import '../data/daos/preference_dao.dart';
import '../data/database/database_provider.dart';
import '../widgets/sync_progress_dialog.dart';
import 'router.dart';
import '../data/debug/audit_logger.dart';

/// 登录页
class LoginPage extends StatefulWidget {
  final AuthRepository? authRepository;
  final PreferenceRepository? preferenceRepository;

  const LoginPage({
    super.key,
    this.authRepository,
    this.preferenceRepository,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;

  late final AuthRepository _authRepo;
  PreferenceRepository? _prefRepo;

  @override
  void initState() {
    super.initState();
    _authRepo = widget.authRepository ?? AuthRepository(AuthApi(ApiClient()));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final result = await _authRepo.login(LoginRequest(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        appType: 'student',
      ));

      // 保存 token
      await AppPrefs().setAccessToken(result.accessToken);
      await AppPrefs().setRefreshToken(result.refreshToken);

      // 保存用户缓存
      final userJson = jsonEncode(result.user);
      await AppPrefs().setUserCacheStr(userJson);

      if (!mounted) return;

      // 同步用户数据（展示进度弹窗）
      final syncOk = await showSyncProgress(context, (onProgress) async {
        await SyncManager().onLogin(onProgress: onProgress);
      });
      if (!mounted) return;

      // 同步失败时页面内显示提示（登录流程已走完，token 已保存）
      if (!syncOk) {
        _showError('数据同步失败，可稍后在「我的」页面手动同步');
      }

      // 检查是否有学习偏好
      final hasPrefs = await _checkPreferences();
      if (!mounted) return;

      if (hasPrefs) {
        context.go(AppRoutes.mainShell);
      } else {
        context.go(AppRoutes.preferenceWelcome);
      }
    } catch (e) {
      AuditLogger.instance.error('LoginPage._login', e);
      if (!mounted) return;
      _showError(_extractErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
      AuditLogger.instance.page('LoginPage', {'loading': _loading});
    }
  }

  Future<bool> _checkPreferences() async {
    try {
      _prefRepo ??= widget.preferenceRepository ?? PreferenceRepository(
        PreferenceDao(DatabaseProvider().appDb),
      );
      final count = await _prefRepo!.getCount();
      return count > 0;
    } catch (e) {
      AuditLogger.instance.error('LoginPage._checkPreferences', e);
      // DB 未初始化等，默认有偏好
      return true;
    }
  }

  String _extractErrorMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('40001')) return '用户名或密码错误';
    if (msg.contains('401')) return '用户名或密码错误';
    return '登录失败，请稍后重试';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.baseSpacing),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 品牌标识
                    const Text(
                      '🐙 章鱼智学',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '北京高考数学 · 题库 · 讲义 · 解题训练',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '📚 登录',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 用户名
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: '用户名',
                        hintText: '输入用户名',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? '请输入用户名' : null,
                    ),
                    const SizedBox(height: 16),

                    // 密码
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: '密码',
                        hintText: '输入密码',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? '请输入密码' : null,
                    ),
                    const SizedBox(height: 24),

                    // 登录按钮
                    ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('登录'),
                    ),
                    const SizedBox(height: 16),

                    // 注册入口
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '还没有账号？',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.register),
                          child: const Text('使用邀请码注册'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
