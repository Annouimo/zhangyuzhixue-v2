import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/user_repository.dart';
import '../repositories/auth_repository.dart';

/// 我的（个人中心）
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          children: [
            // 用户信息卡片
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryLight,
                      child: Text(
                        _user?['name'] != null && (_user!['name'] as String).isNotEmpty
                            ? (_user!['name'] as String)[0]
                            : '?',
                        style: const TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_user?['name'] ?? '', style: const TextStyle(fontSize: AppTheme.fontSizeLarge, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('学号：${_user?['student_id'] ?? ''}', style: const TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text('${_user?['points'] ?? 0}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                        const Text('积分', style: TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontSizeSmall)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            // 入口列表
            _entryItem(Icons.history, '做题历史', () => Navigator.pushNamed(context, '/answer-history')),
            _entryItem(Icons.article_outlined, '组卷历史', () {}),
            _entryItem(Icons.receipt_long_outlined, '积分流水', () => Navigator.pushNamed(context, '/points-history')),
            const Divider(height: 32),
            _entryItem(Icons.logout, '退出登录', () => AuthRepository.logout(context).then((_) => Navigator.pushReplacementNamed(context, '/login'))),
          ],
        ),
      ),
    );
  }

  Widget _entryItem(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
