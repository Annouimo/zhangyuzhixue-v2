import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'router.dart';

class ContentHomePage extends StatelessWidget {
  const ContentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('内容')),
      body: AppContentContainer(
        maxWidth: AppContentWidth.reading,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            AppResponsiveCardGrid(
              children: [
                AppNavigationCard(
                  icon: Icons.menu_book_rounded,
                  title: '讲义',
                  subtitle: '按章节查看学习内容',
                  onTap: () =>
                      RouterUtils.push(context, AppRoutes.lectureCourses),
                ),
                const AppNavigationCard(
                  icon: Icons.play_circle_outline_rounded,
                  title: '视频',
                  subtitle: '系统课、可视化视频和学习经验',
                  trailing: AppStatusBadge(
                    label: '筹备中',
                    tone: AppStatusTone.neutral,
                    compact: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
