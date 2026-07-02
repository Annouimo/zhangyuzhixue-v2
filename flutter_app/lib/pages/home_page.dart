import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/user_repository.dart';

/// 首页
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await UserRepository.getUserInfo();
    setState(() => _user = user);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return '早上好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // 问候语（正文，非 AppBar）
              Text(
                '${_greeting}，${_user?['name'] ?? '...'}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              // 题目推荐入口
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/recommend-list'),
                child: const Text('题目推荐', style: TextStyle(fontSize: 18, color: AppTheme.primaryColor)),
              ),
              const SizedBox(height: 24),
              // 自主组卷入口
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/exam-builder'),
                child: const Text('自主组卷', style: TextStyle(fontSize: 18, color: AppTheme.primaryColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
