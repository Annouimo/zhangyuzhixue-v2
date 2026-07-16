import 'package:flutter/material.dart';
import 'index_page.dart';
import 'recommend_page.dart';
import 'exam/exam_home_page.dart';
import 'profile/profile_page.dart';
import '../data/database/database_provider.dart';
import '../data/daos/sync_queue_dao.dart';
import '../data/debug/operation_log.dart';

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
  int _syncPendingCount = 0;

  final GlobalKey<IndexPageState> _indexKey = GlobalKey();
  final GlobalKey<RecommendPageState> _recommendKey = GlobalKey();
  final GlobalKey<ProfilePageState> _profileKey = GlobalKey();

  List<Widget> get _pages => [
    IndexPage(key: _indexKey),
    RecommendPage(key: _recommendKey),
    const ExamHomePage(),
    ProfilePage(key: _profileKey),
  ];

  @override
  void initState() {
    super.initState();
    DatabaseProvider().dbVersionNotifier.addListener(_onDbVersionChanged);
    _refreshSyncPending();
  }

  Future<void> _refreshSyncPending() async {
    try {
      final count = await SyncQueueDao(DatabaseProvider()).getPendingCount();
      if (mounted) setState(() => _syncPendingCount = count);
    } catch (e) {
      OperationLog.instance.error('MainShell._refreshSyncPending', e);
    }
  }

  @override
  void dispose() {
    DatabaseProvider().dbVersionNotifier.removeListener(_onDbVersionChanged);
    super.dispose();
  }

  void _onDbVersionChanged() {
    if (!mounted) return;
    // 刷新所有 Tab 页
    _indexKey.currentState?.reload();
    _recommendKey.currentState?.refresh();
    _profileKey.currentState?.reload();
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
          if (index == 0) _indexKey.currentState?.reload();
          if (index == 1) _recommendKey.currentState?.refresh();
          if (index == 3) {
            _profileKey.currentState?.reload();
            _refreshSyncPending();
          }
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: '推荐',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: '组卷',
          ),
          BottomNavigationBarItem(
            icon: _syncPendingCount > 0
                ? Badge(
                    isLabelVisible: true,
                    label: Text('$_syncPendingCount',
                        style: const TextStyle(fontSize: 9)),
                    child: const Icon(Icons.person_outline),
                  )
                : const Icon(Icons.person_outline),
            activeIcon: _syncPendingCount > 0
                ? Badge(
                    isLabelVisible: true,
                    label: Text('$_syncPendingCount',
                        style: const TextStyle(fontSize: 9)),
                    child: const Icon(Icons.person),
                  )
                : const Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
