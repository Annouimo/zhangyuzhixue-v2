import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../router.dart';
import 'exam_explore_page.dart';
import 'exam_favorites_page.dart';
import 'exam_history_page.dart';
import '../question_bank/paper_library_page.dart';

class ExamHomePage extends StatefulWidget {
  const ExamHomePage({super.key});

  @override
  State<ExamHomePage> createState() => _ExamHomePageState();
}

class _ExamHomePageState extends State<ExamHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('试卷')),
      body: AppContentContainer(
        maxWidth: AppContentWidth.reading,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            AppResponsiveCardGrid(
              children: [
                AppNavigationCard(
                  icon: Icons.folder_outlined,
                  title: '试题篮',
                  subtitle: '持续收集、整理并生成试卷',
                  onTap: () =>
                      RouterUtils.push(context, AppRoutes.paperFolders),
                ),
                AppNavigationCard(
                  icon: Icons.library_books_outlined,
                  title: '浏览试卷',
                  subtitle: '浏览真题、模拟和广场试卷',
                  onTap: () => RouterUtils.push(context, AppRoutes.examBrowse),
                ),
                AppNavigationCard(
                  icon: Icons.description_outlined,
                  title: '我的试卷',
                  subtitle: '查看已生成和收藏的试卷',
                  onTap: () => RouterUtils.push(context, AppRoutes.myPapers),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ExamBrowsePage extends StatelessWidget {
  const ExamBrowsePage({super.key});
  static const _realRegions = ['北京'];
  static const _mockRegions = ['东城', '西城', '海淀', '朝阳'];

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('浏览试卷'),
        bottom: const TabBar(
          tabs: [
            Tab(text: '真题'),
            Tab(text: '模拟'),
            Tab(text: '广场'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          PaperLibraryPage(embedded: true, regions: _realRegions),
          PaperLibraryPage(embedded: true, regions: _mockRegions),
          ExamExplorePage(embedded: true),
        ],
      ),
    ),
  );
}

class MyPapersPage extends StatelessWidget {
  const MyPapersPage({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('我的试卷'),
        bottom: const TabBar(
          tabs: [
            Tab(text: '已生成'),
            Tab(text: '收藏'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          ExamHistoryPage(embedded: true),
          ExamFavoritesPage(embedded: true),
        ],
      ),
    ),
  );
}
