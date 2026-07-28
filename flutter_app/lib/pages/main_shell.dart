import 'package:flutter/material.dart';
import 'package:shared/debug/operation_log.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_icons.dart';
import 'package:shared/theme/app_tokens.dart';

import '../data/daos/sync_queue_dao.dart';
import '../data/database/database_provider.dart';
import 'content_home_page.dart';
import 'practice_home_page.dart';
import 'profile/profile_page.dart';

/// Tab 页枚举。
enum MainTab { practice, content, profile }

/// 学生端主导航框架。
///
/// 紧凑窗口使用 Material 3 底部导航；中等及以上窗口自动切换侧边导航。
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _syncPendingCount = 0;

  final GlobalKey<ProfilePageState> _profileKey = GlobalKey();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const PracticeHomePage(),
      const ContentHomePage(),
      ProfilePage(key: _profileKey),
    ];
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
    _profileKey.currentState?.reload();
  }

  void _selectTab(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }

    if (index == MainTab.profile.index) {
      _profileKey.currentState?.reload();
      _refreshSyncPending();
    }
  }

  Widget _profileIcon({required bool selected}) {
    final icon = Icon(selected ? AppIcons.profileSelected : AppIcons.profile);
    if (_syncPendingCount <= 0) return icon;

    return Badge(
      isLabelVisible: true,
      label: Text(_syncPendingCount > 99 ? '99+' : '$_syncPendingCount'),
      child: icon,
    );
  }

  List<NavigationDestination> get _bottomDestinations => [
    const NavigationDestination(
      icon: Icon(AppIcons.recommendation),
      selectedIcon: Icon(AppIcons.recommendationSelected),
      label: '练习',
      tooltip: '题目练习',
    ),
    const NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: '内容',
      tooltip: '学习内容',
    ),
    NavigationDestination(
      icon: _profileIcon(selected: false),
      selectedIcon: _profileIcon(selected: true),
      label: '我的',
      tooltip: '个人中心',
    ),
  ];

  List<NavigationRailDestination> get _railDestinations => [
    const NavigationRailDestination(
      icon: Icon(AppIcons.recommendation),
      selectedIcon: Icon(AppIcons.recommendationSelected),
      label: Text('练习'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: Text('内容'),
    ),
    NavigationRailDestination(
      icon: _profileIcon(selected: false),
      selectedIcon: _profileIcon(selected: true),
      label: const Text('我的'),
    ),
  ];

  Widget _buildPageStack() {
    return IndexedStack(index: _currentIndex, children: _pages);
  }

  Widget _buildRailHeader(BuildContext context, {required bool extended}) {
    final mark = Image.asset(
      'assets/logo_mark.png',
      width: 38,
      height: 38,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => const SizedBox(
        width: 38,
        height: 38,
        child: Icon(Icons.auto_awesome, size: 28),
      ),
    );

    if (!extended) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Tooltip(
          message: '章鱼智学',
          child: Semantics(label: '章鱼智学', image: true, child: mark),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          const SizedBox(width: AppSpacing.sm),
          Text(
            '章鱼智学',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSideNavigation = constraints.maxWidth >= AppBreakpoints.medium;
        final extendRail = constraints.maxWidth >= AppBreakpoints.expanded;

        if (!useSideNavigation) {
          return Scaffold(
            body: _buildPageStack(),
            bottomNavigationBar: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.colors.divider)),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: _selectTab,
                destinations: _bottomDestinations,
              ),
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                right: false,
                child: NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _selectTab,
                  extended: extendRail,
                  labelType: extendRail
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  groupAlignment: -0.72,
                  leading: _buildRailHeader(context, extended: extendRail),
                  destinations: _railDestinations,
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: context.colors.divider,
              ),
              Expanded(child: _buildPageStack()),
            ],
          ),
        );
      },
    );
  }
}
