import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/sync_progress_dialog.dart';
import '../../widgets/shared/app_toast.dart';
import '../../data/sync/sync_manager.dart';
import '../../data/prefs/app_prefs.dart';
import '../../data/daos/progress_dao.dart';
import '../../data/database/database_provider.dart';
import '../../constants/app_version.dart';
import '../../data/debug/audit_logger.dart';

/// 关于页
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _lastSyncTime = '从未同步';
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final ts = AppPrefs().lastSyncTime;
    if (ts != null && mounted) {
      setState(() => _lastSyncTime = '上次同步：$ts');
    }
    AuditLogger.instance.page('AboutPage', {'version': appVersion});
  }

  Future<void> _onSync() async {
    if (_syncing) return;
    setState(() => _syncing = true);

    final ok = await showSyncProgress(
      context,
      (onProgress) async {
        await SyncManager().forcePull(onProgress: onProgress);
      },
      dataVerifier: () async {
        final dao = ProgressDao(DatabaseProvider().appDb);
        return dao.hasAnySubmission();
      },
    );

    if (ok && mounted) {
      final now = DateTime.now();
      final label =
          '${now.month}/${now.day} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      await AppPrefs().setLastSyncTime(label);
      setState(() => _lastSyncTime = '上次同步：$label');
    }
    if (mounted) setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('关于')),
    body: Padding(
      padding: const EdgeInsets.all(AppSizes.baseSpacing),
      child: Column(children: [
        const SizedBox(height: 40),
        const CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.school, size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        const Text(
          '章鱼智学',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '版本 $appVersion',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('用户协议'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => AppToast.show(context, icon: Icons.description, message: '用户协议页面即将上线'),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('隐私政策'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => AppToast.show(context, icon: Icons.description, message: '隐私政策页面即将上线'),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.sync),
          title: const Text('数据同步'),
          subtitle: Text(
            _lastSyncTime,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: TextButton(
            onPressed: _syncing ? null : _onSync,
            child: _syncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('同步'),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '© ${DateTime.now().year} 章鱼智学 · 北京',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ]),
    ),
  );
}
