import 'package:flutter/material.dart';
import '../../app_theme.dart';

/// 关于页
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('关于')),
    body: Padding(
      padding: const EdgeInsets.all(AppSizes.baseSpacing),
      child: Column(children: [
        const SizedBox(height: 40),
        const CircleAvatar(radius: 36, backgroundColor: AppColors.primaryLight, child: Icon(Icons.school, size: 36, color: AppColors.primary)),
        const SizedBox(height: 12),
        const Text('章鱼智学', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('版本 2.0.0', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        ListTile(leading: const Icon(Icons.description_outlined), title: const Text('用户协议'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.privacy_tip_outlined), title: const Text('隐私政策'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
        const SizedBox(height: 24),
        const Text('© 2025 章鱼智学 · 北京', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    ),
  );
}
