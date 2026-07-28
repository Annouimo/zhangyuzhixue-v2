import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../router.dart';

class StudyArchivePage extends StatelessWidget {
  const StudyArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习档案')),
      body: AppContentContainer(
        maxWidth: AppContentWidth.reading,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            AppResponsiveCardGrid(
              children: [
                AppNavigationCard(
                  icon: Icons.radar_rounded,
                  title: '学习复盘',
                  subtitle: '查看掌握状态和需要巩固的知识点',
                  onTap: () => RouterUtils.push(context, AppRoutes.review),
                ),
                AppNavigationCard(
                  icon: Icons.insights_rounded,
                  title: '学习统计',
                  subtitle: '查看正确率、活跃度和题型分布',
                  onTap: () => RouterUtils.push(context, AppRoutes.statistics),
                ),
                AppNavigationCard(
                  icon: Icons.history_rounded,
                  title: '做题记录',
                  subtitle: '继续未完成的作答或回顾历史题目',
                  onTap: () =>
                      RouterUtils.push(context, AppRoutes.profileHistory),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
