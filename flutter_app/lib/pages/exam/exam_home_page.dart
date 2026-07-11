import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../data/debug/audit_logger.dart';

/// 组卷首页 — 新组卷入口 + 功能列表（匹配 exam.html）
class ExamHomePage extends StatelessWidget {
  const ExamHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    AuditLogger.instance.page('ExamHomePage', {'autoCount': _autoCount, 'pickCount': _pickCount, 'favCount': _favCount});
    return Scaffold(
      appBar: AppBar(title: const Text('组卷')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 新组卷
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('新组卷',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/exam/auto'),
                    icon: const Text('🤖'),
                    label: const Text('智能组卷 · 消耗 10 积分'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/exam/pick'),
                    icon: const Text('🖐'),
                    label: const Text('自主选题 · 消耗 20 积分'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 我的组卷
          _EntryItem(
            icon: '📋',
            title: '我的组卷',
            subtitle: '管理我创建的试卷',
            onTap: () => context.push('/exam/history'),
          ),
          // 发现组卷
          _EntryItem(
            icon: '🌐',
            title: '发现组卷',
            subtitle: '浏览他人分享的公开试卷',
            onTap: () => context.push('/exam/explore'),
          ),
          // 我的收藏
          _EntryItem(
            icon: '🔖',
            title: '我的收藏',
            subtitle: '收藏的他人试卷',
            onTap: () => context.push('/exam/favorites'),
          ),
        ],
      ),
    );
  }
}

class _EntryItem extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EntryItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 24)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
