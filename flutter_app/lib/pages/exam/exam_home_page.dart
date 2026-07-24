import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/debug/audit_logger.dart';

/// 智能组卷积分消耗
const int _autoPaperCost = 10;
/// 自主选题积分消耗
const int _pickPaperCost = 20;

/// 组卷首页 — 新组卷入口 + 功能列表（匹配 exam.html）
class ExamHomePage extends StatelessWidget {
  const ExamHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    AuditLogger.instance.page('ExamHomePage', {'visited': true});
    return Scaffold(
      appBar: AppBar(title: const Text('组卷')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.baseSpacing),
        children: [
          // 新组卷
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.baseSpacing),
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
                      onPressed: () => RouterUtils.push(context,AppRoutes.examAuto),
                      icon: const Icon(Icons.smart_toy),
                      label: Text('智能组卷 · 消耗 $_autoPaperCost 积分'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => RouterUtils.push(context,AppRoutes.examPick),
                      icon: const Icon(Icons.touch_app),
                      label: Text('自主选题 · 消耗 $_pickPaperCost 积分'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.baseSpacing),
          // 我的组卷
          _EntryItem(
            icon: Icons.assignment,
            title: '我的组卷',
            subtitle: '管理我创建的试卷',
            onTap: () => RouterUtils.push(context,AppRoutes.examHistory),
          ),
          // 发现组卷
          _EntryItem(
            icon: Icons.language,
            title: '发现组卷',
            subtitle: '浏览他人分享的公开试卷',
            onTap: () => RouterUtils.push(context,AppRoutes.examExplore),
          ),
          // 我的收藏
          _EntryItem(
            icon: Icons.bookmark,
            title: '我的收藏',
            subtitle: '收藏的他人试卷',
            onTap: () => RouterUtils.push(context,AppRoutes.examFavorites),
          ),
        ],
      ),
    );
  }
}

class _EntryItem extends StatelessWidget {
  final IconData icon;
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
        leading: Icon(icon, size: 24, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
