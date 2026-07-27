import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_auth_layout.dart';
import 'package:shared/widgets/app_button.dart';
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

  const LoginPage({super.key, this.authRepository, this.preferenceRepository});

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
      final result = await _authRepo.login(
        LoginRequest(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          appType: 'student',
        ),
      );

      // 保存 token
      await AppPrefs().setAccessToken(result.accessToken);
      await AppPrefs().setRefreshToken(result.refreshToken);

      if (!mounted) return;

      // 同步用户数据（展示进度弹窗）
      final syncOk = await showSyncProgress(
        context,
        (onProgress) async {
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
      if (mounted) {
        setState(() {
          _loading = false;
          _submitting = false;
        });
      }
      AuditLogger.instance.page('LoginPage', {'loading': _loading});
    }
  }

  Future<bool> _checkPreferences() async {
    try {
      _prefRepo ??=
          widget.preferenceRepository ??
          PreferenceRepository(PreferenceDao(DatabaseProvider()));
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

  Future<void> _cancelAccountDeletion() async {
    final usernameController = TextEditingController(
      text: _usernameController.text.trim(),
    );
    final passwordController = TextEditingController();
    final credentials = await showDialog<(String, String)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('撤销账号注销'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('冷静期内可使用原用户名和密码恢复账号。'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: '原用户名'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '原密码'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final username = usernameController.text.trim();
              final password = passwordController.text;
              if (username.isNotEmpty && password.isNotEmpty) {
                Navigator.pop(ctx, (username, password));
              }
            },
            child: const Text('恢复账号'),
          ),
        ],
      ),
    );
    usernameController.dispose();
    passwordController.dispose();
    if (credentials == null || !mounted) return;
    try {
      await _authRepo.cancelAccountDeletion(
        username: credentials.$1,
        password: credentials.$2,
      );
      if (!mounted) return;
      _usernameController.text = credentials.$1;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('账号已恢复，请重新登录')));
    } catch (e) {
      if (!mounted) return;
      _showError(_extractErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppAuthLayout(
      title: '欢迎回来',
      subtitle: '登录后继续你的个性化数学学习计划。',
      footer: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '还没有账号？',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
              TextButton(
                onPressed: () => RouterUtils.push(context, AppRoutes.register),
                child: const Text('注册账号'),
              ),
            ],
          ),
          TextButton(
            onPressed: _cancelAccountDeletion,
            child: const Text('撤销账号注销'),
          ),
          TextButton.icon(
            onPressed: _exportLog,
            icon: const Icon(Icons.description_outlined, size: 18),
            label: const Text('导出运行日志'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                hintText: '输入用户名',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '请输入用户名' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '密码',
                hintText: '输入密码',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
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
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _login(),
              validator: (value) =>
                  value == null || value.isEmpty ? '请输入密码' : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showContactDialog,
                child: const Text('忘记密码？'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: '登录',
              icon: Icons.login_rounded,
              onPressed: _loading ? null : _login,
              isLoading: _loading,
              fullWidth: true,
            ),
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: colors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '学习记录会在登录后自动恢复，并支持离线使用。',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportLog() async {
    final msg = switch (await OperationLog.instance.exportToShare()) {
      ExportResult.success => '已打开分享面板',
      ExportResult.fileNotFound => '暂无日志数据',
      ExportResult.notReady => '日志已导出到 Downloads 文件夹',
      ExportResult.savedToFolder => '日志已导出到 Downloads 文件夹',
    };
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}
