import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'router.dart';

class PracticeHomePage extends StatelessWidget {
  const PracticeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('练习')),
      body: AppContentContainer(
        maxWidth: AppContentWidth.reading,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            AppNavigationCard(
              icon: Icons.auto_awesome_rounded,
              title: '推荐练习',
              subtitle: '系统结合新题与旧题，安排当前最适合的练习',
              tone: AppStatusTone.recommendation,
              onTap: () => RouterUtils.push(context, AppRoutes.recommend),
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(title: '自主练习'),
            const SizedBox(height: AppSpacing.sm),
            AppResponsiveCardGrid(
              children: [
                AppNavigationCard(
                  icon: Icons.search_rounded,
                  title: '题库浏览',
                  subtitle: '按题型和来源查找题目，查看完整信息',
                  onTap: () =>
                      RouterUtils.push(context, AppRoutes.questionBank),
                ),
                AppNavigationCard(
                  icon: Icons.description_outlined,
                  title: '试卷',
                  subtitle: '智能组卷、自主选题和已有试卷',
                  onTap: () => RouterUtils.push(context, AppRoutes.examHome),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
