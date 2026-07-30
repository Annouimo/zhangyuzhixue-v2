import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../router.dart';
import 'exam_explore_page.dart';
import 'exam_favorites_page.dart';
import 'exam_history_page.dart';

enum PaperCenterTab { created, explore, favorites }

class ExamHomePage extends StatefulWidget {
  const ExamHomePage({super.key, this.initialTab = PaperCenterTab.created});

  final PaperCenterTab initialTab;

  @override
  State<ExamHomePage> createState() => _ExamHomePageState();
}

class _ExamHomePageState extends State<ExamHomePage> {
  late int _selectedIndex;

  late final List<Widget> _pages = const [
    ExamHistoryPage(embedded: true),
    ExamExplorePage(embedded: true),
    ExamFavoritesPage(embedded: true),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab.index;
    AuditLogger.instance.page('ExamHomePage', {'visited': true});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: PaperCenterTab.values.length,
      initialIndex: _selectedIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('试卷中心'),
          actions: [
            IconButton(
              tooltip: '新建试卷',
              icon: const Icon(Icons.add),
              onPressed: () =>
                  RouterUtils.push(context, AppRoutes.questionBank),
            ),
          ],
          bottom: TabBar(
            onTap: (index) => setState(() => _selectedIndex = index),
            tabs: const [
              Tab(text: '我创建的'),
              Tab(text: '发现试卷'),
              Tab(text: '收藏'),
            ],
          ),
        ),
        body: IndexedStack(index: _selectedIndex, children: _pages),
      ),
    );
  }
}
