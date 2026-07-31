import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'router.dart';

class PracticeHomePage extends StatelessWidget {
  const PracticeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习')),
      body: AppContentContainer(
        maxWidth: AppContentWidth.reading,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            AppResponsiveCardGrid(
              children: [
                AppNavigationCard(
                  icon: Icons.auto_awesome_rounded,
                  title: '推荐练习',
                  subtitle: '系统结合新题与旧题，安排当前最适合的练习',
                  tone: AppStatusTone.recommendation,
                  onTap: () => RouterUtils.push(context, AppRoutes.recommend),
                ),
                AppNavigationCard(
                  icon: Icons.search_rounded,
                  title: '题库选题',
                  subtitle: '按专题或知识点找题，练习或一键出卷',
                  onTap: () =>
                      RouterUtils.push(context, AppRoutes.questionBank),
                ),
                AppNavigationCard(
                  icon: Icons.assignment_late_outlined,
                  title: '错题本',
                  subtitle: '订正错题并回顾已掌握的题目',
                  onTap: () => RouterUtils.push(
                    context,
                    '${AppRoutes.questionBank}?review=current-wrong',
                  ),
                ),
                AppNavigationCard(
                  icon: Icons.menu_book_outlined,
                  title: '学习资料',
                  subtitle: '浏览视频课程和配套讲义',
                  tone: AppStatusTone.info,
                  onTap: () =>
                      RouterUtils.push(context, AppRoutes.learningMaterials),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
