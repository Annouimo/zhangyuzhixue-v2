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
                AppNavigationCard(
                  icon: Icons.play_circle_outline_rounded,
                  title: '视频',
                  subtitle: '分类浏览自媒体视频与配套讲义',
                  onTap: () =>
                      RouterUtils.push(context, AppRoutes.videoCatalog),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
