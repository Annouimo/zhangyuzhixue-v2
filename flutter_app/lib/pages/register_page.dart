import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_theme.dart';
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
        const SnackBar(
          content: Text('注册成功，请登录'),
          backgroundColor: AppColors.success,
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
      if (mounted) setState(() => _loading = false);
      AuditLogger.instance.page('RegisterPage', {'saving': _loading});
    }
  }

  String _extractErrorMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('40101')) return '邀请码无效或已使用';
    if (msg.contains('username')) return '用户名已存在';
    if (msg.contains('invitation_code')) return '邀请码无效或已使用';
    return '注册失败，请稍后重试';
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
      appBar: AppBar(
        title: const Text('注册'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.baseSpacing),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '使用邀请码注册',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '需要邀请码才能注册，请联系管理员获取',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 邀请码
                    TextFormField(
                      controller: _inviteCodeController,
                      decoration: const InputDecoration(
                        labelText: '邀请码',
                        hintText: '输入邀请码',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? '请输入邀请码' : null,
                    ),
                    const SizedBox(height: 16),

                    // 用户名
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: '用户名',
                        hintText: '输入用户名',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return '请输入用户名';
                        if (v.trim().length < 3) return '用户名至少 3 个字符';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 姓名
                    TextFormField(
                      controller: _realNameController,
                      decoration: const InputDecoration(
                        labelText: '姓名',
                        hintText: '输入真实姓名',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? '请输入姓名' : null,
                    ),
                    const SizedBox(height: 16),

                    // 手机号
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: '手机号',
                        hintText: '输入手机号',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return '请输入手机号';
                        if (!RegExp(r'^1\d{10}$').hasMatch(v.trim())) {
                          return '请输入正确的手机号';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 高考年份
                    DropdownButtonFormField<String>(
                      initialValue: _gaokaoYear,
                      decoration: const InputDecoration(
                        labelText: '高考年份',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      items: ['2025', '2026', '2027', '2028'].map((y) => DropdownMenuItem(
                        value: y,
                        child: Text('$y 年'),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _gaokaoYear = v);
                      },
                    ),
                    const SizedBox(height: 16),

                    // 密码
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: '密码',
                        hintText: '至少 6 位',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.isEmpty) return '请输入密码';
                        if (v.length < 6) return '密码至少 6 位';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 确认密码
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: '确认密码',
                        hintText: '再次输入密码',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _register(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return '请确认密码';
                        if (v != _passwordController.text) return '两次密码不一致';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 提交按钮
                    ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('注册'),
                    ),
                    const SizedBox(height: 16),

                    // 返回登录
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '已有账号？',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('返回登录'),
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

