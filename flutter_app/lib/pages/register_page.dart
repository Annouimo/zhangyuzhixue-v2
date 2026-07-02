import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/auth_repository.dart';

/// 注册页
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _inviteController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPwdController = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    if (_passwordController.text != _confirmPwdController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('两次密码不一致')));
      return;
    }
    setState(() => _loading = true);
    final ok = await AuthRepository.register(
      context,
      name: _nameController.text,
      phone: _phoneController.text,
      invitationCode: _inviteController.text,
      password: _passwordController.text,
      studentId: _studentIdController.text.isEmpty ? null : _studentIdController.text,
    );
    setState(() => _loading = false);
    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    _inviteController.dispose();
    _passwordController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          children: [
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: '姓名', prefixIcon: Icon(Icons.badge_outline))),
            const SizedBox(height: 14),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: '手机号', prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 14),
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: '学号（可选）',
                hintText: '________________________',
                hintStyle: TextStyle(color: Color(0xFFBDBDBD)),
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 14),
            TextField(controller: _inviteController, decoration: const InputDecoration(labelText: '邀请码', prefixIcon: Icon(Icons.vpn_key_outlined))),
            const SizedBox(height: 14),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: '密码', prefixIcon: Icon(Icons.lock_outline))),
            const SizedBox(height: 14),
            TextField(controller: _confirmPwdController, obscureText: true, decoration: const InputDecoration(labelText: '确认密码', prefixIcon: Icon(Icons.lock_outline))),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('注册', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('已有账号？去登录', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
