import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared/theme/app_theme.dart';
import '../data/api/auth_api.dart';
import '../data/api/api_client.dart';
import '../data/api/user_api.dart';
import '../data/prefs/app_prefs.dart';
import '../data/sync/sync_manager.dart';
import '../domain/auth_repository.dart';
import '../domain/preference_repository.dart';
import '../data/daos/preference_dao.dart';
import '../data/database/database_provider.dart';
import 'package:shared/widgets/sync_progress_dialog.dart';
import 'router.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

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
  bool _submitting = false;
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
      final colors = context.colors;
    if (!_formKey.currentState!.validate()) return;
    if (_submitting) return;
    setState(() => _submitting = true);
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

      if (!mounted) return;

      // 同步用户数据（展示进度弹窗）
      final syncOk = await showSyncProgress(context, (onProgress) async {
        await SyncManager().onLogin(onProgress: onProgress);
      },
        title: '恢复数据',
        message: '正在从服务器恢复你的学习记录…',
      );
      if (!mounted) return;

      // 缓存 accessible_course_ids（登录即获取，供离线过滤用）
      try {
        final data = await UserApi(ApiClient()).pendingAssignments();
        final ids = (data['accessible_course_ids'] as List).cast<int>();
        if (ids.isNotEmpty) {
          await AppPrefs().setAccessibleCourseIds(ids);
        }
      } catch (e) {
        AuditLogger.instance.error('LoginPage.cacheCourseIds', e);
        OperationLog.instance.error('LoginPage.cacheCourseIds', e);
      }

      // 同步失败时页面内显示提示（登录流程已走完，token 已保存）
      if (!syncOk) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('数据同步失败，部分数据可能未恢复'),
            backgroundColor: colors.warning,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: '去同步',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                context.go(AppRoutes.syncQueue);
              },
            ),
          ),
        );
      }

      // 检查是否有学习偏好
      final hasPrefs = await _checkPreferences();
      if (!mounted) return;

      if (hasPrefs) {
        context.go(AppRoutes.mainShell);
      } else {
        context.go(AppRoutes.preferenceWelcome);
      }
      OperationLog.instance.action('login', 'ok');
    } catch (e) {
      AuditLogger.instance.error('LoginPage._login', e);
      OperationLog.instance.error('LoginPage._login', e);
      if (!mounted) return;
      _showError(_extractErrorMessage(e));
    } finally {
      if (mounted) setState(() { _loading = false; _submitting = false; });
      AuditLogger.instance.page('LoginPage', {'loading': _loading});
    }
  }

  Future<bool> _checkPreferences() async {
    try {
      _prefRepo ??= widget.preferenceRepository ?? PreferenceRepository(
        PreferenceDao(DatabaseProvider()),
      );
      final count = await _prefRepo!.getCount();
      return count > 0;
    } catch (e) {
      AuditLogger.instance.error('LoginPage._checkPreferences', e);
      OperationLog.instance.error('LoginPage._checkPreferences', e);
      // DB 未初始化等，默认有偏好
      return true;
    }
  }

  String _extractErrorMessage(Object e) {
    // 优先从服务端响应体提取真实错误描述
    if (e is DioException && e.response?.data is Map) {
      final serverMsg = (e.response!.data as Map)["message"];
      if (serverMsg is String && serverMsg.isNotEmpty) {
        return serverMsg;
      }
    }
    final msg = e.toString();
    if (msg.contains('40001')) return '用户名或密码错误';
    if (msg.contains('401')) return '用户名或密码错误';
    // 网络连接错误（DNS 失败、无网络等）
    if (e is DioException && e.type == DioExceptionType.connectionError) {
      return '网络连接失败，请检查网络';
    }
    return '登录失败，请稍后重试';
  }

  void _showError(String message) {
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('忘记密码'),
        content: const Text('请联系微信管理员重置密码：\n\n微信：zhangyubb101\n（备注「章鱼智学」）'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('复制微信号'),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: 'zhangyubb101'));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('微信号已复制'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
      final colors = context.colors;
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/logo_mark.png', width: 32, height: 32),
                        SizedBox(width: 8),
                        Text(
                          '章鱼智学',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '北京高考数学 · 题库 · 讲义 · 解题训练',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      '📚 登录',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
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
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showContactDialog(),
                      child: Text(
                        '忘记密码',
                        style: TextStyle(fontSize: 12, color: context.colors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 16),

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
                        Text(
                          '还没有账号？',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => RouterUtils.push(context,AppRoutes.register),
                          child: const Text('使用邀请码注册'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 导出日志
                    GestureDetector(
                      onTap: _exportLog,
                      child: Text(
                        '导出日志',
                        style: TextStyle(fontSize: 11, color: colors.textMuted),
                      ),
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

  Future<void> _exportLog() async {
    final msg = switch (await OperationLog.instance.exportToShare()) {
      ExportResult.success        => '已打开分享面板',
      ExportResult.fileNotFound   => '暂无日志数据',
      ExportResult.notReady       => '日志已导出到 Downloads 文件夹',
      ExportResult.savedToFolder  => '日志已导出到 Downloads 文件夹',
    };
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

