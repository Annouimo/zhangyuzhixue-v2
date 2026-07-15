import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../data/update_manager.dart';
import '../data/database/database_provider.dart';
import '../widgets/sync_progress_dialog.dart';
import 'question_bank/question_bank_page.dart';
import 'lecture/lecture_courses_page.dart';
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
          _showUpdateDialog(s.type == 'qbank' ? '题库' : '讲义', s);
          break;
        }
      }
    } catch (_) {}
  }

  void _showUpdateDialog(String label, UpdateSummary info) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.system_update, size: 40, color: AppColors.primary),
                const SizedBox(height: 12),
                const Text('数据更新', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('$label 有新版本（v${info.serverVersion}）', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () { Navigator.of(ctx).pop(); _startUpdate(label, info); },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('立即更新', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startUpdate(String label, UpdateSummary info) async {
    await showSyncProgress(
      context,
      (onProgress) async {
        final prefs = await SharedPreferences.getInstance();
        final baseUrl = prefs.getString('server_url') ?? 'https://zhangyuzhixue.top';
        final manager = UpdateManager(baseUrl, DatabaseProvider());
        await manager.downloadAndReplace(
          type: info.type, url: info.downloadUrl ?? '',
          expectedChecksum: info.checksum ?? '', newVersion: info.serverVersion,
          onProgress: onProgress,
        );
      },
    );
    if (!mounted) return;
    setState(() => _currentIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: '题库'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: '讲义'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
