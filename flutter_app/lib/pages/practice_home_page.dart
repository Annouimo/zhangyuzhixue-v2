import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'router.dart';

class PracticeHomePage extends StatelessWidget {
  const PracticeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
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
                  icon: Icons.folder_outlined,
                  title: '试题篮',
                  subtitle: '持续收集、整理并生成试卷',
                  onTap: () =>
                      RouterUtils.push(context, AppRoutes.paperFolders),
                ),
                AppNavigationCard(
                  icon: Icons.library_books_outlined,
                  title: '套卷',
                  subtitle: '按年份、地区和考试类型浏览完整试卷',
                  onTap: () =>
                      RouterUtils.push(context, AppRoutes.paperLibrary),
                ),
                AppNavigationCard(
                  icon: Icons.description_outlined,
                  title: '试卷中心',
                  subtitle: '查看我创建的、发现和收藏的试卷',
                  onTap: () => RouterUtils.push(context, AppRoutes.examHome),
                ),
                AppNavigationCard(
                  icon: Icons.rate_review_outlined,
                  title: '内容贡献',
                  subtitle: '投稿新题、查看审核进度',
                  tone: AppStatusTone.info,
                  onTap: () =>
                      RouterUtils.push(context, AppRoutes.contributions),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
