import 'package:flutter/material.dart';
import '../../app_theme.dart';

/// 成就页
class AchievementPage extends StatelessWidget {
  const AchievementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final achievements = [
      _Achievement('初次练习', '完成第一道题', true, '100%'),
      _Achievement('持续学习', '连续学习 7 天', true, '3/7'),
      _Achievement('答题达人', '完成 100 道题', false, '45/100'),
      _Achievement('全对之星', '某次组卷全部正确', false, '0%'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('成就')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        itemCount: achievements.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final a = achievements[i];
          return ListTile(
            leading: Icon(a.unlocked ? Icons.emoji_events : Icons.emoji_events_outlined,
              color: a.unlocked ? const Color(0xFFF59E0B) : AppColors.textSecondary, size: 32),
            title: Text(a.title),
            subtitle: Text(a.desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            trailing: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(a.progress, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              const SizedBox(height: 2),
              SizedBox(width: 60, child: LinearProgressIndicator(value: a.unlocked ? 1 : 0.45, backgroundColor: Colors.grey[200])),
            ]),
          );
        },
      ),
    );
  }
}

class _Achievement {
  final String title;
  final String desc;
  final bool unlocked;
  final String progress;
  const _Achievement(this.title, this.desc, this.unlocked, this.progress);
}
