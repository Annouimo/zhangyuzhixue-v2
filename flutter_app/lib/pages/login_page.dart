import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/auth_repository.dart';

/// 登录页
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    final ok = await AuthRepository.login(
      context,
      _usernameController.text,
      _passwordController.text,
    );
    setState(() => _loading = false);
    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school, size: 80, color: AppTheme.primaryColor),
              const SizedBox(height: 8),
              const Text('章鱼智学', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              const SizedBox(height: 48),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: '用户名 / 手机号', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '密码', prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('登录', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text('没有账号？去注册', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
