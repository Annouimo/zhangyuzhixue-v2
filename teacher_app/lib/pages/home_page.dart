import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      final manager = TeacherUpdateManager(DatabaseProvider(), baseUrl);

      final qbank = await manager.checkVersion('qbank');
      final courses = await manager.checkVersion('courses');

      if (!mounted) return;

      if (qbank.hasUpdate) {
        _showUpdateBanner('题库', qbank);
      } else if (courses.hasUpdate) {
        _showUpdateBanner('讲义', courses);
      }
    } catch (_) {
      // 静默失败，不影响启动
    }
  }

  void _showUpdateBanner(String label, UpdateInfo info) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label 有新版本 v${info.serverVersion}'),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: '更新',
          onPressed: () => _doUpdate(label, info),
        ),
      ),
    );
  }

  Future<void> _doUpdate(String label, UpdateInfo info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl =
          prefs.getString('server_url') ?? 'https://zhangyuzhixue.top';
      final manager = TeacherUpdateManager(DatabaseProvider(), baseUrl);

      await manager.downloadAndReplace(
        type: info.type,
        url: info.downloadUrl,
        expectedChecksum: info.checksum,
        newVersion: info.serverVersion,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('更新完成，即将刷新')),
      );
      // 刷新界面：切到首页 Tab 并触发重建
      setState(() => _currentIndex = 0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label 更新失败：$e')),
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
