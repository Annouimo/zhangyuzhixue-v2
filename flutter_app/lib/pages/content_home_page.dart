import 'package:flutter/material.dart';

import 'lecture/lecture_courses_page.dart';
import 'video/video_catalog_page.dart';

/// 学习资料页，集中提供视频和讲义。
class ContentHomePage extends StatelessWidget {
  const ContentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习资料')),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: const [
            TabBar(
              tabs: [
                Tab(text: '视频'),
                Tab(text: '讲义'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  VideoCatalogPage(embedded: true),
                  LectureCoursesPage(embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
