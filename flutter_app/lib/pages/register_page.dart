import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/app_auth_layout.dart';
import 'package:shared/widgets/app_button.dart';
import '../data/api/auth_api.dart';
import '../data/api/api_client.dart';
import '../domain/auth_repository.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

/// 注册页
class RegisterPage extends StatefulWidget {
  final AuthRepository? authRepository;

  const RegisterPage({super.key, this.authRepository});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _realNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _gaokaoYear = '2026';

  bool _loading = false;
  bool _submitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late final AuthRepository _authRepo;

  @override
  void initState() {
    super.initState();
    _authRepo = widget.authRepository ?? AuthRepository(AuthApi(ApiClient()));
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _realNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_submitting) return;
    setState(() => _submitting = true);
    setState(() => _loading = true);

    try {
      await _authRepo.register(RegisterRequest(
        inviteCode: _inviteCodeController.text.trim(),
        username: _usernameController.text.trim(),
        realName: _realNameController.text.trim(),
        phone: _phoneController.text.trim(),
        gaokaoYear: _gaokaoYear,
        password: _passwordController.text,
      ));

      if (!mounted) return;

      // 注册成功，不返回 token，跳回登录页
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('注册成功，请登录'),
          backgroundColor: context.colors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      OperationLog.instance.action('register', 'ok');
      context.pop();
    } catch (e) {
      AuditLogger.instance.error('RegisterPage._register', e);
      OperationLog.instance.error('RegisterPage._register', e);
      if (!mounted) return;
      _showError(_extractErrorMessage(e));
    } finally {
      if (mounted) setState(() { _loading = false; _submitting = false; });
      AuditLogger.instance.page('RegisterPage', {'saving': _loading});
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
    if (msg.contains('40101')) return '邀请码无效或已使用';
    if (msg.contains('username')) return '用户名已存在';
    if (msg.contains('invitation_code')) return '邀请码无效或已使用';
    // 网络连接错误（DNS 失败、无网络等）
    if (e is DioException && e.type == DioExceptionType.connectionError) {
      return '网络连接失败，请检查网络';
    }
    return '注册失败，请稍后重试';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.colors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppAuthLayout(
      title: '创建学生账号',
      subtitle: '使用有效邀请码注册，完成后即可登录并设置学习偏好。',
      leading: IconButton(
        tooltip: '返回登录',
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => context.pop(),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _inviteCodeController,
              decoration: const InputDecoration(
                labelText: '邀请码',
                hintText: '输入管理员提供的邀请码',
                prefixIcon: Icon(Icons.key_outlined),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) => value == null || value.trim().isEmpty
                  ? '请输入邀请码'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 420;
                final username = TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: '用户名',
                    hintText: '至少 3 个字符',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return '请输入用户名';
                    if (value.trim().length < 3) return '用户名至少 3 个字符';
                    return null;
                  },
                );
                final realName = TextFormField(
                  controller: _realNameController,
                  decoration: const InputDecoration(
                    labelText: '姓名',
                    hintText: '输入真实姓名',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? '请输入姓名'
                      : null,
                );
                if (!twoColumns) {
                  return Column(
                    children: [username, const SizedBox(height: AppSpacing.md), realName],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: username),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: realName),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '手机号',
                hintText: '用于账号联系',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              validator: (value) {
                if (value == null || value.trim().isEmpty) return '请输入手机号';
                if (!RegExp(r'^1\d{10}$').hasMatch(value.trim())) return '请输入有效手机号';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _gaokaoYear,
              decoration: const InputDecoration(
                labelText: '高考年份',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              items: ['2025', '2026', '2027', '2028']
                  .map((year) => DropdownMenuItem(
                        value: year,
                        child: Text('$year 年'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _gaokaoYear = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '密码',
                hintText: '至少 6 位',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) {
                if (value == null || value.isEmpty) return '请输入密码';
                if (value.length < 6) return '密码至少 6 位';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: '确认密码',
                hintText: '再次输入密码',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  tooltip: _obscureConfirm ? '显示密码' : '隐藏密码',
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(
                    () => _obscureConfirm = !_obscureConfirm,
                  ),
                ),
              ),
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _register(),
              validator: (value) {
                if (value == null || value.isEmpty) return '请确认密码';
                if (value != _passwordController.text) return '两次密码不一致';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: '完成注册',
              icon: Icons.person_add_alt_1_rounded,
              onPressed: _loading ? null : _register,
              isLoading: _loading,
              fullWidth: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '注册即表示你同意按学校或机构要求使用本学习系统。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '已有账号？',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          TextButton(onPressed: () => context.pop(), child: const Text('返回登录')),
        ],
      ),
    );
  }
}
