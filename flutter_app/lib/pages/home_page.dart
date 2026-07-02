import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/auth_repository.dart';

/// 首页
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> _user = AuthRepository.getMockUser();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return '早上好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        children: [
          const SizedBox(height: 16),
          // 用户信息卡片（含问候语）
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
                      _user['name'] != null && (_user['name'] as String).isNotEmpty
                          ? (_user['name'] as String)[0]
                          : '?',
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_greeting()}，${_user['name'] ?? ''}',
                            style: const TextStyle(fontSize: AppTheme.fontSizeLarge, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('学号：${_user['student_id'] ?? ''}', style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text('${_user['points'] ?? 0}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                      const Text('积分', style: TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontSizeSmall)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.paddingMedium),
          // 题目推荐入口
          _entryItem(Icons.auto_stories, '题目推荐', () => Navigator.pushNamed(context, '/recommend-list')),
          // 自主组卷入口
          _entryItem(Icons.auto_fix_high, '自主组卷', () => Navigator.pushNamed(context, '/exam-builder')),
        ],
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
