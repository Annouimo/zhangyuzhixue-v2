import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared/theme/app_theme.dart';
import '../data/update_manager.dart';
import '../data/database/database_provider.dart';
import 'package:shared/widgets/sync_progress_dialog.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
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
  bool _hasUpdate = false;

  final GlobalKey<SettingsPageState> _settingsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkUpdates();
  }

  Future<void> _checkUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl =
          prefs.getString('server_url') ?? 'https://zhangyuzhixue.zhtec123.com';
      final manager = UpdateManager(baseUrl, DatabaseProvider());
      final summaries = await manager.checkAll();
      if (!mounted) return;

      var anyUpdate = false;
      for (final s in summaries) {
        if (s.serverVersion > s.localVersion) {
          anyUpdate = true;
          _showUpdateDialog(s.type == 'qbank' ? '题库' : '课程', s);
          break;
        }
      }
      if (!anyUpdate && mounted) {
        setState(() => _hasUpdate = false);
      }
    } catch (e) {
      AuditLogger.instance.error('HomePage._checkUpdates', e);
      OperationLog.instance.error('HomePage._checkUpdates', e);
    }
  }

  void _showUpdateDialog(String label, UpdateSummary info) {
    setState(() => _hasUpdate = true);
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
                Text('$label 有新版本（v${info.serverVersion}）', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () { Navigator.of(ctx).pop(); _startUpdate(label, info); },
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
        final baseUrl = prefs.getString('server_url') ?? 'https://zhangyuzhixue.zhtec123.com';
        final manager = UpdateManager(baseUrl, DatabaseProvider());
        await manager.downloadAndReplace(
          type: info.type, url: info.downloadUrl ?? '',
          expectedChecksum: info.checksum ?? '', newVersion: info.serverVersion,
          onProgress: onProgress,
        );
      },
      title: '更新数据',
      message: '正在下载$label新版本…',
    );
    if (!mounted) return;
    setState(() {
      _currentIndex = 0;
      _hasUpdate = false;
    });
    // 刷新设置页版本号
    _settingsKey.currentState?.refreshVersions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: [
        const QuestionBankPage(),
        const LectureCoursesPage(),
        SettingsPage(key: _settingsKey),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 2) _settingsKey.currentState?.refreshVersions();
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: '题库'),
          const BottomNavigationBarItem(icon: Icon(Icons.article), label: '课程'),
          BottomNavigationBarItem(
            icon: _hasUpdate
                ? const Badge(
                    isLabelVisible: true,
                    label: Text('!', style: TextStyle(fontSize: 9)),
                    child: Icon(Icons.settings),
                  )
                : const Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
