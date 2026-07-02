import 'package:flutter/material.dart';

/// 认证相关：登录、注册、退出、登录状态
class AuthRepository {
  static bool _loggedIn = true; // mock: 默认已登录，方便 UI 调试

  /// 检查是否已登录（静默 mock）
  static bool isLoggedIn() => _loggedIn;

  /// 获取 mock 登录用户信息（供 UserRepository 使用）
  static Map<String, dynamic> getMockUser() {
    return {
      'name': '李小红',
      'student_id': '2026001',
      'points': 9.2,
    };
  }

  /// 登录（写入操作，显示 Toast）
  static Future<bool> login(BuildContext context, String username, String password) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在进行登录操作，需要验证用户身份并获取 Token')),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    _loggedIn = true;
    return true;
  }

  /// 注册（写入操作，显示 Toast）
  static Future<bool> register(
    BuildContext context, {
    required String name,
    required String phone,
    required String invitationCode,
    required String password,
    String? studentId,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在进行注册操作，需要提交用户注册信息')),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    _loggedIn = true;
    return true;
  }

  /// 退出登录（写入操作，显示 Toast）
  static Future<void> logout(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在进行退出登录操作，需要清除登录状态')),
    );
    await Future.delayed(const Duration(milliseconds: 200));
    _loggedIn = false;
  }
}
