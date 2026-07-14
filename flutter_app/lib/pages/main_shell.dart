import 'package:flutter/material.dart';
import 'index_page.dart';
import 'recommend_page.dart';
import 'exam/exam_home_page.dart';
import 'profile/profile_page.dart';
import '../data/database/database_provider.dart';

/// Tab 页枚举
enum MainTab { home, recommend, exam, profile }

/// 底部导航框架（4 Tab：首页/推荐/组卷/我的 — 匹配 HTML 原型）
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _pageKey = 0;

  final GlobalKey<RecommendPageState> _recommendKey = GlobalKey();
  final GlobalKey<ProfilePageState> _profileKey = GlobalKey();

  List<Widget> get _pages => [
    IndexPage(key: ValueKey('index_$_pageKey')),
    RecommendPage(key: _recommendKey),
    const ExamHomePage(),
    ProfilePage(key: _profileKey),
  ];

  @override
  void initState() {
    super.initState();
    DatabaseProvider().dbVersionNotifier.addListener(_onDbVersionChanged);
  }

  @override
  void dispose() {
    DatabaseProvider().dbVersionNotifier.removeListener(_onDbVersionChanged);
    super.dispose();
  }

  void _onDbVersionChanged() {
    if (!mounted) return;
    setState(() => _pageKey++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) setState(() => _pageKey++);
          if (index == 1) _recommendKey.currentState?.refresh();
          if (index == 3) _profileKey.currentState?.reload();
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: '推荐',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: '组卷',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
