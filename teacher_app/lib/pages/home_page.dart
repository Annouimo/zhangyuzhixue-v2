import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../data/update_manager.dart';
import '../data/database/database_provider.dart';
import 'question_bank/question_bank_page.dart';
import 'lecture/courses_page.dart';
import 'settings/settings_page.dart';

/// 教师 App 首页 — 3 Tab 底部导航
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final _pages = const [
    QuestionBankPage(),
    LectureCoursesPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkUpdates();
  }

  Future<void> _checkUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl =
          prefs.getString('server_url') ?? 'https://zhangyuzhixue.top';
      final manager = UpdateManager(baseUrl, DatabaseProvider());

      final summaries = await manager.checkAll();

      if (!mounted) return;

      for (final s in summaries) {
        if (s.serverVersion > s.localVersion) {
          final label = s.type == 'qbank' ? '题库' : '讲义';
          _showUpdateDialog(label, s);
          break;
        }
      }
    } catch (_) {}
  }

  void _showUpdateDialog(String label, UpdateSummary info) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text('$label 有更新'),
          ],
        ),
        content: Text('新版本 v${info.serverVersion} 可用，是否下载更新？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('稍后'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _doUpdate(label, info);
            },
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }

  Future<void> _doUpdate(String label, UpdateSummary info) async {
    // 进度弹窗
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text('正在下载 $label…'),
          ],
        ),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl =
          prefs.getString('server_url') ?? 'https://zhangyuzhixue.top';
      final manager = UpdateManager(baseUrl, DatabaseProvider());

      await manager.downloadAndReplace(
        type: info.type,
        url: info.downloadUrl ?? '',
        expectedChecksum: info.checksum ?? '',
        newVersion: info.serverVersion,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // 关闭进度弹窗
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('更新完成'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() => _currentIndex = 0);
    } catch (e) {
      if (!mounted) return;
      // 关闭进度弹窗
      Navigator.of(context).pop();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('更新失败'),
          content: Text('$label 更新失败：$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
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
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: '题库',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: '讲义',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
